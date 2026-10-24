import SwiftUI

struct CommandReference: Identifiable {
    let id: String
    let title: String
    let description: String
    let command: String
    let riskLabel: String
    let changesSystem: Bool
    var isMole: Bool = false
    var category: String? = nil
}

enum CommandFilter: String, CaseIterable, Identifiable {
    case all = "All Commands"
    case homebrew = "Homebrew"
    case mole = "Mole"
    
    var id: String { rawValue }
}

enum CommandCatalog {
    static let items: [CommandReference] = [
        // MARK: - Homebrew: Inspection & Diagnostics
        .init(
            id: "brew-version",
            title: "Check Homebrew Version",
            description: "Display the installed version of Homebrew Core, Homebrew Cask, and the exact Git commit SHAs of your local formula taps.",
            command: "brew --version",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inspection"
        ),
        .init(
            id: "brew-doctor",
            title: "Run System Diagnostics",
            description: "Thoroughly inspect your macOS environment for broken symlinks, unlinked kegs, conflicting compilers, or obsolete Xcode Command Line Tools.",
            command: "brew doctor",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Diagnostics"
        ),
        .init(
            id: "brew-config",
            title: "View Environment Configuration",
            description: "Output comprehensive diagnostic information about your Homebrew install, macOS build, CPU architecture, Xcode paths, and compiler flags.",
            command: "brew config",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Diagnostics"
        ),
        
        // MARK: - Homebrew: Package Discovery & Inspection
        .init(
            id: "brew-search",
            title: "Search Available Packages",
            description: "Search Homebrew's centralized package index and enabled third-party taps for formulae (CLI tools) and casks (macOS GUI apps) by keyword or regex.",
            command: "brew search <name>",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Discovery"
        ),
        .init(
            id: "brew-info",
            title: "Inspect Package Metadata & Caveats",
            description: "Show detailed package details including homepage URL, current release version, download size, required build/runtime dependencies, caveats, and options.",
            command: "brew info <formula-or-cask>",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inspection"
        ),
        .init(
            id: "brew-deps-tree",
            title: "Display Dependency Tree",
            description: "Visualize the entire direct and transitive dependency hierarchy for a given package as an ASCII tree diagram.",
            command: "brew deps --tree <formula>",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inspection"
        ),
        .init(
            id: "brew-uses",
            title: "Check Reverse Dependencies",
            description: "List all currently installed packages that depend on a specific formula. Helpful to run before uninstalling to prevent breaking other software.",
            command: "brew uses --installed <formula>",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inspection"
        ),
        
        // MARK: - Homebrew: Installed Inventory
        .init(
            id: "brew-list-formula",
            title: "List Installed Formulae",
            description: "List all command-line programs, background tools, and system libraries currently installed into your local Homebrew cellar.",
            command: "brew list --formula",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inventory"
        ),
        .init(
            id: "brew-list-cask",
            title: "List Installed Casks",
            description: "List all graphical macOS desktop applications installed via Homebrew Casks (e.g. Visual Studio Code, Docker, Slack).",
            command: "brew list --cask",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Inventory"
        ),
        .init(
            id: "brew-outdated",
            title: "Check Outdated Packages",
            description: "Scan your installed packages and report all formulae and casks that have newer versions published upstream in structured JSON format.",
            command: "brew outdated --json=v2",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Updates"
        ),
        
        // MARK: - Homebrew: Updates & Maintenance
        .init(
            id: "brew-update",
            title: "Refresh Package Catalog",
            description: "Fetch the latest formula definitions, casks, and repository metadata from GitHub. Refreshes package indexes without modifying any installed software.",
            command: "brew update",
            riskLabel: "Changes metadata",
            changesSystem: true,
            isMole: false,
            category: "Updates"
        ),
        .init(
            id: "brew-upgrade",
            title: "Upgrade All Outdated Packages",
            description: "Download and install the latest versions of all outdated formulae and casks, resolving dependency changes and updating symlinks.",
            command: "brew upgrade",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Updates"
        ),
        .init(
            id: "brew-upgrade-single",
            title: "Upgrade Specific Package",
            description: "Upgrade only the specified formula or cask to its latest available release while leaving all other installed software untouched.",
            command: "brew upgrade <formula-or-cask>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Updates"
        ),
        .init(
            id: "brew-pin",
            title: "Pin Package Version",
            description: "Lock a formula at its current installed version, preventing `brew upgrade` from automatically upgrading or replacing it.",
            command: "brew pin <formula>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Maintenance"
        ),
        .init(
            id: "brew-unpin",
            title: "Unpin Package Version",
            description: "Release the version lock on a previously pinned formula, allowing it to be upgraded normally during future update cycles.",
            command: "brew unpin <formula>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Maintenance"
        ),
        
        // MARK: - Homebrew: Cleanup & Uninstall
        .init(
            id: "brew-uninstall",
            title: "Uninstall Formula",
            description: "Safely remove an installed formula package from the cellar and unlink its binaries from /opt/homebrew/bin or /usr/local/bin.",
            command: "brew uninstall <formula>",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: false,
            category: "Uninstall"
        ),
        .init(
            id: "brew-uninstall-cask-zap",
            title: "Deep Uninstall Cask & Scrub Data",
            description: "Uninstall a GUI application and use --zap to delete its associated preferences, caches, application support files, and saved state from ~/Library.",
            command: "brew uninstall --cask --zap <cask>",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: false,
            category: "Uninstall"
        ),
        .init(
            id: "brew-autoremove",
            title: "Autoremove Orphaned Dependencies",
            description: "Detect and remove installed packages that were originally installed as dependencies for software you have since uninstalled.",
            command: "brew autoremove",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: false,
            category: "Cleanup"
        ),
        .init(
            id: "brew-cleanup",
            title: "Clean Outdated Versions & Lockfiles",
            description: "Remove old, superseded versions of installed packages, stale lockfiles, and outdated download cache entries to free disk space.",
            command: "brew cleanup",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: false,
            category: "Cleanup"
        ),
        .init(
            id: "brew-cleanup-prune",
            title: "Purge All Download Caches",
            description: "Completely purge all bottle downloads, installer images, and git cache archives in ~/Library/Caches/Homebrew to reclaim maximum disk space.",
            command: "brew cleanup --prune=all",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: false,
            category: "Cleanup"
        ),
        
        // MARK: - Homebrew: Services & Repositories
        .init(
            id: "brew-services-list",
            title: "List Background Services",
            description: "Display the real-time operational status (started, stopped, error) and launch agent plist paths for all background daemons.",
            command: "brew services list",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: false,
            category: "Services"
        ),
        .init(
            id: "brew-services-start",
            title: "Start Background Service",
            description: "Start a background service daemon (e.g. PostgreSQL, Redis, Nginx) and configure macOS launchd to automatically run it at system startup.",
            command: "brew services start <service>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Services"
        ),
        .init(
            id: "brew-services-stop",
            title: "Stop Background Service",
            description: "Gracefully stop a running background service daemon and deregister its launch agent from macOS launchd.",
            command: "brew services stop <service>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Services"
        ),
        .init(
            id: "brew-services-restart",
            title: "Restart Background Service",
            description: "Restart a running service daemon to apply updated configuration files or reload after updating package binaries.",
            command: "brew services restart <service>",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: false,
            category: "Services"
        ),
        .init(
            id: "brew-tap",
            title: "Tap Third-Party Repository",
            description: "Add an external third-party Git repository to Homebrew, enabling you to install specialized tools, custom formulas, and proprietary casks.",
            command: "brew tap <user/repo>",
            riskLabel: "Changes metadata",
            changesSystem: true,
            isMole: false,
            category: "Repositories"
        ),
        
        // MARK: - Mole: System Debris Clean
        .init(
            id: "mole-clean",
            title: "Mole Deep System Clean",
            description: "Scan and purge deep system debris across user caches, application logs, diagnostic crash reports, simulator files, and uninstalled app residues.",
            command: "mo clean",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: true,
            category: "Clean"
        ),
        .init(
            id: "mole-clean-preview",
            title: "Mole Clean Dry-Run Preview",
            description: "Safely scan and calculate reclaimable disk space across all debris categories without modifying or deleting any files on disk.",
            command: "mo clean --dry-run",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Clean"
        ),
        .init(
            id: "mole-clean-section",
            title: "Mole Clean Targeted Section",
            description: "Clean only a specific section of debris (e.g. 'User Caches', 'System Logs', 'Browser', or 'Developer') while leaving other areas untouched.",
            command: "mo clean --section <name>",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: true,
            category: "Clean"
        ),
        .init(
            id: "mole-clean-whitelist",
            title: "Mole Whitelist Manager",
            description: "Configure directories, caches, or applications that Mole should permanently protect and exclude from all cleanup routines.",
            command: "mo clean --whitelist",
            riskLabel: "Settings",
            changesSystem: true,
            isMole: true,
            category: "Clean"
        ),
        
        // MARK: - Mole: Developer Project Purge
        .init(
            id: "mole-purge",
            title: "Mole Developer Build Purge",
            description: "Recursively scan your project directories and purge massive build artifacts including node_modules, Xcode DerivedData, SPM, Gradle, and Rust target folders.",
            command: "mo purge --yes",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: true,
            category: "Purge"
        ),
        .init(
            id: "mole-purge-preview",
            title: "Mole Developer Purge Preview",
            description: "Preview reclaimable gigabytes across dormant repositories and project directories before any deletion takes place.",
            command: "mo purge --dry-run",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Purge"
        ),
        .init(
            id: "mole-purge-paths",
            title: "Mole Project Paths Configuration",
            description: "Inspect and customize the root scan paths (such as ~/Projects, ~/Work, ~/Code) where Mole automatically looks for developer repositories.",
            command: "mo purge --paths",
            riskLabel: "Settings",
            changesSystem: true,
            isMole: true,
            category: "Purge"
        ),
        
        // MARK: - Mole: Deep App Uninstaller
        .init(
            id: "mole-uninstall-app",
            title: "Mole Deep App Uninstaller",
            description: "Completely uninstall a macOS application, moving the app bundle to Trash and thoroughly scrubbing all leftover Application Support, Preferences, and Caches.",
            command: "mo uninstall <app>",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: true,
            category: "Uninstall"
        ),
        .init(
            id: "mole-uninstall-list",
            title: "Mole List Removable Apps",
            description: "Scan and produce a structured JSON catalog of all installed macOS applications with bundle IDs, install sources, and calculated disk footprints.",
            command: "mo uninstall --list",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Uninstall"
        ),
        
        // MARK: - Mole: Installer Media Sweep
        .init(
            id: "mole-installer",
            title: "Mole Installer Media Sweep",
            description: "Scan Downloads, Desktop, and cache directories for orphaned disk images (.dmg), package files (.pkg), and installer archives (.zip) to delete.",
            command: "mo installer",
            riskLabel: "Destructive",
            changesSystem: true,
            isMole: true,
            category: "Installers"
        ),
        .init(
            id: "mole-installer-preview",
            title: "Mole Installer Sweep Preview",
            description: "Preview all leftover application installer files and total reclaimable disk space without deleting any files.",
            command: "mo installer --dry-run",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Installers"
        ),
        
        // MARK: - Mole: Disk Storage Analyzer
        .init(
            id: "mole-analyze",
            title: "Mole Interactive Disk Analyzer",
            description: "Launch an interactive terminal disk exploration tool to visually drill down into directories and pinpoint the largest space-consuming folders.",
            command: "mo analyze",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Analyzer"
        ),
        .init(
            id: "mole-analyze-library",
            title: "Mole User Library Deep Analysis",
            description: "Conduct an in-depth scan of ~/Library to uncover hidden disk hogs inside Application Support, Containers, and user Caches.",
            command: "mo analyze ~/Library",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Analyzer"
        ),
        
        // MARK: - Mole: System Optimization
        .init(
            id: "mole-optimize",
            title: "Mole System Optimization & Flush",
            description: "Run essential macOS maintenance: flush DNS cache, restart mDNSResponder, purge inactive memory, and rebuild LaunchServices application associations.",
            command: "mo optimize",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: true,
            category: "Optimize"
        ),
        .init(
            id: "mole-optimize-preview",
            title: "Mole Optimization Preview",
            description: "Safely preview the system maintenance routines and service refreshes that Mole would perform without executing them.",
            command: "mo optimize --dry-run",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Optimize"
        ),
        
        // MARK: - Mole: System Health & Audit
        .init(
            id: "mole-status",
            title: "Mole Live System Health Monitor",
            description: "Interactive real-time terminal dashboard monitoring CPU load, GPU utilization, memory pressure, battery health, and disk activity.",
            command: "mo status",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Status"
        ),
        .init(
            id: "mole-status-json",
            title: "Mole Export System Vitals (JSON)",
            description: "Query current CPU, memory, battery, and disk telemetry metrics and export them in machine-readable JSON format for scripts or monitoring.",
            command: "mo status --json",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Status"
        ),
        .init(
            id: "mole-history",
            title: "Mole Operation Audit History",
            description: "Review a forensic audit log of all previous cleanups, optimizations, and application removals, complete with timestamps and exact bytes freed.",
            command: "mo history",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "History"
        ),
        .init(
            id: "mole-touchid-status",
            title: "Mole Touch ID Sudo Status",
            description: "Check if Touch ID authentication for sudo privileges in Terminal is currently active and configured in /etc/pam.d/sudo.",
            command: "mo touchid status",
            riskLabel: "Read only",
            changesSystem: false,
            isMole: true,
            category: "Tools"
        ),
        .init(
            id: "mole-touchid-enable",
            title: "Mole Enable Touch ID for Sudo",
            description: "Configure macOS PAM system to enable authenticating sudo terminal commands using your Touch ID fingerprint instead of typing your password.",
            command: "mo touchid enable",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: true,
            category: "Tools"
        ),
        .init(
            id: "mole-update",
            title: "Mole Upgrade to Latest Release",
            description: "Check for and download the latest stable release of the Mole CLI tool from official distribution repositories.",
            command: "mo update",
            riskLabel: "Changes system",
            changesSystem: true,
            isMole: true,
            category: "Tools"
        )
    ]
}

struct CommandsView: View {
    let searchText: String
    @State private var selectedFilter: CommandFilter = .all
    @State private var copiedCommandID: String?
    
    private var filteredCommands: [CommandReference] {
        let baseItems: [CommandReference]
        switch selectedFilter {
        case .all:
            baseItems = CommandCatalog.items
        case .homebrew:
            baseItems = CommandCatalog.items.filter { !$0.isMole }
        case .mole:
            baseItems = CommandCatalog.items.filter { $0.isMole }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return baseItems }
        return baseItems.filter { item in
            item.title.localizedCaseInsensitiveContains(query)
            || item.description.localizedCaseInsensitiveContains(query)
            || item.command.localizedCaseInsensitiveContains(query)
            || item.riskLabel.localizedCaseInsensitiveContains(query)
            || (item.category?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    private func count(for filter: CommandFilter) -> Int {
        switch filter {
        case .all:
            return CommandCatalog.items.count
        case .homebrew:
            return CommandCatalog.items.filter { !$0.isMole }.count
        case .mole:
            return CommandCatalog.items.filter { $0.isMole }.count
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "REFERENCE",
                title: "The right command, clearly explained",
                description: "A comprehensive reference catalogue for Homebrew and Mole commands with detailed descriptions. Copying only copies text; Purge never executes commands from this screen."
            )
            
            NotePanel(
                symbol: "doc.on.clipboard",
                title: "Preview before you act",
                message: "Commands that change system state are labeled. Replace placeholders such as `<formula>` or `<cask>` with a package name and review the command before running it yourself.",
                tint: AppTheme.accent
            )
            
            // Ecosystem Filter Tabs
            HStack(spacing: 8) {
                ForEach(CommandFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count = count(for: filter)
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                            Text("\(count)")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(isSelected ? AppTheme.accent.opacity(0.18) : AppTheme.subtleFill, in: Capsule())
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(isSelected ? AppTheme.panel : AppTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.separator, lineWidth: isSelected ? 1.2 : 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            
            HStack {
                SectionCaption(title: "Command library", trailing: "\(filteredCommands.count) commands")
                Spacer()
                Text("COPY ONLY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }
            
            if filteredCommands.isEmpty {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "No matching commands",
                    message: "Try a different package, command name, or risk category."
                )
                .background(AppTheme.panel, in: AppTheme.cardShape)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredCommands) { item in
                        CommandRow(
                            item: item,
                            isCopied: copiedCommandID == item.id,
                            onCopy: {
                                if ClipboardService.copy(item.command) {
                                    copiedCommandID = item.id
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct CommandRow: View {
    let item: CommandReference
    let isCopied: Bool
    let onCopy: () -> Void
    
    private var tint: Color {
        if !item.changesSystem { return .secondary }
        if item.riskLabel == "Destructive" { return AppTheme.danger }
        return AppTheme.warning
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if item.isMole {
                            Text("MOLE")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.purple.opacity(0.18), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .foregroundStyle(Color.purple)
                        } else {
                            Text("BREW")
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(AppTheme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        if let cat = item.category {
                            Text(cat)
                                .font(.system(size: 8, weight: .medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(item.description)
                        .font(.system(size: 11))
                        .lineSpacing(2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 10)
                
                StatusPill(
                    title: item.riskLabel,
                    symbol: item.changesSystem ? "exclamationmark.circle" : "checkmark.circle",
                    tint: tint
                )
            }
            
            HStack(spacing: 10) {
                Text(item.command)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(AppTheme.insetPanel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                Button(action: onCopy) {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(minWidth: 63)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy the displayed command; do not execute it")
            }
        }
        .padding(15)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}

typealias CommandsPage = CommandsView
