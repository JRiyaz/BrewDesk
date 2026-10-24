import AppKit
import SwiftUI

// MARK: - Models

struct UninstallLibraryPath: Identifiable {
    let id: String
    let path: String
    let scope: Scope
    let description: String
    let targetType: String
    
    enum Scope: String, CaseIterable, Identifiable {
        case all = "All"
        case user = "User (~)"
        case system = "System (/)"
        case sandbox = "Sandbox"
        
        var id: String { rawValue }
    }
}

struct UninstallCommandItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let rawCommandTemplate: String
    let riskLabel: String
    let changesSystem: Bool
    let note: String?
}

// MARK: - View

struct AppUninstallGuideView: View {
    let searchText: String
    
    @State private var targetAppName: String = ""
    @State private var selectedPathScope: UninstallLibraryPath.Scope = .all
    @State private var selectedSectionFilter: SectionFilter = .all
    @State private var copiedPathID: String?
    @State private var copiedCommandID: String?
    @State private var showCopiedAlert = false
    
    enum SectionFilter: String, CaseIterable, Identifiable {
        case all = "All Steps"
        case processes = "1. Force Quit"
        case package = "2. Package Dismantle"
        case library = "3. Library Folders"
        case verify = "4. Terminal Verify"
        case cleanup = "5. Terminal Cleanup"
        case advanced = "6. Homebrew / PKG"
        case video = "7. Video Tutorial"
        
        var id: String { rawValue }
    }
    
    // Quick app suggestions for user testing
    private let presetApps = ["Slack", "Zoom", "Docker", "Google Chrome", "Discord", "Spotify"]
    
    // Video tutorial URL from user
    private let tutorialVideoURL = "https://youtu.be/QlyxPuqzZHA?si=PtWpWsDCwkxGJ7FZ"
    
    // Effective app name with fallback
    private var effectiveAppName: String {
        let trimmed = targetAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "<app-name>" : trimmed
    }
    
    private var effectiveCaskName: String {
        let trimmed = targetAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "<cask-name>" }
        return trimmed.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    
    // MARK: - Library Paths Catalog
    private let libraryPaths: [UninstallLibraryPath] = [
        .init(
            id: "user-launchagents",
            path: "~/Library/LaunchAgents",
            scope: .user,
            description: "User startup launch agents that run in the background upon login.",
            targetType: "Background Daemons"
        ),
        .init(
            id: "sys-launchagents",
            path: "/Library/LaunchAgents",
            scope: .system,
            description: "System-wide launch agents loaded for all local user accounts.",
            targetType: "Global Daemons"
        ),
        .init(
            id: "user-launchdaemons",
            path: "~/Library/LaunchDaemons",
            scope: .user,
            description: "User-specific persistent background daemons.",
            targetType: "Background Daemons"
        ),
        .init(
            id: "sys-launchdaemons",
            path: "/Library/LaunchDaemons",
            scope: .system,
            description: "Root-level background services executed by launchd at system boot.",
            targetType: "Root Daemons"
        ),
        .init(
            id: "user-appsupport",
            path: "~/Library/Application Support/",
            scope: .user,
            description: "Primary user application data, offline databases, local profiles, and plugins.",
            targetType: "Application Data"
        ),
        .init(
            id: "sys-appsupport",
            path: "/Library/Application Support/",
            scope: .system,
            description: "Shared global application resources, license engines, and shared helper files.",
            targetType: "Global Data"
        ),
        .init(
            id: "user-caches",
            path: "~/Library/Caches/",
            scope: .user,
            description: "Temporary app caches, downloaded preview assets, and web view cached files.",
            targetType: "Caches & Media"
        ),
        .init(
            id: "user-preferences",
            path: "~/Library/Preferences/",
            scope: .user,
            description: "Property list (.plist) configuration files storing app settings and license keys.",
            targetType: "Settings (.plist)"
        ),
        .init(
            id: "user-logs",
            path: "~/Library/Logs/",
            scope: .user,
            description: "Application diagnostic event logs, crash reports, and update telemetry.",
            targetType: "Logs & Crash Dumps"
        ),
        .init(
            id: "user-containers",
            path: "~/Library/Containers/",
            scope: .sandbox,
            description: "Isolated sandbox environments for App Store & notarized apps (bundle IDs like com.vendor.app).",
            targetType: "Sandbox Containers"
        ),
        .init(
            id: "user-savedstate",
            path: "~/Library/Saved Application State/",
            scope: .user,
            description: "Restorable window positions, saved workspace layouts, and state caches.",
            targetType: "Window States"
        ),
        // Additional high-impact paths
        .init(
            id: "user-groupcontainers",
            path: "~/Library/Group Containers/",
            scope: .sandbox,
            description: "Shared storage shared between main application, menu bar widgets, and helper extensions.",
            targetType: "Group Containers"
        ),
        .init(
            id: "user-appscripts",
            path: "~/Library/Application Scripts/",
            scope: .sandbox,
            description: "Scripts and automation hooks registered for sandboxed application extensions.",
            targetType: "Scripts & Automations"
        ),
        .init(
            id: "user-webkit",
            path: "~/Library/WebKit/",
            scope: .user,
            description: "WebKit offline web storage, IndexedDB, and local site databases for web-based apps.",
            targetType: "WebKit Storage"
        ),
        .init(
            id: "user-httpstorage",
            path: "~/Library/HTTPStorages/",
            scope: .user,
            description: "HTTP network request caches and session cookies saved by app networking stacks.",
            targetType: "HTTP Caches"
        ),
        .init(
            id: "sys-helpertools",
            path: "/Library/PrivilegedHelperTools/",
            scope: .system,
            description: "Privileged helper binaries installed with root access (common for VPNs, Docker, disk tools).",
            targetType: "Root Helpers"
        ),
        .init(
            id: "user-cookies",
            path: "~/Library/Cookies/",
            scope: .user,
            description: "Binary cookies storage (.binarycookies) holding authentication and session tokens.",
            targetType: "Cookies"
        )
    ]
    
    // MARK: - Filtered Paths
    private var filteredLibraryPaths: [UninstallLibraryPath] {
        libraryPaths.filter { item in
            let matchesScope: Bool = {
                switch selectedPathScope {
                case .all: return true
                case .user: return item.scope == .user
                case .system: return item.scope == .system
                case .sandbox: return item.scope == .sandbox
                }
            }()
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else { return matchesScope }
            
            return matchesScope && (
                item.path.lowercased().contains(query) ||
                item.description.lowercased().contains(query) ||
                item.targetType.lowercased().contains(query)
            )
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Intro
            PageIntro(
                eyebrow: "COMPLETE UNINSTALLATION",
                title: "How to completely delete any app",
                description: "A comprehensive step-by-step interactive guide and command reference to dismantle app bundles, background daemons, sandboxed containers, and deep Library remnants without leaving traces."
            )
            
            // Interactive App Name Input Panel
            appNameInputCard
            
            // Top Metrics
            HStack(spacing: 12) {
                MetricCard(
                    title: "Residual Locations",
                    value: "\(libraryPaths.count) Library Paths",
                    detail: "User (~), System (/), and Sandbox",
                    symbol: "folder.badge.gearshape",
                    tint: AppTheme.accent
                )
                
                MetricCard(
                    title: "Removal Methods",
                    value: "Finder & Terminal",
                    detail: "Visual package dismantle + shell commands",
                    symbol: "terminal",
                    tint: AppTheme.accent
                )
                
                MetricCard(
                    title: "Safety Advisory",
                    value: "Caution Advised",
                    detail: "Review search results before recursive delete",
                    symbol: "exclamationmark.triangle",
                    tint: AppTheme.warning
                )
            }
            
            // Section Filter Tabs
            sectionFilterTabs
            
            // Step 1: Force Quit & Terminate Background Daemons
            if shouldShowSection(.processes) {
                step1ProcessesSection
            }
            
            // Step 2: Show Package Contents & Move to Bin
            if shouldShowSection(.package) {
                step2PackageContentsSection
            }
            
            // Step 3: Library Residual Folders
            if shouldShowSection(.library) {
                step3LibraryFoldersSection
            }
            
            // Step 4: Terminal Verification & Search
            if shouldShowSection(.verify) {
                step4TerminalVerificationSection
            }
            
            // Step 5: Terminal Residual Cleanup (With Prominent Safety Warning)
            if shouldShowSection(.cleanup) {
                step5TerminalCleanupSection
            }
            
            // Step 6: Homebrew & Package Receipts (Extra Steps)
            if shouldShowSection(.advanced) {
                step6AdvancedSection
            }
            
            // Step 7: Video Tutorial
            if shouldShowSection(.video) {
                videoTutorialSection
            }
        }
    }
    
    private func shouldShowSection(_ filter: SectionFilter) -> Bool {
        selectedSectionFilter == .all || selectedSectionFilter == filter
    }
    
    // MARK: - App Name Input Card
    private var appNameInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Target App Customizer")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Type the app name you want to uninstall. All paths and terminal commands below will update dynamically with ready-to-copy text.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if !targetAppName.isEmpty {
                    Button("Reset") {
                        targetAppName = ""
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                }
            }
            
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter target app name (e.g. Slack, Zoom, Chrome, Docker)…", text: $targetAppName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium))
                        .autocorrectionDisabled()
                    
                    if !targetAppName.isEmpty {
                        Button {
                            targetAppName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(AppTheme.insetPanel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(targetAppName.isEmpty ? AppTheme.separator : AppTheme.accent.opacity(0.4), lineWidth: 1)
                )
            }
            
            // Quick preset pills
            HStack(spacing: 6) {
                Text("Try an example:")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.tertiary)
                
                ForEach(presetApps, id: \.self) { app in
                    Button {
                        targetAppName = app
                    } label: {
                        Text(app)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(targetAppName == app ? AppTheme.accent.opacity(0.18) : AppTheme.subtleFill, in: Capsule())
                            .overlay(Capsule().strokeBorder(targetAppName == app ? AppTheme.accent.opacity(0.4) : AppTheme.separator, lineWidth: 0.7))
                            .foregroundStyle(targetAppName == app ? AppTheme.accent : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    // MARK: - Section Filter Tabs
    private var sectionFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SectionFilter.allCases) { filter in
                    let isSelected = selectedSectionFilter == filter
                    Button {
                        selectedSectionFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(isSelected ? AppTheme.panel : AppTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.separator, lineWidth: isSelected ? 1.2 : 0.8)
                            )
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Step 1: Force Quit & Terminate Processes
    private var step1ProcessesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "01",
                title: "Force Quit & Terminate Background Processes",
                badge: "Essential First Step",
                badgeTint: AppTheme.accent
            )
            
            Text("Before deleting any files, ensure the application and its background helper processes are completely stopped. Running processes hold file locks, can block deletion, or will immediately recreate deleted cache files.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            
            // GUI Method
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finder / GUI Method")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("• Press `Cmd + Option + Esc` to open the Force Quit Applications dialog, select the app, and click Force Quit.\n• Or open **Activity Monitor** (/Applications/Utilities/Activity Monitor.app), search for \"\(effectiveAppName)\", and click the Stop (X) button.")
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            
            // Terminal Commands
            VStack(spacing: 10) {
                CommandBlockView(
                    title: "Inspect Active Processes",
                    description: "Lists process IDs (PIDs) and executable names currently running that match the target app.",
                    command: "pgrep -l -i \"\(effectiveAppName)\"",
                    riskLabel: "Read only",
                    changesSystem: false
                )
                
                CommandBlockView(
                    title: "Terminate App and Detached Helpers",
                    description: "Sends termination signals to close the main app bundle and any detached background child processes.",
                    command: "killall \"\(effectiveAppName)\" 2>/dev/null || pkill -f \"\(effectiveAppName)\"",
                    riskLabel: "Changes system",
                    changesSystem: true
                )
                
                CommandBlockView(
                    title: "Inspect Registered Background Daemons",
                    description: "Checks if the app installed background agents or daemons registered with macOS launchd.",
                    command: "launchctl list | grep -i \"\(effectiveAppName)\"",
                    riskLabel: "Read only",
                    changesSystem: false
                )
            }
        }
    }
    
    // MARK: - Step 2: Show Package Contents & Move to Bin
    private var step2PackageContentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "02",
                title: "Dismantle App Package Contents & Move to Bin",
                badge: "Finder App Bundle",
                badgeTint: AppTheme.accent
            )
            
            Text("Standard macOS apps are packaged as `.app` directories. Dismantling the internal contents first neutralizes code signing, breaks helper frameworks, and invalidates background hooks before moving the shell to Bin.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            
            // Visual Step Flow Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("FINDER STEP-BY-STEP SEQUENCE")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(AppTheme.accent)
                    
                    Spacer()
                    
                    Button {
                        openApplicationsFolder()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Open Applications in Finder")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppTheme.subtleFill, in: Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.separator, lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Open /Applications directly in Finder")
                }
                
                Divider().overlay(AppTheme.separator)
                
                VStack(alignment: .leading, spacing: 12) {
                    finderInstructionRow(
                        num: "1",
                        title: "Go to Applications",
                        detail: "Open Finder, select Applications from the sidebar, or press Cmd + Shift + A."
                    )
                    
                    finderInstructionRow(
                        num: "2",
                        title: "Select the App",
                        detail: "Click on \"\(effectiveAppName).app\" in your Applications directory."
                    )
                    
                    finderInstructionRow(
                        num: "3",
                        title: "Right-Click & Show Package Contents",
                        detail: "Right click (or Control + click) on the app icon and select \"Show Package Contents\"."
                    )
                    
                    finderInstructionRow(
                        num: "4",
                        title: "Open the Contents Folder",
                        detail: "A new Finder window opens displaying the internal \"Contents\" folder. Double click to enter."
                    )
                    
                    finderInstructionRow(
                        num: "5",
                        title: "Select All Inside Contents and Delete",
                        detail: "Select everything inside Contents (Cmd + A) and press Cmd + Delete to move internal binaries to Bin."
                    )
                    
                    finderInstructionRow(
                        num: "6",
                        title: "Go Back to Applications & Move App to Bin",
                        detail: "Return to the Applications folder, select the remaining \"\(effectiveAppName).app\" container, and press Cmd + Delete (Move to Bin)."
                    )
                    
                    finderInstructionRow(
                        num: "7",
                        title: "Empty Bin",
                        detail: "Right click the Bin icon in your macOS Dock and choose \"Empty Bin\" (or Cmd + Shift + Delete)."
                    )
                }
            }
            .padding(16)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            
            // Terminal Alternative
            CommandBlockView(
                title: "Terminal Alternative: Direct Application Bundle Removal",
                description: "If you prefer Terminal over Finder GUI, this deletes the .app directory directly from /Applications.",
                command: "rm -rf \"/Applications/\(effectiveAppName).app\"",
                riskLabel: "Destructive",
                changesSystem: true
            )
        }
    }
    
    // MARK: - Step 3: Library Folders Section
    private var step3LibraryFoldersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "03",
                title: "Purge Library Folders (Finder Go to Folder)",
                badge: "\(libraryPaths.count) Residual Locations",
                badgeTint: AppTheme.warning
            )
            
            Text("Even after deleting the app bundle, macOS retains application settings, local databases, background launch daemons, and caches in your Library folders. Use Finder's **Go to Folder… (Cmd + Shift + G)** to open each location below, search for folders matching \"\(effectiveAppName)\", and move them to Bin.")
            
            // Go to Folder Quick Helper
            NotePanel(
                symbol: "folder.badge.gearshape",
                title: "Finder Shortcut: Cmd + Shift + G",
                message: "In Finder, click \"Go\" in the top menu bar > select \"Go to Folder…\" (or press Cmd + Shift + G). Copy any path below and paste it directly into the prompt. Click \"Open in Finder\" to jump there immediately.",
                tint: AppTheme.accent
            )
            
            // Scope Filter & Path Count Bar
            HStack(spacing: 8) {
                ForEach(UninstallLibraryPath.Scope.allCases) { scope in
                    let isSelected = selectedPathScope == scope
                    Button {
                        selectedPathScope = scope
                    } label: {
                        Text(scope.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? AppTheme.panel : AppTheme.canvas, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.separator, lineWidth: isSelected ? 1 : 0.7)
                            )
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text("\(filteredLibraryPaths.count) locations")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            // Paths List
            LazyVStack(spacing: 10) {
                ForEach(filteredLibraryPaths) { item in
                    libraryPathCard(item: item)
                }
            }
        }
    }
    
    // MARK: - Step 4: Terminal Verification Section
    private var step4TerminalVerificationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "04",
                title: "Verify Leftover Contents in Terminal",
                badge: "Safe · Read Only",
                badgeTint: AppTheme.success
            )
            
            Text("Run these read-only inspection commands in Terminal to check if any leftover files, hidden plist configurations, or system daemons still linger on your Mac.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            
            VStack(spacing: 10) {
                // User's requested command
                CommandBlockView(
                    title: "Deep Library Case-Insensitive Search (Root & User)",
                    description: "Recursively inspects both /Library and your user ~/Library for any files or directories matching the application name.",
                    command: "sudo find /Library /Users/$(whoami)/Library -iname \"*\(effectiveAppName)*\"",
                    riskLabel: "Read only",
                    changesSystem: false,
                    note: "Enter your macOS administrator password when prompted. This command will NOT delete anything; it only prints matching paths."
                )
                
                // Fast Spotlight alternative
                CommandBlockView(
                    title: "Instant Spotlight Metadata Search (No Sudo Needed)",
                    description: "Queries the macOS Spotlight filesystem metadata index instantly without requiring sudo or long disk scans.",
                    command: "mdfind \"kMDItemDisplayName == '*\(effectiveAppName)*'cd || kMDItemFSName == '*\(effectiveAppName)*'cd\"",
                    riskLabel: "Read only",
                    changesSystem: false
                )
                
                // Package Receipts Check
                CommandBlockView(
                    title: "Inspect Apple PKG Installer Receipts",
                    description: "Checks if the application was installed via an Apple package (.pkg) installer and has registered receipts.",
                    command: "pkgutil --pkgs | grep -i \"\(effectiveAppName)\"",
                    riskLabel: "Read only",
                    changesSystem: false
                )
            }
        }
    }
    
    // MARK: - Step 5: Terminal Cleanup Section (With Prominent Safety Warning)
    private var step5TerminalCleanupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "05",
                title: "Terminal Residual Cleanup",
                badge: "Destructive Action",
                badgeTint: AppTheme.danger
            )
            
            // Prominent Danger / Caution Notice (from user request)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 9) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.danger)
                    
                    Text("CRITICAL CAUTION: POTENTIAL UNINTENDED DELETION")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(AppTheme.danger)
                }
                
                Text("The recursive deletion command (rm -rf) permanently deletes every file and folder matching the wildcard pattern. If the app name matches other software or common system libraries (for example, names like \"Code\", \"Sync\", \"Clean\", \"Helper\", or \"Web\"), you could permanently delete unrelated documents or break system apps.")
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                
                Text("• ALWAYS run the check command in Step 4 first to verify every file that will match.\n• Prefer the interactive \"-ok\" command below to confirm before deleting each item.\n• Ensure you have an active Time Machine or local backup before executing.")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(16)
            .background(AppTheme.danger.opacity(0.08), in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.danger.opacity(0.35), lineWidth: 1))
            
            VStack(spacing: 10) {
                // User's requested command
                CommandBlockView(
                    title: "Batch Recursive Removal (Use with Extreme Care)",
                    description: "Recursively deletes all matching files and directories across /Library and ~/Library in one execution.",
                    command: "sudo find /Library /Users/$(whoami)/Library -iname \"*\(effectiveAppName)*\" -exec rm -rf {} +",
                    riskLabel: "Destructive",
                    changesSystem: true,
                    note: "Warning: Permanently removes all matching items without confirmation."
                )
                
                // Safe interactive alternative
                CommandBlockView(
                    title: "Safer Alternative: Interactive Deletion (Confirm Each File)",
                    description: "Using -ok instead of -exec prompts you (y/n) in Terminal before deleting each individual file or directory, preventing accidental deletion.",
                    command: "sudo find /Library /Users/$(whoami)/Library -iname \"*\(effectiveAppName)*\" -ok rm -rf {} \\;",
                    riskLabel: "Destructive (Interactive)",
                    changesSystem: true,
                    note: "Recommended: Prompts you with a \"?\" before each file. Type 'y' to delete, or 'n' to skip."
                )
            }
        }
    }
    
    // MARK: - Step 6: Homebrew & Package Receipts (Extra Steps)
    private var step6AdvancedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "06",
                title: "Homebrew Cask Purge & Package Receipt Cleanup",
                badge: "Advanced",
                badgeTint: AppTheme.accent
            )
            
            Text("If the application was installed via Homebrew Cask or an Apple PKG installer, use these package manager commands to trigger automated deep-cleaning and forget installer receipts.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            
            VStack(spacing: 10) {
                CommandBlockView(
                    title: "Homebrew Cask Complete Zap Uninstall",
                    description: "Homebrew's built-in --zap flag automatically locates and deletes all associated Library directories, LaunchAgents, caches, and containers declared in the cask formula.",
                    command: "brew uninstall --zap \(effectiveCaskName)",
                    riskLabel: "Destructive",
                    changesSystem: true,
                    note: "This is the safest automated method for apps installed via Homebrew."
                )
                
                CommandBlockView(
                    title: "Forget Apple PKG Installer Receipt",
                    description: "De-registers the application receipt from macOS's internal database so macOS Software Update stops attempting to track or update it.",
                    command: "sudo pkgutil --forget \"\(effectiveCaskName)\"",
                    riskLabel: "Changes system",
                    changesSystem: true
                )
            }
        }
    }
    
    // MARK: - Video Tutorial Section
    private var videoTutorialSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeaderView(
                stepNumber: "07",
                title: "Video Tutorial Reference",
                badge: "YouTube Walkthrough",
                badgeTint: Color.red
            )
            
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.red)
                    .frame(width: 56, height: 56)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("How to Completely Delete an App on Mac")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Watch the visual step-by-step video demonstration of dismantling package contents and deleting user library leftovers.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(tutorialVideoURL)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        if let url = URL(string: tutorialVideoURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.video.fill")
                                .font(.system(size: 11))
                            Text("Watch on YouTube")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        ClipboardService.copy(tutorialVideoURL)
                        showCopiedAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopiedAlert = false
                        }
                    } label: {
                        Image(systemName: showCopiedAlert ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                            .frame(width: 30, height: 30)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.8))
                            .foregroundStyle(showCopiedAlert ? AppTheme.success : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy YouTube URL")
                }
            }
            .padding(16)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
    }
    
    // MARK: - Row Helpers
    
    private func finderInstructionRow(num: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22, height: 22)
                .background(AppTheme.accent.opacity(0.12), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1.5)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func libraryPathCard(item: UninstallLibraryPath) -> some View {
        let isCopied = copiedPathID == item.id
        let resolvedPath: String = {
            if targetAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return item.path
            } else {
                let suffix = item.path.hasSuffix("/") ? "" : "/"
                return "\(item.path)\(suffix)\(effectiveAppName)"
            }
        }()
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.path)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                        
                        Text(item.scope.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(scopeTint(item.scope).opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .foregroundStyle(scopeTint(item.scope))
                        
                        Text(item.targetType)
                            .font(.system(size: 8, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(item.description)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                HStack(spacing: 6) {
                    // Copy Path Button
                    Button {
                        if ClipboardService.copy(item.path) {
                            copiedPathID = item.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedPathID == item.id { copiedPathID = nil }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                            Text(isCopied ? "Copied" : "Copy Path")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4.5)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(isCopied ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.7))
                        .foregroundStyle(isCopied ? AppTheme.success : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy folder path to clipboard")
                    
                    // Open in Finder Button
                    Button {
                        openInFinder(path: item.path)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 10, weight: .medium))
                            Text("Open in Finder")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4.5)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.7))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reveal this folder in Finder")
                }
            }
            
            // If target app is specified, show target subpath hint
            if !targetAppName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text("Target subfolder to look for:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text(resolvedPath)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                        .textSelection(.enabled)
                }
                .padding(.top, 2)
            }
        }
        .padding(13)
        .background(AppTheme.panel, in: AppTheme.compactShape)
        .overlay(AppTheme.compactShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    private func scopeTint(_ scope: UninstallLibraryPath.Scope) -> Color {
        switch scope {
        case .all: return .secondary
        case .user: return AppTheme.accent
        case .system: return AppTheme.warning
        case .sandbox: return Color.purple
        }
    }
    
    private func openApplicationsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
    }
    
    private func openInFinder(path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        if FileManager.default.fileExists(atPath: expanded) {
            NSWorkspace.shared.open(url)
        } else {
            let parent = url.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: parent.path) {
                NSWorkspace.shared.open(parent)
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()))
            }
        }
    }
}

// MARK: - Subviews

private struct StepHeaderView: View {
    let stepNumber: String
    let title: String
    var badge: String? = nil
    var badgeTint: Color = AppTheme.accent
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(stepNumber)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(badgeTint)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(badgeTint.opacity(0.12), in: Capsule())
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

private struct CommandBlockView: View {
    let title: String
    let description: String
    let command: String
    let riskLabel: String
    let changesSystem: Bool
    var note: String? = nil
    
    @State private var isCopied = false
    
    private var riskTint: Color {
        if !changesSystem { return .secondary }
        if riskLabel.contains("Destructive") { return AppTheme.danger }
        return AppTheme.warning
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .lineSpacing(1.8)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 8)
                
                StatusPill(
                    title: riskLabel,
                    symbol: changesSystem ? "exclamationmark.circle" : "checkmark.circle",
                    tint: riskTint
                )
            }
            
            HStack(spacing: 10) {
                Text(command)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 11)
                    .background(AppTheme.insetPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Button {
                    if ClipboardService.copy(command) {
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCopied = false
                        }
                    }
                } label: {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10.5, weight: .semibold))
                        .frame(minWidth: 62)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy command to clipboard")
            }
            
            if let note {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9.5))
                        .foregroundStyle(riskTint)
                    Text(note)
                        .font(.system(size: 10))
                        .foregroundStyle(riskTint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}
