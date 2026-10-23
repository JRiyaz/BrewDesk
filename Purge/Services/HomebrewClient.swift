import Foundation

/// Small Homebrew adapter for read-only discovery. Mutating operations are implemented
/// separately so their command construction, confirmations, and cancellation can be reviewed.
struct HomebrewClient {
    private let fileManager = FileManager.default
    
    /// Standard installation paths are checked first because they are predictable and trusted.
    private let standardPaths = [
        "/opt/homebrew/bin/brew", // Default Apple Silicon prefix
        "/usr/local/bin/brew"     // Default Intel prefix
    ]
    
    func detectInstallation(customPath: String) async throws -> HomebrewInstallation {
        let override = customPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates: [String]
        let isCustomPath = !override.isEmpty
        
        if isCustomPath {
            let expandedPath = (override as NSString).expandingTildeInPath
            candidates = [URL(fileURLWithPath: expandedPath).standardizedFileURL.path]
        } else {
            candidates = discoveredCandidatePaths()
        }
        
        var diagnostics: [String] = []
        var lastFailure: Error?
        
        for path in candidates {
            try Task.checkCancellation()
            
            let exists = fileManager.fileExists(atPath: path)
            let executable = fileManager.isExecutableFile(atPath: path)
            
            // For candidate paths, only test paths that actually exist on disk.
            if !isCustomPath && !exists {
                continue
            }
            
            do {
                return try await inspectExecutable(at: path)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastFailure = error
                diagnostics.append(
                    "\(path) (exists: \(exists ? "yes" : "no"), executable: \(executable ? "yes" : "no")): \(error.localizedDescription)"
                )
            }
        }
        
        let checkedPaths = candidates.isEmpty ? "No candidate paths were available." : candidates.joined(separator: ", ")
        let failureDetails = diagnostics.isEmpty
        ? "No candidate executable was visible to this app."
        : diagnostics.joined(separator: "\n")
        let processPath = ProcessInfo.processInfo.environment["PATH"] ?? "(not set)"
        let message = "Checked: \(checkedPaths).\n\(failureDetails)\nApp PATH: \(processPath)\nOpen Settings and validate the full path, for example /opt/homebrew/bin/brew."
        
        if isCustomPath, let lastFailure {
            throw HomebrewClientError.detectionFailed("Custom path \(candidates.first ?? override) failed. \(lastFailure.localizedDescription)\n\(message)")
        }
        throw HomebrewClientError.detectionFailed(message)
    }
    
    /// Uses standard paths first, then executable paths inherited by the app when available.
    /// This is a finite lookup performed only when the user opens a screen or requests a check.
    private func discoveredCandidatePaths() -> [String] {
        var candidates = standardPaths
        let inheritedPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        
        for directory in inheritedPath.split(separator: ":", omittingEmptySubsequences: true) {
            let expandedDirectory = (String(directory) as NSString).expandingTildeInPath
            let normalizedDirectory = URL(fileURLWithPath: expandedDirectory).standardizedFileURL.path
            let path = URL(fileURLWithPath: normalizedDirectory)
                .appendingPathComponent("brew", isDirectory: false).path
            if fileManager.fileExists(atPath: path) || fileManager.isExecutableFile(atPath: path) {
                candidates.append(path)
            }
        }
        
        var seen = Set<String>()
        return candidates.filter { candidate in
            let normalized = URL(fileURLWithPath: candidate).standardizedFileURL.path
            return seen.insert(normalized).inserted
        }
    }
    
    func listInstalledPackages(using installation: HomebrewInstallation) async throws -> [HomebrewPackage] {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        let leaves = (try? await listLeaves(executableURL: executableURL)) ?? []
        let leavesSet = Set(leaves)
        
        let rawFormulae = try await listPackages(
            executableURL: executableURL,
            arguments: ["list", "--formula", "--versions"],
            kind: .formula
        )
        let formulae = rawFormulae.map { pkg in
            HomebrewPackage(
                name: pkg.name,
                version: pkg.version,
                kind: pkg.kind,
                isDirect: leavesSet.isEmpty ? true : leavesSet.contains(pkg.name)
            )
        }
        
        let rawCasks = try await listPackages(
            executableURL: executableURL,
            arguments: ["list", "--cask", "--versions"],
            kind: .cask
        )
        let casks = rawCasks.map { pkg in
            HomebrewPackage(
                name: pkg.name,
                version: pkg.version,
                kind: pkg.kind,
                isDirect: true
            )
        }
        
        return (formulae + casks).sorted {
            let nameOrder = $0.name.localizedCaseInsensitiveCompare($1.name)
            if nameOrder == .orderedSame {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return nameOrder == .orderedAscending
        }
    }
    
    private func listLeaves(executableURL: URL) async throws -> [String] {
        let output = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["leaves"],
            displayCommand: "brew leaves"
        )
        return output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("==") }
    }
    
    func listServices(using installation: HomebrewInstallation) async throws -> [HomebrewService] {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        let output = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["services", "list"],
            displayCommand: "brew services list"
        )
        return parseServicesList(output)
    }
    
    private func parseServicesList(_ output: String) -> [HomebrewService] {
        let lines = output.split(whereSeparator: \.isNewline)
        guard lines.count > 1 else { return [] }
        
        var services: [HomebrewService] = []
        // Skip header line (e.g. "Name Status User File")
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("==") else { continue }
            let fields = trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let name = fields.first else { continue }
            
            let statusRaw = fields.count > 1 ? fields[1].lowercased() : "unknown"
            let status: HomebrewServiceStatus
            if statusRaw.contains("started") {
                status = .started
            } else if statusRaw.contains("stopped") || statusRaw.contains("none") {
                status = .stopped
            } else if statusRaw.contains("error") {
                status = .error
            } else {
                status = .unknown
            }
            
            let user = fields.count > 2 && !fields[2].hasPrefix("/") && !fields[2].hasPrefix("~") ? fields[2] : nil
            let file = fields.first(where: { $0.hasPrefix("/") || $0.hasPrefix("~") })
            
            services.append(HomebrewService(
                name: name,
                status: status,
                user: user,
                file: file
            ))
        }
        
        return services.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func startService(name: String, using installation: HomebrewInstallation) async throws {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        _ = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["services", "start", name],
            displayCommand: "brew services start \(name)"
        )
    }
    
    func stopService(name: String, using installation: HomebrewInstallation) async throws {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        _ = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["services", "stop", name],
            displayCommand: "brew services stop \(name)"
        )
    }
    
    func listOutdatedPackages(using installation: HomebrewInstallation) async throws -> [HomebrewOutdatedPackage] {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        
        async let leavesTask = (try? await listLeaves(executableURL: executableURL)) ?? []
        async let jsonTask = try? await checkedOutput(
            executableURL: executableURL,
            arguments: ["outdated", "--json=v2"],
            displayCommand: "brew outdated --json=v2"
        )
        
        let leaves = await leavesTask
        let leavesSet = Set(leaves)
        
        if let jsonOutput = await jsonTask, let packages = parseOutdatedJSON(jsonOutput, leavesSet: leavesSet) {
            return packages
        }
        
        let plainOutput = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["outdated"],
            displayCommand: "brew outdated"
        )
        return parseOutdatedPlain(plainOutput, leavesSet: leavesSet)
    }
    
    private func parseOutdatedJSON(_ jsonString: String, leavesSet: Set<String>) -> [HomebrewOutdatedPackage]? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        var results: [HomebrewOutdatedPackage] = []
        
        if let formulae = json["formulae"] as? [[String: Any]] {
            for item in formulae {
                guard let name = item["name"] as? String else { continue }
                let current = (item["current_version"] as? String) ?? "available"
                let installed: String
                if let versions = item["installed_versions"] as? [String] {
                    installed = versions.joined(separator: ", ")
                } else {
                    installed = "unknown"
                }
                let pinned = (item["pinned"] as? Bool) ?? false
                let isDirect = leavesSet.isEmpty ? true : (leavesSet.contains(name) || leavesSet.contains(name.components(separatedBy: "/").last ?? name))
                results.append(HomebrewOutdatedPackage(
                    name: name,
                    installedVersion: installed,
                    currentVersion: current,
                    kind: .formula,
                    isPinned: pinned,
                    isDirect: isDirect
                ))
            }
        }
        
        if let casks = json["casks"] as? [[String: Any]] {
            for item in casks {
                guard let name = item["name"] as? String else { continue }
                let current = (item["current_version"] as? String) ?? "available"
                let installed: String
                if let versions = item["installed_versions"] as? [String] {
                    installed = versions.joined(separator: ", ")
                } else if let version = item["installed_versions"] as? String {
                    installed = version
                } else {
                    installed = "unknown"
                }
                results.append(HomebrewOutdatedPackage(
                    name: name,
                    installedVersion: installed,
                    currentVersion: current,
                    kind: .cask,
                    isPinned: false,
                    isDirect: true
                ))
            }
        }
        
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private func parseOutdatedPlain(_ output: String, leavesSet: Set<String>) -> [HomebrewOutdatedPackage] {
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("==") else { return nil }
                let parts = trimmed.components(separatedBy: "<")
                if parts.count == 2 {
                    let left = parts[0].trimmingCharacters(in: .whitespaces)
                    let newVer = parts[1].trimmingCharacters(in: .whitespaces)
                    let nameAndOld = left.components(separatedBy: "(")
                    let name = nameAndOld[0].trimmingCharacters(in: .whitespaces)
                    let oldVer = nameAndOld.count > 1
                    ? nameAndOld[1].replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
                    : "installed"
                    let isDirect = leavesSet.isEmpty ? true : (leavesSet.contains(name) || leavesSet.contains(name.components(separatedBy: "/").last ?? name))
                    return HomebrewOutdatedPackage(
                        name: name,
                        installedVersion: oldVer,
                        currentVersion: newVer,
                        kind: .formula,
                        isPinned: false,
                        isDirect: isDirect
                    )
                } else {
                    let name = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
                    let isDirect = leavesSet.isEmpty ? true : (leavesSet.contains(name) || leavesSet.contains(name.components(separatedBy: "/").last ?? name))
                    return HomebrewOutdatedPackage(
                        name: name,
                        installedVersion: "Installed",
                        currentVersion: "New version available",
                        kind: .formula,
                        isPinned: false,
                        isDirect: isDirect
                    )
                }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func upgradePackage(name: String, kind: HomebrewPackageKind, using installation: HomebrewInstallation) async throws {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        let args = kind == .cask ? ["upgrade", "--cask", name] : ["upgrade", name]
        _ = try await ProcessRunner.run(
            executableURL: executableURL,
            arguments: args,
            timeout: 180
        )
    }
    
    func upgradeAll(using installation: HomebrewInstallation) async throws {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        _ = try await ProcessRunner.run(
            executableURL: executableURL,
            arguments: ["upgrade"],
            timeout: 300
        )
    }
    
    func searchCatalogue(
        query: String,
        kind: HomebrewPackageKind,
        using installation: HomebrewInstallation
    ) async throws -> [HomebrewSearchResult] {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        let kindFlag = kind == .cask ? "--cask" : "--formula"
        let output = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["search", kindFlag, query],
            displayCommand: "brew search \(kindFlag) \(query)"
        )
        return parseSearchResults(output, kind: kind)
    }
    
    func installPackage(
        name: String,
        kind: HomebrewPackageKind,
        using installation: HomebrewInstallation
    ) async throws {
        let executableURL = URL(fileURLWithPath: installation.executablePath)
        let args = kind == .cask ? ["install", "--cask", name] : ["install", name]
        _ = try await ProcessRunner.run(
            executableURL: executableURL,
            arguments: args,
            timeout: 300
        )
    }
    
    private func parseSearchResults(_ output: String, kind: HomebrewPackageKind) -> [HomebrewSearchResult] {
        let lines = output.split(whereSeparator: \.isNewline)
        var results: [HomebrewSearchResult] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("==>") else { continue }
            
            let rawTokens = trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
            var i = 0
            while i < rawTokens.count {
                let token = rawTokens[i]
                if token == "✔" || token == "(disabled)" {
                    i += 1
                    continue
                }
                var isInstalled = false
                var isDisabled = false
                
                if i + 1 < rawTokens.count && rawTokens[i + 1] == "✔" {
                    isInstalled = true
                }
                if i + 1 < rawTokens.count && rawTokens[i + 1] == "(disabled)" {
                    isDisabled = true
                }
                if i + 2 < rawTokens.count && rawTokens[i + 2] == "(disabled)" {
                    isDisabled = true
                }
                
                let cleanName = token.replacingOccurrences(of: "✔", with: "").trimmingCharacters(in: .whitespaces)
                if !cleanName.isEmpty {
                    results.append(HomebrewSearchResult(
                        name: cleanName,
                        kind: kind,
                        isInstalled: isInstalled,
                        isDisabled: isDisabled
                    ))
                }
                i += 1
            }
        }
        
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private func inspectExecutable(at path: String) async throws -> HomebrewInstallation {
        let executableURL = URL(fileURLWithPath: path)
        let version = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["--version"],
            displayCommand: "brew --version"
        )
        let prefix = try await checkedOutput(
            executableURL: executableURL,
            arguments: ["--prefix"],
            displayCommand: "brew --prefix"
        )
        
        guard let versionLine = version.split(whereSeparator: \.isNewline).first else {
            throw HomebrewClientError.commandFailed(
                command: "brew --version",
                reason: "Homebrew returned an empty version response."
            )
        }
        guard let prefixLine = prefix.split(whereSeparator: \.isNewline).first else {
            throw HomebrewClientError.commandFailed(
                command: "brew --prefix",
                reason: "Homebrew returned an empty prefix response."
            )
        }
        
        return HomebrewInstallation(
            executablePath: path,
            version: String(versionLine).trimmingCharacters(in: .whitespacesAndNewlines),
            prefix: String(prefixLine).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    private func listPackages(
        executableURL: URL,
        arguments: [String],
        kind: HomebrewPackageKind
    ) async throws -> [HomebrewPackage] {
        let displayCommand = arguments.joined(separator: " ")
        let output = try await checkedOutput(
            executableURL: executableURL,
            arguments: arguments,
            displayCommand: "brew \(displayCommand)"
        )
        
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("==") else { return nil }
                let fields = trimmed.split(whereSeparator: \.isWhitespace)
                guard let first = fields.first else { return nil }
                let name = String(first)
                let version = fields.dropFirst().map(String.init).joined(separator: ", ")
                return HomebrewPackage(name: name, version: version, kind: kind)
            }
    }
    
    private func checkedOutput(
        executableURL: URL,
        arguments: [String],
        displayCommand: String
    ) async throws -> String {
        let result = try await ProcessRunner.run(
            executableURL: executableURL,
            arguments: arguments
        )
        guard result.exitCode == 0 else {
            let reason = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            throw HomebrewClientError.commandFailed(
                command: displayCommand,
                reason: reason.isEmpty ? "The command exited with status \(result.exitCode)." : reason
            )
        }
        return result.standardOutput
    }
}
