import Foundation

struct CommandReference: Identifiable {
    let id: String
    let title: String
    let description: String
    let command: String
    let riskLabel: String
    let changesSystem: Bool
}

enum CommandCatalog {
    static let items: [CommandReference] = [
        .init(id: "version", title: "Homebrew version", description: "Show the installed Homebrew version.", command: "brew --version", riskLabel: "Read only", changesSystem: false),
        .init(id: "doctor", title: "Diagnostics", description: "Check the Homebrew environment for common issues.", command: "brew doctor", riskLabel: "Read only", changesSystem: false),
        .init(id: "search", title: "Search packages", description: "Search the catalogue for a formula or cask by name.", command: "brew search <name>", riskLabel: "Read only", changesSystem: false),
        .init(id: "info", title: "Package details", description: "Show metadata and dependencies for a package.", command: "brew info <formula-or-cask>", riskLabel: "Read only", changesSystem: false),
        .init(id: "list-formula", title: "List formulae", description: "List formulae currently installed by Homebrew.", command: "brew list --formula", riskLabel: "Read only", changesSystem: false),
        .init(id: "list-cask", title: "List casks", description: "List installed casks, commonly GUI applications.", command: "brew list --cask", riskLabel: "Read only", changesSystem: false),
        .init(id: "outdated", title: "Check outdated packages", description: "Report packages for which Homebrew lists an update.", command: "brew outdated --json=v2", riskLabel: "Read only", changesSystem: false),
        .init(id: "update", title: "Refresh package metadata", description: "Fetch the latest Homebrew package definitions. Does not itself upgrade installed packages.", command: "brew update", riskLabel: "Changes metadata", changesSystem: true),
        .init(id: "upgrade", title: "Upgrade packages", description: "Upgrade installed packages that have newer versions. Dependencies may also change.", command: "brew upgrade", riskLabel: "Changes system", changesSystem: true),
        .init(id: "uninstall", title: "Uninstall a package", description: "Uninstall a specific formula. Review dependencies and package type first.", command: "brew uninstall <formula>", riskLabel: "Destructive", changesSystem: true),
        .init(id: "cleanup", title: "Cleanup old versions", description: "Remove old versions and stale downloads managed by Homebrew.", command: "brew cleanup", riskLabel: "Destructive", changesSystem: true),
        .init(id: "services", title: "List Homebrew services", description: "Show service status supported by the installed Homebrew version.", command: "brew services list", riskLabel: "Read only", changesSystem: false)
    ]
}
