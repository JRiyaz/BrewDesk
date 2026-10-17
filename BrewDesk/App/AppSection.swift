import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case overview
    case installed
    case services
    case discover
    case updates
    case cleaner
    case commands
    case ports
    case systemCleaner
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .installed: "Installed"
        case .services: "Services"
        case .discover: "Discover"
        case .updates: "Updates"
        case .cleaner: "Cleaner"
        case .commands: "Commands"
        case .ports: "Ports"
        case .systemCleaner: "System Cleaner"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .installed: "shippingbox"
        case .services: "gearshape.2"
        case .discover: "sparkle.magnifyingglass"
        case .updates: "arrow.triangle.2.circlepath"
        case .cleaner: "sparkles"
        case .commands: "terminal"
        case .ports: "point.3.connected.trianglepath.dotted"
        case .systemCleaner: "internaldrive"
        case .settings: "gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: "A clear view of your Mac tools."
        case .installed: "Review formulae, apps, and services."
        case .services: "Manage Homebrew background services."
        case .discover: "Explore the Homebrew catalogue."
        case .updates: "See what may need updating."
        case .cleaner: "Manage Homebrew cache, outdated versions, and dependencies."
        case .commands: "Find and copy common Homebrew commands."
        case .ports: "See what is listening on your Mac."
        case .systemCleaner: "Reclaim disk space from caches, logs, and development stores."
        case .settings: "Make BrewDesk feel right for you."
        }
    }

    var supportsSearch: Bool {
        switch self {
        case .installed, .services, .discover, .ports, .commands, .systemCleaner: true
        default: false
        }
    }

    static let homebrew: [AppSection] = [.overview, .installed, .services, .discover, .updates, .cleaner, .commands]
    static let utilities: [AppSection] = [.ports, .systemCleaner]
    static var workspace: [AppSection] { homebrew }
}
