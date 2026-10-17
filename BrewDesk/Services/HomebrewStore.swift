import Combine
import Foundation

/// UI-facing state for Homebrew reads and actions.
@MainActor
final class HomebrewStore: ObservableObject {
    @Published private(set) var installation: HomebrewInstallation?
    @Published private(set) var packages: [HomebrewPackage] = []
    @Published private(set) var services: [HomebrewService] = []
    @Published private(set) var outdatedPackages: [HomebrewOutdatedPackage] = []

    @Published private(set) var isCheckingInstallation = false
    @Published private(set) var isLoadingPackages = false
    @Published private(set) var isLoadingServices = false
    @Published private(set) var isCheckingUpdates = false
    @Published private(set) var mutatingService: String?
    @Published private(set) var updatingPackage: String?
    @Published private(set) var isUpgradingAll = false

    @Published private(set) var installationError: String?
    @Published private(set) var packagesError: String?
    @Published private(set) var servicesError: String?
    @Published private(set) var updatesError: String?
    @Published private(set) var searchError: String?

    @Published private(set) var searchResults: [HomebrewSearchResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var installingPackage: String?

    @Published private(set) var installationCheckedAt: Date?
    @Published private(set) var packagesLoadedAt: Date?
    @Published private(set) var servicesLoadedAt: Date?
    @Published private(set) var updatesCheckedAt: Date?

    private let client = HomebrewClient()

    var configuredCustomPath: String {
        UserDefaults.standard.string(forKey: "customHomebrewPath") ?? ""
    }

    var formulaCount: Int { packages.filter { $0.kind == .formula }.count }
    var caskCount: Int { packages.filter { $0.kind == .cask }.count }
    var directCount: Int { packages.filter { $0.isDirect }.count }
    var transitiveCount: Int { packages.filter { !$0.isDirect }.count }
    var runningServicesCount: Int { services.filter { $0.status.isRunning }.count }
    var hasLoadedPackages: Bool { packagesLoadedAt != nil }
    var hasLoadedServices: Bool { servicesLoadedAt != nil }
    var hasCheckedUpdates: Bool { updatesCheckedAt != nil }

    func checkInstallation(customPath: String? = nil) async {
        guard !isCheckingInstallation else { return }
        isCheckingInstallation = true
        installationError = nil
        defer { isCheckingInstallation = false }

        let path = customPath ?? configuredCustomPath
        do {
            let detected = try await client.detectInstallation(customPath: path)
            try Task.checkCancellation()
            installation = detected
            installationCheckedAt = Date()
        } catch is CancellationError {
        } catch {
            installation = nil
            installationError = error.localizedDescription
            installationCheckedAt = Date()
        }
    }

    private func ensureInstallation(customPath: String? = nil) async throws -> HomebrewInstallation {
        if let installation { return installation }
        let path = customPath ?? configuredCustomPath
        let detected = try await client.detectInstallation(customPath: path)
        try Task.checkCancellation()
        self.installation = detected
        self.installationCheckedAt = Date()
        return detected
    }

    func loadInstalledPackages(customPath: String? = nil) async {
        guard !isLoadingPackages else { return }
        isLoadingPackages = true
        packagesError = nil
        defer { isLoadingPackages = false }

        let install: HomebrewInstallation
        do {
            install = try await ensureInstallation(customPath: customPath)
        } catch is CancellationError {
            return
        } catch {
            installation = nil
            installationError = error.localizedDescription
            packages = []
            packagesLoadedAt = nil
            packagesError = error.localizedDescription
            return
        }

        do {
            let loadedPackages = try await client.listInstalledPackages(using: install)
            try Task.checkCancellation()
            packages = loadedPackages
            packagesLoadedAt = Date()
            packagesError = nil
        } catch is CancellationError {
        } catch {
            packagesError = error.localizedDescription
        }
    }

    func loadServices(customPath: String? = nil) async {
        guard !isLoadingServices else { return }
        isLoadingServices = true
        servicesError = nil
        defer { isLoadingServices = false }

        let install: HomebrewInstallation
        do {
            install = try await ensureInstallation(customPath: customPath)
        } catch is CancellationError {
            return
        } catch {
            servicesError = error.localizedDescription
            return
        }

        do {
            let loadedServices = try await client.listServices(using: install)
            try Task.checkCancellation()
            services = loadedServices
            servicesLoadedAt = Date()
            servicesError = nil
        } catch is CancellationError {
        } catch {
            servicesError = error.localizedDescription
        }
    }

    func startService(name: String, customPath: String? = nil) async {
        guard mutatingService == nil else { return }
        mutatingService = name
        servicesError = nil
        defer { mutatingService = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.startService(name: name, using: install)
            let updatedServices = try await client.listServices(using: install)
            services = updatedServices
            servicesLoadedAt = Date()
        } catch is CancellationError {
        } catch {
            servicesError = error.localizedDescription
        }
    }

    func stopService(name: String, customPath: String? = nil) async {
        guard mutatingService == nil else { return }
        mutatingService = name
        servicesError = nil
        defer { mutatingService = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.stopService(name: name, using: install)
            let updatedServices = try await client.listServices(using: install)
            services = updatedServices
            servicesLoadedAt = Date()
        } catch is CancellationError {
        } catch {
            servicesError = error.localizedDescription
        }
    }

    func checkUpdates(customPath: String? = nil) async {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        updatesError = nil
        defer { isCheckingUpdates = false }

        let install: HomebrewInstallation
        do {
            install = try await ensureInstallation(customPath: customPath)
        } catch is CancellationError {
            return
        } catch {
            updatesError = error.localizedDescription
            return
        }

        do {
            let outdated = try await client.listOutdatedPackages(using: install)
            try Task.checkCancellation()
            outdatedPackages = outdated
            updatesCheckedAt = Date()
            updatesError = nil
        } catch is CancellationError {
        } catch {
            updatesError = error.localizedDescription
        }
    }

    func upgradePackage(package: HomebrewOutdatedPackage, customPath: String? = nil) async {
        guard updatingPackage == nil && !isUpgradingAll else { return }
        updatingPackage = package.name
        updatesError = nil
        defer { updatingPackage = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.upgradePackage(name: package.name, kind: package.kind, using: install)
            outdatedPackages.removeAll { $0.id == package.id }
            if let refreshed = try? await client.listOutdatedPackages(using: install) {
                outdatedPackages = refreshed
            }
        } catch is CancellationError {
        } catch {
            updatesError = error.localizedDescription
        }
    }

    func upgradeAll(customPath: String? = nil) async {
        guard !isUpgradingAll && updatingPackage == nil else { return }
        isUpgradingAll = true
        updatesError = nil
        defer { isUpgradingAll = false }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.upgradeAll(using: install)
            outdatedPackages = []
            if let refreshed = try? await client.listOutdatedPackages(using: install) {
                outdatedPackages = refreshed
            }
        } catch is CancellationError {
        } catch {
            updatesError = error.localizedDescription
        }
    }

    func searchCatalogue(query: String, kind: HomebrewPackageKind, customPath: String? = nil) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            searchError = nil
            return
        }

        isSearching = true
        searchError = nil
        defer { isSearching = false }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            let results = try await client.searchCatalogue(query: trimmed, kind: kind, using: install)
            try Task.checkCancellation()
            searchResults = results
            searchError = nil
        } catch is CancellationError {
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }
    }

    func installPackage(name: String, kind: HomebrewPackageKind, customPath: String? = nil) async {
        guard installingPackage == nil else { return }
        installingPackage = name
        searchError = nil
        defer { installingPackage = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.installPackage(name: name, kind: kind, using: install)
            if let refreshed = try? await client.listInstalledPackages(using: install) {
                packages = refreshed
            }
            searchResults = searchResults.map { item in
                if item.name == name && item.kind == kind {
                    return HomebrewSearchResult(name: item.name, kind: item.kind, isInstalled: true, isDisabled: item.isDisabled)
                }
                return item
            }
        } catch is CancellationError {
        } catch {
            searchError = error.localizedDescription
        }
    }
}
