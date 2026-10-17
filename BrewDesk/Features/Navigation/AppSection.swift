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
        case .overview: return "Overview"
        case .installed: return "Installed"
        case .discover: return "Discover"
        case .updates: return "Updates"
        case .cleaner: return "Cleaner"
        case .ports: return "Ports"
        case .commands: return "Commands"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .installed: return "shippingbox"
        case .discover: return "sparkle.magnifyingglass"
        case .updates: return "arrow.triangle.2.circlepath"
        case .cleaner: return "sparkles"
        case .ports: return "point.3.connected.trianglepath.dotted"
        case .commands: return "terminal"
        case .settings: return "gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "A clear view of your Mac tools."
        case .installed: return "Review formulae, apps, and services."
        case .discover: return "Explore the Homebrew catalogue."
        case .updates: return "See what may need updating."
        case .cleaner: return "Review files before removing anything."
        case .ports: return "See what is listening on your Mac."
        case .commands: return "Find and copy common Homebrew commands."
        case .settings: return "Make BrewDesk feel right for you."
        }
    }

    var supportsSearch: Bool {
        switch self {
        case .installed, .discover, .ports, .commands: return true
        default: return false
        }
    }

    static let workspace: [AppSection] = [.overview, .installed, .discover, .updates]
    static let utilities: [AppSection] = [.cleaner, .ports, .commands]
}
