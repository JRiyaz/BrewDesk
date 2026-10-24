import AppKit
import Foundation
import SwiftUI

struct MoleInstallation: Equatable, Sendable {
    let executablePath: String
    let version: String
    let macOSVersion: String
    let architecture: String
    let sipStatus: String
    let diskFree: String
    let installSource: String
    let shell: String
    
    init(
        executablePath: String,
        version: String = "1.0",
        macOSVersion: String = "macOS",
        architecture: String = "arm64",
        sipStatus: String = "Enabled",
        diskFree: String = "Available",
        installSource: String = "Homebrew",
        shell: String = "/bin/zsh"
    ) {
        self.executablePath = executablePath
        self.version = version
        self.macOSVersion = macOSVersion
        self.architecture = architecture
        self.sipStatus = sipStatus
        self.diskFree = diskFree
        self.installSource = installSource
        self.shell = shell
    }
}

struct MoleSystemVitals: Equatable, Sendable {
    let healthScore: Int
    let healthScoreMsg: String
    let cpuPercent: Double
    let memoryPercent: Double
    let memoryUsedBytes: Int64
    let memoryTotalBytes: Int64
    let diskUsedPercent: Double
    let diskUsedBytes: Int64
    let diskTotalBytes: Int64
    let trashSizeBytes: Int64
    let hardwareModel: String
    let cpuModel: String
    let totalRam: String
    let uptime: String
    let batteryStatus: String
    let thermalStatus: String
    
    // Legacy string properties for backward compatibility
    var disk: String {
        let free = max(0, diskTotalBytes - diskUsedBytes)
        let freeStr = ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
        let totalStr = ByteCountFormatter.string(fromByteCount: diskTotalBytes, countStyle: .file)
        return "\(freeStr) free of \(totalStr) (\(String(format: "%.1f", diskUsedPercent))% used)"
    }
    
    var memory: String {
        let usedStr = ByteCountFormatter.string(fromByteCount: memoryUsedBytes, countStyle: .memory)
        let totalStr = ByteCountFormatter.string(fromByteCount: memoryTotalBytes, countStyle: .memory)
        return "\(usedStr) used of \(totalStr) (\(String(format: "%.1f", memoryPercent))%)"
    }
    
    var battery: String { batteryStatus }
    var load: String { "\(String(format: "%.1f", cpuPercent))% CPU" }
    var network: String { "Active" }
    var thermal: String { thermalStatus }
    
    var diskAvailable: String {
        let free = max(0, diskTotalBytes - diskUsedBytes)
        return ByteCountFormatter.string(fromByteCount: free, countStyle: .file) + " free"
    }
    
    var memoryUsage: String {
        let usedStr = ByteCountFormatter.string(fromByteCount: memoryUsedBytes, countStyle: .memory)
        return "\(usedStr) used (\(String(format: "%.0f", memoryPercent))%)"
    }
    
    var formattedFreeDisk: String {
        let free = max(0, diskTotalBytes - diskUsedBytes)
        return ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
    }
    
    var formattedTotalDisk: String {
        ByteCountFormatter.string(fromByteCount: diskTotalBytes, countStyle: .file)
    }
    
    var formattedTrash: String {
        ByteCountFormatter.string(fromByteCount: trashSizeBytes, countStyle: .file)
    }
    
    static func gaugeTint(value: Double) -> Color {
        if value >= 75 { return Color.red }
        if value >= 50 { return Color.orange }
        return Color.green
    }
}

// MARK: - Mole Module Tabs (mole-gui style)

enum MoleModuleTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case clean = "Clean"
    case uninstall = "Uninstall"
    case analyze = "Analyze"
    case optimize = "Optimize"
    case purge = "Purge"
    case installers = "Installers"
    case history = "History"
    case commands = "Commands"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .clean: return "System Clean"
        case .uninstall: return "App Uninstaller"
        case .analyze: return "Disk Analysis"
        case .optimize: return "System Optimize"
        case .purge: return "Project Purge"
        case .installers: return "Installer Sweep"
        case .history: return "History & Logs"
        case .commands: return "Command Catalog"
        }
    }
    
    var symbol: String {
        switch self {
        case .dashboard: return "gauge.medium"
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .analyze: return "chart.pie"
        case .optimize: return "speedometer"
        case .purge: return "folder.badge.minus"
        case .installers: return "archivebox"
        case .history: return "clock.arrow.circlepath"
        case .commands: return "terminal"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .dashboard: return Color(red: 107/255, green: 64/255, blue: 209/255)
        case .clean: return Color(red: 31/255, green: 140/255, blue: 89/255)
        case .uninstall: return Color(red: 140/255, green: 64/255, blue: 199/255)
        case .analyze: return Color(red: 26/255, green: 128/255, blue: 166/255)
        case .optimize: return Color(red: 202/255, green: 148/255, blue: 30/255)
        case .purge: return Color(red: 104/255, green: 96/255, blue: 186/255)
        case .installers: return Color(red: 186/255, green: 62/255, blue: 68/255)
        case .history: return Color(red: 88/255, green: 94/255, blue: 110/255)
        case .commands: return Color.blue
        }
    }
    
    var ringGradient: [Color] {
        switch self {
        case .dashboard: return [Color(red: 89/255, green: 56/255, blue: 184/255), Color(red: 140/255, green: 98/255, blue: 228/255)]
        case .clean: return [Color(red: 31/255, green: 135/255, blue: 84/255), Color(red: 76/255, green: 178/255, blue: 120/255)]
        case .uninstall: return [Color(red: 124/255, green: 52/255, blue: 168/255), Color(red: 172/255, green: 102/255, blue: 220/255)]
        case .analyze: return [Color(red: 24/255, green: 118/255, blue: 156/255), Color(red: 66/255, green: 168/255, blue: 204/255)]
        case .optimize: return [Color(red: 196/255, green: 140/255, blue: 26/255), Color(red: 228/255, green: 180/255, blue: 62/255)]
        case .purge: return [Color(red: 88/255, green: 82/255, blue: 176/255), Color(red: 140/255, green: 132/255, blue: 216/255)]
        case .installers: return [Color(red: 176/255, green: 56/255, blue: 62/255), Color(red: 218/255, green: 106/255, blue: 112/255)]
        case .history: return [Color(red: 72/255, green: 78/255, blue: 92/255), Color(red: 108/255, green: 114/255, blue: 130/255)]
        case .commands: return [Color.blue, Color.cyan]
        }
    }
}

// MARK: - Clean Preview Models

struct CleanItem: Identifiable, Hashable, Sendable {
    var id: String { path }
    let section: String
    let path: String
    let sizeKb: Int64
    let itemCount: Int
    let isSizeKnown: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeKb * 1024, countStyle: .file)
    }
}

struct CleanSectionSummary: Identifiable, Hashable, Sendable {
    var id: String { section }
    let section: String
    var totalSizeKb: Int64
    var itemCount: Int
    var items: [CleanItem]
    
    init(section: String, totalSizeKb: Int64? = nil, itemCount: Int? = nil, items: [CleanItem] = []) {
        self.section = section
        self.items = items
        self.totalSizeKb = totalSizeKb ?? items.reduce(0) { $0 + $1.sizeKb }
        self.itemCount = itemCount ?? items.count
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSizeKb * 1024, countStyle: .file)
    }
}

// MARK: - Disk Analysis Models

struct AnalyzeEntry: Identifiable, Hashable, Sendable {
    var id: String { path }
    let name: String
    let path: String
    let size: Int64
    let isDir: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct AnalyzeResult: Sendable {
    let path: String
    let totalSize: Int64
    let totalFiles: Int
    let entries: [AnalyzeEntry]
    let largeFiles: [AnalyzeEntry]
    
    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Optimize Diagnostic Models

enum OptimizeStatus: String, Sendable {
    case ok
    case warn
    case info
}

struct OptimizeDiagnosticItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let details: String
    let status: OptimizeStatus
}

// MARK: - Installed App Model

struct MoleInstalledApp: Identifiable, Hashable, Codable, Sendable {
    let name: String?
    let bundle_id: String?
    let source: String?
    let uninstall_name: String?
    let path: String?
    let size: String?
    
    var id: String { bundle_id ?? path ?? (name ?? UUID().uuidString) }
    
    var displayName: String {
        if let name = name, !name.isEmpty { return name }
        if let uninstall_name = uninstall_name, !uninstall_name.isEmpty { return uninstall_name }
        return "Application"
    }
    
    var safeUninstallName: String {
        uninstall_name ?? name ?? ""
    }
    
    var safePath: String {
        path ?? ""
    }
    
    var safeBundleId: String {
        bundle_id ?? "Unknown ID"
    }
    
    var safeSize: String {
        size ?? "Available"
    }
    
    var dryRunCommand: String {
        "mo uninstall --dry-run \"\(safeUninstallName)\""
    }
    
    var uninstallCommand: String {
        "mo uninstall \"\(safeUninstallName)\""
    }
    
    var withDataCommand: String {
        "mo uninstall --with-data \"\(safeUninstallName)\""
    }
    
    var bundlePath: String {
        if let path = path, !path.isEmpty { return path }
        return "/Applications/\(displayName).app"
    }
}

// MARK: - App Uninstall Preview Models

struct AppUninstallPreviewItem: Identifiable, Hashable, Sendable {
    let id: String
    let path: String
    let category: String
    let sizeBytes: Int64
    
    var formattedSize: String {
        if sizeBytes == 0 { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

struct AppUninstallPreview: Identifiable, Hashable, Sendable {
    let id: String
    let app: MoleInstalledApp
    let totalSizeBytes: Int64
    let items: [AppUninstallPreviewItem]
    let rawOutput: String
    let isRootProtected: Bool
    
    var formattedTotalSize: String {
        if totalSizeBytes == 0 { return app.safeSize }
        return ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
    }
}

// MARK: - Command Catalog Models

enum MoleModuleCategory: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case uninstall = "Uninstall"
    case optimize = "Optimize"
    case purge = "Projects"
    case installers = "Installers"
    case slim = "App Slimmer"
    case analyze = "Analyze"
    case status = "Vitals"
    case history = "History"
    case commands = "Commands"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .clean: return "System Clean"
        case .uninstall: return "Uninstall Apps"
        case .optimize: return "Optimize"
        case .purge: return "Project Purge"
        case .installers: return "Installers"
        case .slim: return "App Slimmer"
        case .analyze: return "Disk Analysis"
        case .status: return "System Vitals"
        case .history: return "History"
        case .commands: return "Commands"
        }
    }
    
    var symbol: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .optimize: return "speedometer"
        case .purge: return "folder.badge.minus"
        case .installers: return "archivebox"
        case .slim: return "bolt.shield"
        case .analyze: return "chart.pie"
        case .status: return "heart.text.square"
        case .history: return "clock.arrow.circlepath"
        case .commands: return "terminal"
        }
    }
}

struct MoleActionItem: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let command: String
    let dryRunCommand: String
    let category: MoleModuleCategory
    let dangerLevel: String
    let isDryRunSupported: Bool
    let requiresSudo: Bool
    let tip: String
}

enum MoleCatalog {
    static let actions: [MoleActionItem] = [
        // Clean
        .init(
            id: "clean",
            title: "Clean all system debris",
            description: "Remove caches, logs, temporary files, and app leftovers from uninstalled apps.",
            command: "mo clean",
            dryRunCommand: "mo clean --dry-run",
            category: .clean,
            dangerLevel: "Safe",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Safe dry run lists everything before anything is deleted."
        ),
        .init(
            id: "clean-whitelist",
            title: "Manage clean whitelist",
            description: "Configure directories and caches that Mole should never touch during cleanup.",
            command: "mo clean --whitelist",
            dryRunCommand: "mo clean --whitelist",
            category: .clean,
            dangerLevel: "Settings",
            isDryRunSupported: false,
            requiresSudo: false,
            tip: "Opens interactive whitelist editor in terminal."
        ),
        .init(
            id: "clean-external",
            title: "Clean external volume metadata",
            description: "Remove macOS metadata (.DS_Store, .Spotlight, .Trashes) from an external drive.",
            command: "mo clean --external /Volumes",
            dryRunCommand: "mo clean --dry-run",
            category: .clean,
            dangerLevel: "Safe",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Cleans junk files from mounted external drives and USB sticks."
        ),
        
        // Uninstall
        .init(
            id: "uninstall-interactive",
            title: "Interactive app uninstaller",
            description: "Browse installed apps with arrow keys and remove selected apps with leftovers sent to Trash.",
            command: "mo uninstall",
            dryRunCommand: "mo uninstall --list",
            category: .uninstall,
            dangerLevel: "Interactive",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Mole moves files to macOS Trash by default so they can be recovered."
        ),
        .init(
            id: "uninstall-list",
            title: "List removable apps",
            description: "Scan and list all installed applications and their calculated bundle sizes.",
            command: "mo uninstall --list",
            dryRunCommand: "mo uninstall --list",
            category: .uninstall,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Outputs complete JSON catalogue of installed applications."
        ),
        
        // Optimize
        .init(
            id: "optimize",
            title: "System optimization & repair",
            description: "Refresh system caches and services, flush DNS cache, repair safe maintenance issues.",
            command: "mo optimize",
            dryRunCommand: "mo optimize --dry-run",
            category: .optimize,
            dangerLevel: "Safe",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Clears DNS caches, restarts background system services, and refreshes UI cache."
        ),
        .init(
            id: "optimize-whitelist",
            title: "Manage optimize whitelist",
            description: "Protect specific services and caches from being refreshed or cleared.",
            command: "mo optimize --whitelist",
            dryRunCommand: "mo optimize --whitelist",
            category: .optimize,
            dangerLevel: "Settings",
            isDryRunSupported: false,
            requiresSudo: false,
            tip: "Allows excluding critical local services."
        ),
        
        // Projects
        .init(
            id: "purge-projects",
            title: "Purge project build artifacts",
            description: "Scan projects and clean heavy node_modules, target, build directories, and DerivedData.",
            command: "mo purge --yes",
            dryRunCommand: "mo purge --dry-run",
            category: .purge,
            dangerLevel: "Destructive",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Recovers gigabytes from dormant git repos and project directories."
        ),
        .init(
            id: "purge-paths",
            title: "Configure scan paths",
            description: "Edit custom project scan directories where Mole looks for build artifacts.",
            command: "mo purge --paths",
            dryRunCommand: "mo purge --paths",
            category: .purge,
            dangerLevel: "Settings",
            isDryRunSupported: false,
            requiresSudo: false,
            tip: "Add ~/Projects, ~/Work, ~/Code or other custom project roots."
        ),
        .init(
            id: "purge-empty",
            title: "Show zero-size project folders",
            description: "Preview empty project artifact directories across your repositories.",
            command: "mo purge --include-empty --dry-run",
            dryRunCommand: "mo purge --include-empty --dry-run",
            category: .purge,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Identifies empty directories left behind by builds."
        ),
        
        // Installers
        .init(
            id: "installer",
            title: "Installer files sweep",
            description: "Locate and remove leftover installer packages (.dmg, .pkg, .iso, .zip).",
            command: "mo installer",
            dryRunCommand: "mo installer --dry-run",
            category: .installers,
            dangerLevel: "Safe",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Scans Downloads, Desktop, and user folders for installer media you no longer need."
        ),
        
        // Slimmer
        .init(
            id: "slim",
            title: "Universal app slimmer",
            description: "Remove unused Intel x86_64 code from universal applications on Apple Silicon.",
            command: "mo slim",
            dryRunCommand: "mo slim --dry-run",
            category: .slim,
            dangerLevel: "System",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Validates Gatekeeper and code signing before replacing the slimmed app."
        ),
        
        // Analyze
        .init(
            id: "analyze-overview",
            title: "Machine-wide disk analysis",
            description: "Interactive visual disk exploration to pinpoint large folders and files.",
            command: "mo analyze",
            dryRunCommand: "mo analyze --json /Applications",
            category: .analyze,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Fast visual inspection of disk space consumption."
        ),
        .init(
            id: "analyze-apps",
            title: "Analyze /Applications folder",
            description: "Inspect exact disk usage and breakdown of installed macOS applications.",
            command: "mo analyze /Applications",
            dryRunCommand: "mo analyze --json /Applications",
            category: .analyze,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Finds the largest installed applications on your drive."
        ),
        .init(
            id: "analyze-library",
            title: "Analyze ~/Library folder",
            description: "Scan the user Library folder to find bloated application support and cache trees.",
            command: "mo analyze ~/Library",
            dryRunCommand: "mo analyze --json ~/Library",
            category: .analyze,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Uncovers hidden disk hogs inside ~/Library."
        ),
        .init(
            id: "analyze-caches",
            title: "Analyze user Caches folder",
            description: "Scan ~/Library/Caches to reveal which apps are hoarding disk space.",
            command: "mo analyze ~/Library/Caches",
            dryRunCommand: "mo analyze --json ~/Library/Caches",
            category: .analyze,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Pinpoint large caches from browsers, IDEs, and desktop apps."
        ),
        .init(
            id: "analyze-volumes",
            title: "Analyze external drives",
            description: "Scan external volumes to discover what is consuming storage space.",
            command: "mo analyze /Volumes",
            dryRunCommand: "mo analyze --json /Volumes",
            category: .analyze,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Quick visual scan for connected drives."
        ),
        
        // Vitals
        .init(
            id: "status-vitals",
            title: "Live system health monitor",
            description: "Interactive live terminal monitor with CPU, GPU, memory, I/O and thermals.",
            command: "mo status",
            dryRunCommand: "mo status --json",
            category: .status,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Queries native macOS sensors for complete vitals."
        ),
        .init(
            id: "status-snapshot",
            title: "Export vitals snapshot (JSON)",
            description: "Capture current system health metrics snapshot in machine-readable JSON format.",
            command: "mo status --json",
            dryRunCommand: "mo status --json",
            category: .status,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Instant snapshot of CPU, RAM, battery, and disks."
        ),
        
        // History
        .init(
            id: "history-log",
            title: "Cleanup history & audit log",
            description: "Review recent Mole operation logs, reclaimed disk space, and deletion records.",
            command: "mo history",
            dryRunCommand: "mo history --json",
            category: .history,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Shows forensic audit records of past operations."
        ),
        .init(
            id: "history-limit",
            title: "Recent 50 operations audit",
            description: "Inspect the last 50 cleanup and optimization operations performed.",
            command: "mo history --limit 50",
            dryRunCommand: "mo history --json",
            category: .history,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Quickly view recent cleanup actions."
        ),
        
        // Commands & Tools
        .init(
            id: "touchid-status",
            title: "Touch ID sudo status",
            description: "Check if Touch ID authentication for sudo is currently active.",
            command: "mo touchid status",
            dryRunCommand: "mo touchid status",
            category: .commands,
            dangerLevel: "Read only",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Verifies PAM configuration for Touch ID."
        ),
        .init(
            id: "touchid-enable",
            title: "Enable Touch ID for sudo",
            description: "Configure Touch ID authentication for sudo privileges in Terminal.",
            command: "mo touchid enable",
            dryRunCommand: "mo touchid enable --dry-run",
            category: .commands,
            dangerLevel: "System",
            isDryRunSupported: true,
            requiresSudo: true,
            tip: "Allows you to authenticate sudo commands using your fingerprint."
        ),
        .init(
            id: "touchid-disable",
            title: "Disable Touch ID for sudo",
            description: "Revert sudo authentication back to standard password prompt.",
            command: "mo touchid disable",
            dryRunCommand: "mo touchid disable",
            category: .commands,
            dangerLevel: "System",
            isDryRunSupported: false,
            requiresSudo: true,
            tip: "Restores standard sudo password authentication."
        ),
        .init(
            id: "completion",
            title: "Shell tab completion",
            description: "Install auto-completion scripts for zsh and bash.",
            command: "mo completion",
            dryRunCommand: "mo completion --dry-run",
            category: .commands,
            dangerLevel: "Setup",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Enables fast tab-completion for mo commands."
        ),
        .init(
            id: "update",
            title: "Update Mole",
            description: "Upgrade Mole to the latest stable release.",
            command: "mo update",
            dryRunCommand: "mo --version",
            category: .commands,
            dangerLevel: "Maintenance",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Fetches latest stable release from Homebrew or official repo."
        ),
        .init(
            id: "update-force",
            title: "Force reinstall Mole",
            description: "Force reinstall the latest stable version of Mole.",
            command: "mo update --force",
            dryRunCommand: "mo --version",
            category: .commands,
            dangerLevel: "Maintenance",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Reinstalls binaries and repair links."
        ),
        .init(
            id: "update-nightly",
            title: "Install nightly build",
            description: "Install the latest bleeding-edge build from main branch.",
            command: "mo update --nightly",
            dryRunCommand: "mo --version",
            category: .commands,
            dangerLevel: "Advanced",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "For testing new, unreleased Mole features."
        ),
        .init(
            id: "remove",
            title: "Preview Mole removal",
            description: "Review what files would be removed if Mole were uninstalled.",
            command: "mo remove --dry-run",
            dryRunCommand: "mo remove --dry-run",
            category: .commands,
            dangerLevel: "Maintenance",
            isDryRunSupported: true,
            requiresSudo: false,
            tip: "Safe dry-run preview of uninstalling Mole."
        )
    ]
}
