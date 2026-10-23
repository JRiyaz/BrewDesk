import Foundation

enum HomebrewPackageKind: String, CaseIterable, Identifiable, Codable {
    case formula
    case cask
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .formula: "Formula"
        case .cask: "Cask"
        }
    }
}

struct HomebrewPackage: Identifiable, Hashable, Codable {
    let name: String
    let version: String
    let kind: HomebrewPackageKind
    let isDirect: Bool
    
    init(name: String, version: String, kind: HomebrewPackageKind, isDirect: Bool = true) {
        self.name = name
        self.version = version
        self.kind = kind
        self.isDirect = isDirect
    }
    
    var id: String { "\(kind.rawValue):\(name)" }
    
    var versionLabel: String {
        version.isEmpty ? "Version not reported" : version
    }
}

enum HomebrewServiceStatus: String, CaseIterable, Identifiable, Codable, Sendable {
    case started
    case stopped
    case error
    case unknown
    
    var id: String { rawValue }
    
    var isRunning: Bool {
        self == .started
    }
    
    var title: String {
        switch self {
        case .started: "Running"
        case .stopped: "Stopped"
        case .error: "Error"
        case .unknown: "Unknown"
        }
    }
}

struct HomebrewService: Identifiable, Hashable, Sendable {
    let name: String
    let status: HomebrewServiceStatus
    let user: String?
    let file: String?
    
    var id: String { name }
}

struct HomebrewOutdatedPackage: Identifiable, Hashable, Sendable {
    let name: String
    let installedVersion: String
    let currentVersion: String
    let kind: HomebrewPackageKind
    let isPinned: Bool
    let isDirect: Bool
    
    init(
        name: String,
        installedVersion: String,
        currentVersion: String,
        kind: HomebrewPackageKind,
        isPinned: Bool,
        isDirect: Bool = true
    ) {
        self.name = name
        self.installedVersion = installedVersion
        self.currentVersion = currentVersion
        self.kind = kind
        self.isPinned = isPinned
        self.isDirect = isDirect
    }
    
    var id: String { "\(kind.rawValue):\(name)" }
    
    var upgradeCommand: String {
        kind == .cask ? "brew upgrade --cask \(name)" : "brew upgrade \(name)"
    }
}

struct HomebrewSearchResult: Identifiable, Hashable, Sendable {
    let name: String
    let kind: HomebrewPackageKind
    let isInstalled: Bool
    let isDisabled: Bool
    
    var id: String { "\(kind.rawValue):\(name)" }
    
    var installCommand: String {
        kind == .cask ? "brew install --cask \(name)" : "brew install \(name)"
    }
}

struct HomebrewInstallation: Equatable {
    let executablePath: String
    let version: String
    let prefix: String
}

enum HomebrewClientError: LocalizedError {
    case detectionFailed(String)
    case invalidCustomPath(String)
    case commandFailed(command: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .detectionFailed(let details):
            return "Purge could not validate Homebrew.\n\(details)"
        case .invalidCustomPath(let path):
            return "The custom Homebrew path is not an executable file: \(path)"
        case .commandFailed(let command, let reason):
            return "`\(command)` failed. \(reason)"
        }
    }
}
