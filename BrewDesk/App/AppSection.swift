import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case overview
    case installed
    case discover
    case updates
    case cleaner
    case ports
    case commands
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .installed: "Installed"
        case .discover: "Discover"
        case .updates: "Updates"
        case .cleaner: "Cleaner"
        case .ports: "Ports"
        case .commands: "Commands"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .installed: "shippingbox"
        case .discover: "sparkle.magnifyingglass"
        case .updates: "arrow.triangle.2.circlepath"
        case .cleaner: "sparkles"
        case .ports: "point.3.connected.trianglepath.dotted"
        case .commands: "terminal"
        case .settings: "gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: "A clear view of your Mac tools."
        case .installed: "Review formulae, apps, and services."
        case .discover: "Explore the Homebrew catalogue."
        case .updates: "See what may need updating."
        case .cleaner: "Review files before removing anything."
        case .ports: "See what is listening on your Mac."
        case .commands: "Find and copy common Homebrew commands."
        case .settings: "Make BrewDesk feel right for you."
        }
    }

    var supportsSearch: Bool {
        switch self {
        case .installed, .discover, .ports, .commands: true
        default: false
        }
    }

    static let workspace: [AppSection] = [.overview, .installed, .discover, .updates]
    static let utilities: [AppSection] = [.cleaner, .ports, .commands]
}
