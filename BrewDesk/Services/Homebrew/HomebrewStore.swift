import Combine
import Foundation

/// UI-facing state for explicit, finite Homebrew reads. This store creates no timers or observers.
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

    @Published private(set) var installationCheckedAt: Date?
    @Published private(set) var packagesLoadedAt: Date?
    @Published private(set) var servicesLoadedAt: Date?
    @Published private(set) var updatesCheckedAt: Date?

    private let client = HomebrewClient()

    var formulaCount: Int { packages.filter { $0.kind == .formula }.count }
    var caskCount: Int { packages.filter { $0.kind == .cask }.count }
    var directCount: Int { packages.filter { $0.isDirect }.count }
    var transitiveCount: Int { packages.filter { !$0.isDirect }.count }
    var runningServicesCount: Int { services.filter { $0.status.isRunning }.count }
    var hasLoadedPackages: Bool { packagesLoadedAt != nil }
    var hasLoadedServices: Bool { servicesLoadedAt != nil }
    var hasCheckedUpdates: Bool { updatesCheckedAt != nil }

    func checkInstallation(customPath: String) async {
        guard !isCheckingInstallation else { return }
        isCheckingInstallation = true
        installationError = nil
        defer { isCheckingInstallation = false }

        do {
            let detected = try await client.detectInstallation(customPath: customPath)
            try Task.checkCancellation()
            installation = detected
            installationCheckedAt = Date()
        } catch is CancellationError {
            // Cancellation is expected when the view or application is closing.
        } catch {
            installation = nil
            installationError = error.localizedDescription
            installationCheckedAt = Date()
        }
    }

    private func ensureInstallation(customPath: String) async throws -> HomebrewInstallation {
        if let installation {
            return installation
        }
        let detected = try await client.detectInstallation(customPath: customPath)
        try Task.checkCancellation()
        self.installation = detected
        self.installationCheckedAt = Date()
        return detected
    }

    func loadInstalledPackages(customPath: String) async {
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
            // Preserve the last successful package list when a refresh is cancelled.
        } catch {
            packagesError = error.localizedDescription
        }
    }

    func loadServices(customPath: String) async {
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

    func startService(name: String, customPath: String) async {
        guard mutatingService == nil else { return }
        mutatingService = name
        servicesError = nil
        defer { mutatingService = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.startService(name: name, using: install)
            // Refresh service list
            let updatedServices = try await client.listServices(using: install)
            services = updatedServices
            servicesLoadedAt = Date()
        } catch is CancellationError {
        } catch {
            servicesError = error.localizedDescription
        }
    }

    func stopService(name: String, customPath: String) async {
        guard mutatingService == nil else { return }
        mutatingService = name
        servicesError = nil
        defer { mutatingService = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.stopService(name: name, using: install)
            // Refresh service list
            let updatedServices = try await client.listServices(using: install)
            services = updatedServices
            servicesLoadedAt = Date()
        } catch is CancellationError {
        } catch {
            servicesError = error.localizedDescription
        }
    }

    func checkUpdates(customPath: String) async {
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

    func upgradePackage(package: HomebrewOutdatedPackage, customPath: String) async {
        guard updatingPackage == nil && !isUpgradingAll else { return }
        updatingPackage = package.name
        updatesError = nil
        defer { updatingPackage = nil }

        do {
            let install = try await ensureInstallation(customPath: customPath)
            try await client.upgradePackage(name: package.name, kind: package.kind, using: install)
            // Remove from outdated list
            outdatedPackages.removeAll { $0.id == package.id }
            // Refresh outdated in background
            if let refreshed = try? await client.listOutdatedPackages(using: install) {
                outdatedPackages = refreshed
            }
        } catch is CancellationError {
        } catch {
            updatesError = error.localizedDescription
        }
    }

    func upgradeAll(customPath: String) async {
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
}
