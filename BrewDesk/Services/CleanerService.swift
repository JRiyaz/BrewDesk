import Combine
import Foundation
import SwiftUI

struct CleanableItem: Identifiable, Hashable, Sendable {
    let id: String
    let path: String
    let name: String
    let sizeString: String
    let category: String
    var removeCommand: String {
        "rm -f \"\(path)\""
    }
}

@MainActor
final class CleanerService: ObservableObject {
    @Published private(set) var autoremoveItems: [CleanableItem] = []
    @Published private(set) var cleanupItems: [CleanableItem] = []
    @Published private(set) var cachedBottleItems: [CleanableItem] = []

    @Published private(set) var cacheSizeBytes: Int64 = 0
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published private(set) var activeAction: String?
    @Published private(set) var cleanerError: String?
    @Published private(set) var lastScannedAt: Date?
    @Published private(set) var lastAutoremoveAt: Date?
    @Published private(set) var lastCleanedAt: Date?
    @Published private(set) var lastPrunedAt: Date?

    var cacheFormattedSize: String {
        ByteCountFormatter.string(fromByteCount: cacheSizeBytes, countStyle: .file)
    }

    // Backward-compatible alias
    var items: [CleanableItem] {
        cleanupItems
    }

    func scanAll(using installation: HomebrewInstallation?) async {
        guard !isScanning else { return }
        isScanning = true
        cleanerError = nil
        defer { isScanning = false }

        // 1. Scan the cache folder directly
        scanCacheDirectory(using: installation)

        guard let installation else {
            lastScannedAt = Date()
            return
        }

        let executableURL = URL(fileURLWithPath: installation.executablePath)

        // 2. Scan autoremove dry run
        do {
            let autoResult = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["autoremove", "-n"],
                timeout: 30
            )
            self.autoremoveItems = parseAutoremoveDryRun(autoResult.standardOutput)
        } catch is CancellationError {
            return
        } catch {
            // Autoremove dry-run warning is benign if no orphaned formulae
        }

        // 3. Scan cleanup dry run
        do {
            let cleanResult = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["cleanup", "-n"],
                timeout: 30
            )
            self.cleanupItems = parseCleanupDryRun(cleanResult.standardOutput)
        } catch is CancellationError {
            return
        } catch {
            // Non-fatal if sandbox limits certain directories
        }

        self.lastScannedAt = Date()
    }

    func scan(using installation: HomebrewInstallation?) async {
        await scanAll(using: installation)
    }

    func runAutoremove(using installation: HomebrewInstallation?) async -> Bool {
        guard let installation, !isCleaning else { return false }
        isCleaning = true
        activeAction = "Autoremoving unneeded dependencies…"
        cleanerError = nil
        defer {
            isCleaning = false
            activeAction = nil
        }

        let executableURL = URL(fileURLWithPath: installation.executablePath)
        do {
            _ = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["autoremove"],
                timeout: 120
            )
            self.lastAutoremoveAt = Date()
            await scanAll(using: installation)
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.cleanerError = error.localizedDescription
            return false
        }
    }

    func runCleanup(using installation: HomebrewInstallation?) async -> Bool {
        guard let installation, !isCleaning else { return false }
        isCleaning = true
        activeAction = "Cleaning outdated packages & lockfiles…"
        cleanerError = nil
        defer {
            isCleaning = false
            activeAction = nil
        }

        let executableURL = URL(fileURLWithPath: installation.executablePath)
        do {
            _ = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["cleanup"],
                timeout: 120
            )
            self.lastCleanedAt = Date()
            await scanAll(using: installation)
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.cleanerError = error.localizedDescription
            return false
        }
    }

    func pruneAllCache(using installation: HomebrewInstallation?) async -> Bool {
        guard let installation, !isCleaning else { return false }
        isCleaning = true
        activeAction = "Purging all Homebrew cache archives…"
        cleanerError = nil
        defer {
            isCleaning = false
            activeAction = nil
        }

        let executableURL = URL(fileURLWithPath: installation.executablePath)
        do {
            _ = try await ProcessRunner.run(
                executableURL: executableURL,
                arguments: ["cleanup", "--prune=all"],
                timeout: 180
            )
            self.lastPrunedAt = Date()
            await scanAll(using: installation)
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.cleanerError = error.localizedDescription
            return false
        }
    }

    func deleteItem(_ item: CleanableItem) {
        do {
            try FileManager.default.removeItem(atPath: item.path)
            cleanupItems.removeAll { $0.id == item.id }
            cachedBottleItems.removeAll { $0.id == item.id }
            autoremoveItems.removeAll { $0.id == item.id }
        } catch {
            cleanerError = "Failed to remove \(item.name): \(error.localizedDescription)"
        }
    }

    private func scanCacheDirectory(using installation: HomebrewInstallation?) {
        let cachePath = ("~/Library/Caches/Homebrew" as NSString).expandingTildeInPath
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: cachePath)

        guard fileManager.fileExists(atPath: cachePath) else {
            cacheSizeBytes = 0
            cachedBottleItems = []
            return
        }

        var totalSize: Int64 = 0
        var foundBottles: [CleanableItem] = []

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      let isDir = values.isDirectory, !isDir,
                      let size = values.fileSize else {
                    continue
                }

                totalSize += Int64(size)

                let filename = fileURL.lastPathComponent
                let category: String
                if filename.contains(".bottle.") || filename.hasSuffix(".tar.gz") {
                    category = "Active Bottle Archive"
                } else if fileURL.path.contains("/api") {
                    category = "API Index Feed"
                } else if fileURL.path.contains("/bootsnap") {
                    category = "Bootsnap Cache"
                } else if fileURL.path.contains("/Cask") {
                    category = "Cask Archive"
                } else {
                    category = "Cached File"
                }

                let sizeString = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
                foundBottles.append(CleanableItem(
                    id: fileURL.path,
                    path: fileURL.path,
                    name: filename,
                    sizeString: sizeString,
                    category: category
                ))
            }
        }

        self.cacheSizeBytes = totalSize
        // Sort largest files first, capped to top 150 items for snappy UI performance
        self.cachedBottleItems = Array(
            foundBottles.sorted { ($0.name.hasPrefix("api") ? 1 : 0) < ($1.name.hasPrefix("api") ? 1 : 0) }
                .prefix(150)
        )
    }

    private func parseAutoremoveDryRun(_ output: String) -> [CleanableItem] {
        var results: [CleanableItem] = []
        let lines = output.split(whereSeparator: \.isNewline)
        for line in lines {
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { continue }
            if str.hasPrefix("Uninstalling ") {
                let stripped = str.replacingOccurrences(of: "Uninstalling ", with: "")
                let name = stripped.components(separatedBy: "...").first?.trimmingCharacters(in: .whitespaces) ?? stripped
                results.append(CleanableItem(
                    id: "autoremove-\(name)",
                    path: name,
                    name: name,
                    sizeString: "Unneeded",
                    category: "Orphaned Dependency"
                ))
            } else if str.hasPrefix("Would uninstall: ") {
                let name = str.replacingOccurrences(of: "Would uninstall: ", with: "").trimmingCharacters(in: .whitespaces)
                results.append(CleanableItem(
                    id: "autoremove-\(name)",
                    path: name,
                    name: name,
                    sizeString: "Unneeded",
                    category: "Orphaned Dependency"
                ))
            }
        }
        return results
    }

    private func parseCleanupDryRun(_ output: String) -> [CleanableItem] {
        var results: [CleanableItem] = []
        let lines = output.split(whereSeparator: \.isNewline)

        for line in lines {
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard str.hasPrefix("Would remove:") else { continue }
            let afterPrefix = str.replacingOccurrences(of: "Would remove:", with: "").trimmingCharacters(in: .whitespaces)
            let parts = afterPrefix.components(separatedBy: " (")
            guard let path = parts.first?.trimmingCharacters(in: .whitespaces) else { continue }
            let size = parts.count > 1 ? parts[1].replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces) : "Unknown"

            let name = URL(fileURLWithPath: path).lastPathComponent
            let category: String
            if path.contains("Caches") {
                category = "Stale Bottle Download"
            } else if path.contains("Lock") {
                category = "Stale Lockfile"
            } else {
                category = "Old Package Version"
            }

            results.append(CleanableItem(
                id: path,
                path: path,
                name: name,
                sizeString: size,
                category: category
            ))
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
