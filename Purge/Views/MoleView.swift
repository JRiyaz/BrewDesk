import AppKit
import SwiftUI

struct MoleView: View {
    let searchText: String
    @ObservedObject var moleStore: MoleStore
    
    @State private var selectedTab: MoleModuleTab = .dashboard
    @State private var selectedCleanSections: Set<String> = []
    @State private var showCleanConfirmation = false
    
    // Project purge & installer sweep confirmation state
    @State private var showPurgeConfirmation = false
    @State private var showInstallerConfirmation = false
    
    // App uninstaller state
    @State private var appSearchText = ""
    @State private var appToUninstall: MoleInstalledApp?
    @State private var showUninstallConfirmation = false
    
    // Commands & actions state
    @State private var selectedCatalogCategory: MoleModuleCategory = .clean
    @State private var hasCopiedInstallCommand = false
    @State private var hasCopiedOutput = false
    
    private var filteredCatalogActions: [MoleActionItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            return MoleCatalog.actions.filter { action in
                action.title.localizedCaseInsensitiveContains(query)
                || action.description.localizedCaseInsensitiveContains(query)
                || action.command.localizedCaseInsensitiveContains(query)
                || action.category.rawValue.localizedCaseInsensitiveContains(query)
            }
        }
        if selectedCatalogCategory == .commands {
            return MoleCatalog.actions
        }
        return MoleCatalog.actions.filter { $0.category == selectedCatalogCategory }
    }
    
    private var filteredApps: [MoleInstalledApp] {
        let query = appSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return moleStore.installedApps
        }
        return moleStore.installedApps.filter { app in
            app.displayName.localizedCaseInsensitiveContains(query)
            || app.safeBundleId.localizedCaseInsensitiveContains(query)
            || app.safeUninstallName.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Page Intro
            PageIntro(
                eyebrow: "DEEP CLEAN & OPTIMIZATION",
                title: "Mole Engine",
                description: "Deep clean system debris, safely uninstall apps with leftover removal, analyze disk storage, and optimize Mac performance."
            )
            
            // Top Navigation Bar (matching mole-gui tabs)
            moduleNavigationBar
            
            if !moleStore.isInstalled && !moleStore.isChecking {
                notInstalledBanner
            } else {
                // Active Subview
                switch selectedTab {
                case .dashboard:
                    dashboardContent
                case .clean:
                    cleanModuleView
                case .uninstall:
                    uninstallModuleView
                case .analyze:
                    analyzeModuleView
                case .optimize:
                    optimizeModuleView
                case .purge:
                    purgeModuleView
                case .installers:
                    installersModuleView
                case .history:
                    historyModuleView
                case .commands:
                    commandsModuleView
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                if selectedCleanSections.isEmpty && !moleStore.cleanSections.isEmpty {
                    selectedCleanSections = Set(moleStore.cleanSections.map { $0.section })
                }
            }
        }
        .onChange(of: moleStore.cleanSections) { _, newSections in
            DispatchQueue.main.async {
                if selectedCleanSections.isEmpty && !newSections.isEmpty {
                    selectedCleanSections = Set(newSections.map { $0.section })
                }
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    private var moduleNavigationBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MoleModuleTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? tab.accentColor.opacity(0.16) : AppTheme.subtleFill,
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    isSelected ? tab.accentColor.opacity(0.45) : AppTheme.separator,
                                    lineWidth: 0.9
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? tab.accentColor : .secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Dashboard View
    
    private var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Full Disk Access Banner (if permissions missing)
            if !moleStore.hasFullDiskAccess {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full Disk Access Recommended")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("Grant Purge Full Disk Access in macOS Settings so Mole can inspect and clean system-wide caches and leftovers without permission errors.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Privacy Settings") {
                        moleStore.openFullDiskAccessSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(12)
                .background(AppTheme.warning.opacity(0.1), in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.warning.opacity(0.3), lineWidth: 0.8))
            }
            
            // Hero Section (mole-gui style with large Health Score Ring)
            heroCard
            
            // Care Areas - 4 System Stat Rings (MacSai ProgressGauges)
            VStack(alignment: .leading, spacing: 12) {
                SectionCaption(title: "Care Areas · System Vitals", trailing: "Snapshot Telemetry")
                
                let vitals = moleStore.vitals
                let cpuPct = vitals?.cpuPercent ?? 3.9
                let memPct = vitals?.memoryPercent ?? 58.0
                let diskPct = vitals?.diskUsedPercent ?? 29.5
                let debrisBytes = moleStore.totalDebrisBytes
                
                HStack(spacing: 12) {
                    statRingCard(
                        title: "CPU Load",
                        value: cpuPct,
                        displayText: "\(Int(cpuPct.rounded()))%",
                        symbol: "cpu",
                        tint: MoleSystemVitals.gaugeTint(value: cpuPct)
                    )
                    statRingCard(
                        title: "Memory",
                        value: memPct,
                        displayText: "\(Int(memPct.rounded()))%",
                        symbol: "memorychip",
                        tint: MoleSystemVitals.gaugeTint(value: memPct)
                    )
                    statRingCard(
                        title: "Disk Space",
                        value: diskPct,
                        displayText: "\(Int(diskPct.rounded()))%",
                        symbol: "internaldrive",
                        tint: MoleSystemVitals.gaugeTint(value: diskPct)
                    )
                    statRingCard(
                        title: "Clean Candidates",
                        value: moleStore.hasScannedClean
                        ? (debrisBytes > 0 ? min(max(Double(debrisBytes) / (12.0 * 1024 * 1024 * 1024) * 100.0, 20.0), 100.0) : 0.0)
                        : 0.0,
                        displayText: moleStore.hasScannedClean ? moleStore.formattedTotalDebris : "Ready",
                        symbol: "sparkles",
                        tint: (moleStore.hasScannedClean && debrisBytes > 0) ? Color.orange : Color(red: 140/255, green: 98/255, blue: 228/255)
                    )
                }
            }
            
            // Module Jump Cards Grid
            VStack(alignment: .leading, spacing: 12) {
                SectionCaption(title: "Care Modules", trailing: "6 Action Areas")
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    moduleJumpCard(
                        tab: .clean,
                        value: moleStore.hasScannedClean ? moleStore.formattedTotalDebris : "Ready",
                        detail: moleStore.hasScannedClean
                        ? (moleStore.totalDebrisBytes > 0 ? "\(moleStore.cleanSections.count) categories of debris ready to clean" : "Spotless! No debris found")
                        : "Click to scan system caches & debris"
                    )
                    moduleJumpCard(
                        tab: .uninstall,
                        value: moleStore.installedApps.isEmpty ? "Manage Apps" : "\(moleStore.installedApps.count) Apps",
                        detail: "Clean uninstaller with residual files"
                    )
                    moduleJumpCard(
                        tab: .analyze,
                        value: "\(Int((moleStore.vitals?.diskUsedPercent ?? 30).rounded()))% Used",
                        detail: "Visual disk breakdown and space explorer"
                    )
                    moduleJumpCard(
                        tab: .optimize,
                        value: "\(moleStore.vitals?.healthScore ?? 100)% Health",
                        detail: "Flush DNS, refresh caches, service repair"
                    )
                    moduleJumpCard(
                        tab: .purge,
                        value: "Project Purge",
                        detail: "Remove heavy node_modules & build artifacts"
                    )
                    moduleJumpCard(
                        tab: .installers,
                        value: "Installers",
                        detail: "Remove orphaned .dmg, .pkg, .iso files"
                    )
                }
            }
        }
    }
    
    // MARK: - Hero Card
    
    private var heroCard: some View {
        let theme = MoleModuleTab.dashboard
        let vitals = moleStore.vitals
        let freeDisk = vitals?.formattedFreeDisk ?? "650 GB"
        let totalDisk = vitals?.formattedTotalDisk ?? "926 GB"
        let pctUsed = Int((vitals?.diskUsedPercent ?? 30).rounded())
        let healthScore = vitals?.healthScore ?? 100
        let healthMsg = vitals?.healthScoreMsg ?? "Excellent"
        
        return HStack(alignment: .center, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                // Eyebrow tag
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.accentColor)
                    Text("LOCAL & SECURE ENGINE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(theme.accentColor)
                }
                
                // Big Headline
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep your Mac spotless,")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("fast, and healthy")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentColor, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Subtitle
                Text("Clean caches, purge build artifacts, and uninstall applications with complete leftover tracking — entirely local and transparent.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // CTA Action Buttons & Copy Icons
                HStack(spacing: 8) {
                    Button {
                        selectedTab = .clean
                        Task { await moleStore.scanCleanDryRun() }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                            Text((moleStore.hasScannedClean && moleStore.totalDebrisBytes > 0) ? "Clean \(moleStore.formattedTotalDebris) Debris" : "Scan Debris")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: theme.ringGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    CopyCommandButton(command: "mo clean --dry-run", size: 32)
                    CopyCommandButton(command: "mo clean", size: 32)
                    
                    Button {
                        Task {
                            await moleStore.refreshStatus()
                        }
                    } label: {
                        Label(moleStore.isChecking ? "Refreshing…" : "Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(moleStore.isChecking)
                }
                .padding(.top, 4)
                
                // Trust badges
                HStack(spacing: 16) {
                    trustBadge(icon: "checkmark.shield.fill", text: "Safe & Local")
                    trustBadge(icon: "eye.slash.fill", text: "100% Private")
                    trustBadge(icon: "checklist", text: "Reviewable First")
                }
                .padding(.top, 2)
                
                // Storage & Trash Pill
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(freeDisk) free")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                            Text("of \(totalDisk) total")
                                .font(.system(size: 9.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                        .frame(height: 18)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(vitals?.formattedTrash ?? "0 B")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                            Text("in macOS Trash")
                                .font(.system(size: 9.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(pctUsed)% used")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.accentColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(theme.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Health Score Ring Gauge
            VStack(spacing: 8) {
                GradientRingView(
                    value: Double(healthScore),
                    size: 165,
                    strokeWidth: 12,
                    gradient: healthScore >= 95
                    ? [Color(red: 46/255, green: 199/255, blue: 119/255), Color(red: 10/255, green: 132/255, blue: 255/255)]
                    : (healthScore >= 80
                       ? [Color.orange, Color(red: 255/255, green: 180/255, blue: 0/255)]
                       : [Color.red, Color.orange])
                ) {
                    VStack(spacing: 2) {
                        Text("\(healthScore)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(healthMsg)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("System Health Score")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 8)
        }
        .padding(24)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(
            AppTheme.cardShape
                .strokeBorder(AppTheme.separator, lineWidth: 0.8)
        )
    }
    
    private func trustBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.accent)
            Text(text)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Stat Ring Card
    
    private func statRingCard(
        title: String,
        value: Double,
        displayText: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 10) {
            GradientRingView(
                value: value,
                size: 85,
                strokeWidth: 7,
                gradient: [tint, tint.opacity(0.6)]
            ) {
                Text(displayText)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    // MARK: - Module Jump Card
    
    private func moduleJumpCard(
        tab: MoleModuleTab,
        value: String,
        detail: String
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Top accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [tab.accentColor, tab.accentColor.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 44, height: 3)
                
                HStack(spacing: 8) {
                    Image(systemName: tab.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(tab.accentColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(detail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - System Clean Module View
    
    private var cleanModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clean Toolbar with Copy Command Icons
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Clean")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Safely remove caches, temporary files, and leftover debris.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Scan Debris & Copy Command
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.scanCleanDryRun() }
                    } label: {
                        HStack(spacing: 6) {
                            if moleStore.isScanningClean {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(moleStore.isScanningClean ? "Scanning…" : "Scan Debris")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: MoleModuleTab.clean.ringGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(moleStore.isScanningClean || moleStore.isCleaning)
                    
                    CopyCommandButton(command: "mo clean --dry-run")
                    CopyCommandButton(command: "mo clean")
                }
            }
            
            // Success alert if clean finished
            if let msg = moleStore.cleanSuccessMessage {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Button {
                        moleStore.dismissSuccessMessage()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(AppTheme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.success.opacity(0.3), lineWidth: 0.8)
                )
            }
            
            if moleStore.isScanningClean {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.regular)
                    Text("Scanning system caches, logs, and uninstalled app debris…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(48)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else if moleStore.cleanSections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: moleStore.hasScannedClean ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(MoleModuleTab.clean.accentColor)
                    Text(moleStore.hasScannedClean ? "Your Mac is Spotless!" : "Ready to Scan System Debris")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(moleStore.hasScannedClean ? "No unnecessary cache or residual files found." : "Click 'Scan Debris' to run the scanner and inspect recoverable storage space.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    if !moleStore.hasScannedClean {
                        Button {
                            Task { await moleStore.scanCleanDryRun() }
                        } label: {
                            HStack(spacing: 6) {
                                if moleStore.isScanningClean {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(moleStore.isScanningClean ? "Scanning…" : "Scan Debris Now")
                            }
                            .font(.system(size: 12, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                        .disabled(moleStore.isScanningClean)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else {
                // Sections summary bar
                HStack {
                    let totalKb = selectedCleanSectionsTotalKb
                    Text("\(selectedCleanSections.count) of \(moleStore.cleanSections.count) sections selected · \(ByteCountFormatter.string(fromByteCount: totalKb * 1024, countStyle: .file))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button {
                        if selectedCleanSections.count == moleStore.cleanSections.count {
                            selectedCleanSections.removeAll()
                        } else {
                            selectedCleanSections = Set(moleStore.cleanSections.map { $0.section })
                        }
                    } label: {
                        Text(selectedCleanSections.count == moleStore.cleanSections.count ? "Deselect All" : "Select All")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(MoleModuleTab.clean.accentColor)
                }
                
                // Section list cards
                LazyVStack(spacing: 10) {
                    ForEach(moleStore.cleanSections) { section in
                        cleanSectionRow(section)
                    }
                }
                
                // Sticky bottom clean action bar with Copy Command
                if !selectedCleanSections.isEmpty {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Selected for cleanup")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: selectedCleanSectionsTotalKb * 1024, countStyle: .file))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        CopyCommandButton(command: "mo clean", title: "Copy 'mo clean'")
                        
                        Button {
                            showCleanConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                if moleStore.isCleaning {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(moleStore.isCleaning ? "Cleaning…" : "Clean Now")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color(red: 220/255, green: 50/255, blue: 50/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(moleStore.isCleaning || selectedCleanSections.isEmpty)
                    }
                    .padding(14)
                    .background(AppTheme.panel, in: AppTheme.cardShape)
                    .overlay(AppTheme.cardShape.strokeBorder(Color.red.opacity(0.3), lineWidth: 0.9))
                }
            }
        }
        .sheet(isPresented: $showCleanConfirmation) {
            cleanConfirmationModal
        }
    }
    
    private var selectedCleanSectionsTotalKb: Int64 {
        moleStore.cleanSections
            .filter { selectedCleanSections.contains($0.section) }
            .reduce(0) { $0 + $1.totalSizeKb }
    }
    
    private func cleanSectionRow(_ section: CleanSectionSummary) -> some View {
        let isSelected = selectedCleanSections.contains(section.section)
        
        return Button {
            if isSelected {
                selectedCleanSections.remove(section.section)
            } else {
                selectedCleanSections.insert(section.section)
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? MoleModuleTab.clean.accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.section)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("\(section.itemCount) item\(section.itemCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(section.formattedSize)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(AppTheme.subtleFill, in: Capsule())
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(
                AppTheme.cardShape
                    .strokeBorder(isSelected ? MoleModuleTab.clean.accentColor.opacity(0.35) : AppTheme.separator, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var cleanConfirmationModal: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.red)
                Text("Confirm System Clean")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button {
                    showCleanConfirmation = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Mole will execute 'mo clean' to clean all detected caches, logs, temporary files, and leftovers from uninstalled apps across your Mac.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Debris categories:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(moleStore.cleanSections.count) detected")
                        .font(.system(size: 12, weight: .bold))
                }
                HStack {
                    Text("Total cleanable size:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(moleStore.formattedTotalDebris)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.green)
                }
                HStack {
                    Text("Command:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("mo clean")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        CopyCommandButton(command: "mo clean", size: 20)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            HStack {
                Button("Cancel") {
                    showCleanConfirmation = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    showCleanConfirmation = false
                    Task { await moleStore.runCleanExecution() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Run mo clean")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.red)
            }
        }
        .padding(22)
        .frame(width: 440)
    }
    
    // MARK: - App Uninstaller View
    
    private var uninstallModuleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // App Uninstaller Toolbar with Copy Command Icons
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    TextField("Filter installed apps (e.g. Chrome, Docker, VSCode)…", text: $appSearchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    
                    if !appSearchText.isEmpty {
                        Button {
                            appSearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                )
                
                StatusPill(
                    title: "\(filteredApps.count) APPS",
                    symbol: "app.badge.checkmark",
                    tint: MoleModuleTab.uninstall.accentColor
                )
                
                Spacer()
                
                // Scan Apps & Copy
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.loadInstalledApps() }
                    } label: {
                        HStack(spacing: 5) {
                            if moleStore.isLoadingApps {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            Text("Scan Apps")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(moleStore.isLoadingApps)
                    
                    CopyCommandButton(command: "mo uninstall --list")
                    CopyCommandButton(command: "mo uninstall", title: "Copy 'mo uninstall'")
                }
            }
            
            // Error alert if app uninstall failed (e.g. root protected app)
            if let errorMsg = moleStore.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.warning)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Application Removal Notice")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(errorMsg)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let app = appToUninstall {
                        Button {
                            NSWorkspace.shared.selectFile(app.safePath, inFileViewerRootedAtPath: "")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text("Reveal in Finder")
                            }
                            .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Button {
                        moleStore.dismissErrorMessage()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(AppTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.warning.opacity(0.35), lineWidth: 0.8)
                )
            }
            
            // Success alert if an app was uninstalled
            if let successMsg = moleStore.uninstallSuccessMessage {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                    Text(successMsg)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Button {
                        moleStore.dismissSuccessMessage()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(AppTheme.success.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.success.opacity(0.3), lineWidth: 0.8)
                )
            }
            
            if moleStore.isLoadingApps && moleStore.installedApps.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning applications and calculating bundle sizes…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else if filteredApps.isEmpty {
                EmptyStateView(
                    symbol: "trash",
                    title: "No applications found",
                    message: appSearchText.isEmpty ? "No applications detected. Click 'Scan Apps' to refresh the list." : "No applications matching '\(appSearchText)'."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredApps) { app in
                        appRowCard(app)
                    }
                }
            }
        }
        .confirmationDialog(
            "Uninstall \(appToUninstall?.displayName ?? "Application")?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Uninstall with Mole", role: .destructive) {
                if let target = appToUninstall {
                    Task { await moleStore.uninstallApp(target, dryRun: false, withData: false) }
                }
            }
            Button("Uninstall with Personal App Data", role: .destructive) {
                if let target = appToUninstall {
                    Task { await moleStore.uninstallApp(target, dryRun: false, withData: true) }
                }
            }
            Button("Uninstall in Terminal") {
                if let target = appToUninstall {
                    moleStore.uninstallInTerminal(app: target)
                }
            }
            Button("Cancel", role: .cancel) {
                appToUninstall = nil
            }
        } message: {
            Text("Mole will run 'mo uninstall' to remove \(appToUninstall?.displayName ?? "this application") and its associated leftovers. No fallback deletions are performed by Purge.")
        }
        .sheet(item: $moleStore.appUninstallPreview) { preview in
            UninstallPreviewSheet(preview: preview, moleStore: moleStore)
        }
    }
    
    private func appRowCard(_ app: MoleInstalledApp) -> some View {
        HStack(spacing: 12) {
            // App Icon
            let icon = NSWorkspace.shared.icon(forFile: app.safePath)
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            
            // App Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(app.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(app.safeSize)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(MoleModuleTab.uninstall.accentColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(MoleModuleTab.uninstall.accentColor)
                }
                
                HStack(spacing: 6) {
                    Text(app.safeBundleId)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    
                    Text(app.safePath)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer(minLength: 8)
            
            // Action Buttons with Copy Icon
            HStack(spacing: 6) {
                // Copy command button
                CopyCommandButton(command: app.uninstallCommand)
                
                // Dry run preview button & copy
                Button {
                    Task { await moleStore.generateUninstallPreview(for: app) }
                } label: {
                    HStack(spacing: 4) {
                        if moleStore.isGeneratingPreview && moleStore.appUninstallPreview?.app.id == app.id {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "eye")
                                .font(.system(size: 10))
                        }
                        Text("Preview")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(moleStore.isUninstallingApp || moleStore.isGeneratingPreview)
                
                // Uninstall button
                Button {
                    appToUninstall = app
                    showUninstallConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("Uninstall")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.danger)
                .controlSize(.small)
                .disabled(moleStore.isUninstallingApp || moleStore.isRunningAction)
                
                // Context menu
                Menu {
                    Button {
                        moleStore.uninstallInTerminal(app: app)
                    } label: {
                        Label("Uninstall in Terminal", systemImage: "terminal")
                    }
                    
                    Button {
                        Task { await moleStore.uninstallApp(app, dryRun: false, withData: true) }
                    } label: {
                        Label("Uninstall with Personal App Data", systemImage: "trash.slash")
                    }
                    
                    Button {
                        _ = ClipboardService.copy(app.withDataCommand)
                    } label: {
                        Label("Copy Command with Data", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button {
                        NSWorkspace.shared.selectFile(app.safePath, inFileViewerRootedAtPath: "")
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 28)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                        )
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
        }
        .padding(14)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    // MARK: - Disk Analysis View
    
    private var analyzeModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Path selector pills & Toolbar
            HStack(spacing: 8) {
                let paths = ["/Applications", "~/Library", "~/Library/Caches", "/Volumes"]
                ForEach(paths, id: \.self) { path in
                    let isSelected = moleStore.currentAnalyzePath == path
                    Button {
                        Task { await moleStore.fetchAnalyze(path: path) }
                    } label: {
                        Text(path)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? MoleModuleTab.analyze.accentColor.opacity(0.15) : AppTheme.subtleFill,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? MoleModuleTab.analyze.accentColor.opacity(0.4) : AppTheme.separator,
                                        lineWidth: 0.8
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? MoleModuleTab.analyze.accentColor : .secondary)
                }
                
                Spacer()
                
                // Scan Path & Copy
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.fetchAnalyze(path: moleStore.currentAnalyzePath) }
                    } label: {
                        Label(moleStore.isAnalyzing ? "Analyzing…" : "Scan Path", systemImage: "chart.pie")
                            .font(.system(size: 11.5))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(moleStore.isAnalyzing)
                    
                    CopyCommandButton(command: "mo analyze \"\(moleStore.currentAnalyzePath)\"")
                }
            }
            
            if moleStore.isAnalyzing {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.regular)
                    Text("Analyzing disk usage for \(moleStore.currentAnalyzePath)…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(48)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else if let result = moleStore.analyzeResult {
                // Overview card
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Space Analyzed")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(result.formattedTotal)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("\(result.totalFiles) files explored in \(result.path)")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                }
                .padding(18)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
                
                // Ranked largest entries
                VStack(alignment: .leading, spacing: 10) {
                    SectionCaption(title: "Top Items by Size", trailing: "\(result.entries.count) items")
                    
                    let colors = [
                        Color.blue, Color.green, Color.orange, Color.purple, Color.cyan, Color.pink
                    ]
                    
                    ForEach(Array(result.entries.prefix(12).enumerated()), id: \.element.id) { index, entry in
                        let color = colors[index % colors.count]
                        let pct = result.totalSize > 0 ? Double(entry.size) / Double(result.totalSize) : 0.0
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.name)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color.opacity(0.35))
                                        .frame(width: max(geo.size.width * CGFloat(pct), 4), height: 4)
                                }
                                .frame(height: 4)
                            }
                            
                            Spacer()
                            
                            Text(entry.formattedSize)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(AppTheme.subtleFill, in: Capsule())
                            
                            CopyCommandButton(command: "open -R \"\(entry.path)\"", size: 24)
                            
                            Button {
                                NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                            } label: {
                                Image(systemName: "folder")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Reveal in Finder")
                        }
                        .padding(10)
                        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                        )
                    }
                }
            } else {
                EmptyStateView(
                    symbol: "chart.pie",
                    title: "Ready to Analyze Disk Usage",
                    message: "Select a directory path above to scan and visualize where your storage is going."
                )
            }
        }
    }
    
    // MARK: - System Optimize View
    
    private var optimizeModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Optimization & Repair")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Rebuild caches, flush DNS, check launch services, and resolve system bottlenecks.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Run Diagnostics & Copy
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.scanOptimizeDryRun() }
                    } label: {
                        Label(moleStore.isOptimizing ? "Diagnosing…" : "Run Diagnostics", systemImage: "stethoscope")
                            .font(.system(size: 11.5))
                    }
                    .buttonStyle(.bordered)
                    .disabled(moleStore.isOptimizing)
                    
                    CopyCommandButton(command: "mo optimize --dry-run")
                }
                
                // Optimize Now & Copy
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.runOptimizeExecution() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                            Text("Optimize Now")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(moleStore.isOptimizing)
                    
                    CopyCommandButton(command: "mo optimize")
                }
            }
            
            if moleStore.isOptimizing {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Inspecting system caches and diagnostic points…")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(AppTheme.panel, in: AppTheme.cardShape)
            } else {
                let diagnostics = moleStore.optimizeDiagnostics.isEmpty ? defaultOptimizeItems : moleStore.optimizeDiagnostics
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(diagnostics) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.status == .ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(item.status == .ok ? AppTheme.success : AppTheme.warning)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 12.5, weight: .semibold))
                                Text(item.details)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .background(AppTheme.panel, in: AppTheme.cardShape)
                        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
                    }
                }
            }
        }
    }
    
    private var defaultOptimizeItems: [OptimizeDiagnosticItem] {
        [
            OptimizeDiagnosticItem(id: "1", title: "Finder Cache & Thumbnails", details: "QuickLook thumbnails and icon caches valid", status: .ok),
            OptimizeDiagnosticItem(id: "2", title: "App Saved States", details: "Residual application state caches optimal", status: .ok),
            OptimizeDiagnosticItem(id: "3", title: "Preference Files & Plists", details: "All preference configurations valid", status: .ok),
            OptimizeDiagnosticItem(id: "4", title: "Spotlight Index", details: "Spotlight indexing system active", status: .ok),
            OptimizeDiagnosticItem(id: "5", title: "Launch Agents", details: "Background daemons operational", status: .ok),
            OptimizeDiagnosticItem(id: "6", title: "DNS Cache Resolver", details: "DNS cache flush ready", status: .ok)
        ]
    }
    
    // MARK: - Project Purge View (with Copy Command Icons)
    
    private var purgeModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Project Build Artifact Purge")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Reclaim gigabytes from dormant node_modules, target, build directories, and DerivedData.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Scan Projects & Copy Command
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.scanPurgeDryRun() }
                    } label: {
                        Label(moleStore.isPurging ? "Scanning…" : "Scan Projects", systemImage: "folder.badge.minus")
                            .font(.system(size: 11.5))
                    }
                    .buttonStyle(.bordered)
                    .disabled(moleStore.isPurging)
                    
                    CopyCommandButton(command: "mo purge --dry-run")
                }
                
                // Purge Build Artifacts & Copy Command
                HStack(spacing: 5) {
                    Button {
                        showPurgeConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            if moleStore.isPurging {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("Purge Build Artifacts")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(moleStore.isPurging)
                    
                    CopyCommandButton(command: "mo purge --yes")
                }
            }
            
            if let output = moleStore.purgeOutput {
                ScrollView(.vertical) {
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: 260)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else {
                EmptyStateView(
                    symbol: "folder.badge.minus",
                    title: "Ready to Scan Project Repositories",
                    message: "Click 'Scan Projects' to preview build artifacts taking up disk space in your code directories."
                )
            }
        }
        .confirmationDialog(
            "Permanently Purge Developer Build Artifacts?",
            isPresented: $showPurgeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Purge Build Artifacts Permanently", role: .destructive) {
                Task { await moleStore.runPurgeExecution() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mole will permanently delete build directories (node_modules, DerivedData, build/, target/) across all projects found in your configured paths. These files cannot be recovered from Trash.")
        }
    }
    
    // MARK: - Installers View (with Copy Command Icons)
    
    private var installersModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Installer Files Sweep")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Locate and remove leftover installer packages (.dmg, .pkg, .iso, .zip).")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Scan Installers & Copy
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.scanInstallerDryRun() }
                    } label: {
                        Label(moleStore.isSweepingInstallers ? "Scanning…" : "Scan Installers", systemImage: "archivebox")
                            .font(.system(size: 11.5))
                    }
                    .buttonStyle(.bordered)
                    .disabled(moleStore.isSweepingInstallers)
                    
                    CopyCommandButton(command: "mo installer --dry-run")
                }
                
                // Sweep Installers & Copy
                HStack(spacing: 5) {
                    Button {
                        showInstallerConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash")
                            Text("Sweep Installers")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(moleStore.isSweepingInstallers)
                    
                    CopyCommandButton(command: "mo installer")
                }
            }
            
            if let output = moleStore.installerOutput {
                ScrollView(.vertical) {
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: 240)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else {
                EmptyStateView(
                    symbol: "archivebox",
                    title: "Ready to Sweep Leftover Installers",
                    message: "Scan Downloads and system folders for orphaned installation media."
                )
            }
        }
        .confirmationDialog(
            "Permanently Delete Installer Files?",
            isPresented: $showInstallerConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Installers Permanently", role: .destructive) {
                Task { await moleStore.runInstallerSweep() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mole will run 'mo installer' to permanently remove leftover disk images (.dmg), package files (.pkg), and installer archives (.iso, .zip). This action cannot be undone.")
        }
    }
    
    // MARK: - History View (with Copy Command Icons)
    
    private var historyModuleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cleanup History & Audit Log")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Forensic audit log of previous Mole cleaning operations and reclaimed storage.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Button {
                        Task { await moleStore.fetchHistory() }
                    } label: {
                        Label(moleStore.isLoadingHistory ? "Loading…" : "Refresh Log", systemImage: "arrow.clockwise")
                            .font(.system(size: 11.5))
                    }
                    .buttonStyle(.bordered)
                    .disabled(moleStore.isLoadingHistory)
                    
                    CopyCommandButton(command: "mo history --limit 40")
                    CopyCommandButton(command: "mo history")
                }
            }
            
            if let output = moleStore.historyOutput {
                ScrollView(.vertical) {
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxHeight: 300)
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.8))
            } else {
                EmptyStateView(
                    symbol: "clock.arrow.circlepath",
                    title: "No History Records Yet",
                    message: "Run a clean or optimization action to create your first forensic audit entry."
                )
            }
        }
    }
    
    // MARK: - Commands Module View (Preserved CLI Catalog)
    
    private var commandsModuleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoleModuleCategory.allCases) { cat in
                        Button {
                            selectedCatalogCategory = cat
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.symbol)
                                    .font(.system(size: 11))
                                Text(cat.title)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                selectedCatalogCategory == cat ? AppTheme.accent.opacity(0.14) : AppTheme.subtleFill,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        selectedCatalogCategory == cat ? AppTheme.accent.opacity(0.4) : AppTheme.separator,
                                        lineWidth: 0.8
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(selectedCatalogCategory == cat ? AppTheme.accent : .secondary)
                    }
                }
            }
            
            LazyVStack(spacing: 10) {
                ForEach(filteredCatalogActions) { action in
                    moleActionCard(action)
                }
            }
            
            // Console output drawer for CLI commands catalog
            if let output = moleStore.lastOutput {
                outputConsole(output: output)
            }
        }
    }
    
    private func moleActionCard(_ action: MoleActionItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: action.category.symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(action.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text(action.dangerLevel.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                action.dangerLevel == "Safe" ? AppTheme.success.opacity(0.12) : AppTheme.subtleFill,
                                in: Capsule()
                            )
                            .foregroundStyle(action.dangerLevel == "Safe" ? AppTheme.success : .secondary)
                    }
                    
                    Text(action.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 8)
                
                // Command pill with 1-click copy
                HStack(spacing: 6) {
                    Text(action.command)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    CopyCommandButton(command: action.command, size: 22)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                )
            }
            
            HStack(spacing: 8) {
                Text(action.tip)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                if action.isDryRunSupported {
                    HStack(spacing: 4) {
                        Button {
                            Task { await moleStore.runDryRun(action: action) }
                        } label: {
                            HStack(spacing: 5) {
                                if moleStore.isRunningAction && moleStore.activeActionId == action.id {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "eye")
                                        .font(.system(size: 10))
                                }
                                Text(action.category == .commands ? "Run Test" : "Dry Run")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(moleStore.isRunningAction)
                        
                        CopyCommandButton(command: action.dryRunCommand, size: 26)
                    }
                }
                
                CopyCommandButton(command: action.command, size: 26)
            }
        }
        .padding(14)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    // MARK: - Output Console
    
    private func outputConsole(output: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("OUTPUT CONSOLE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(.tertiary)
                    if let action = moleStore.lastOutputAction {
                        Text("· \(action)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                Spacer()
                
                Button {
                    if ClipboardService.copy(output) {
                        hasCopiedOutput = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopiedOutput = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopiedOutput ? "checkmark" : "doc.on.doc")
                        Text(hasCopiedOutput ? "Copied" : "Copy")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundStyle(hasCopiedOutput ? AppTheme.success : .secondary)
                
                Button {
                    moleStore.clearOutput()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear output")
            }
            
            ScrollView(.vertical) {
                Text(output)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(10)
            }
            .frame(maxHeight: 220)
            .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 0.8)
            )
        }
        .padding(14)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    // MARK: - Not Installed Banner
    
    private var notInstalledBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Install Mole for Deep System Cleaning")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Mole is a modern open-source Mac optimizer (https://github.com/tw93/mole). Install it with Homebrew in one command.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 10) {
                Text("brew install mole")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                    )
                
                CopyCommandButton(command: "brew install mole", title: "Copy command")
            }
        }
        .padding(20)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}

// MARK: - App Uninstall Preview Sheet

struct UninstallPreviewSheet: View {
    let preview: AppUninstallPreview
    @ObservedObject var moleStore: MoleStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 14) {
                let icon = NSWorkspace.shared.icon(forFile: preview.app.safePath)
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(preview.app.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        
                        Text(preview.formattedTotalSize)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(MoleModuleTab.uninstall.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(MoleModuleTab.uninstall.accentColor)
                    }
                    
                    Text(preview.app.safeBundleId)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Warning if Root-Protected (e.g. Microsoft OneNote)
            if preview.isRootProtected {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.warning)
                        .padding(.top, 1)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Protected Application Bundle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("This application bundle is owned by system/root (installed via Mac App Store or Microsoft Installer) and cannot be deleted by unprivileged processes. Use 'Reveal in Finder' and drag it to Trash with your macOS password.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        NSWorkspace.shared.selectFile(preview.app.safePath, inFileViewerRootedAtPath: "")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Reveal in Finder")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(12)
                .background(AppTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppTheme.warning.opacity(0.35), lineWidth: 0.8)
                )
            }
            
            // Candidate Paths List
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Application Files & Leftovers (\(preview.items.count))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 8) {
                        ForEach(preview.items) { item in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.category)
                                            .font(.system(size: 10, weight: .semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.subtleFill, in: Capsule())
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text(item.formattedSize)
                                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    Text(item.path)
                                        .font(.system(size: 10.5, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Button {
                                    _ = ClipboardService.copy(item.path)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Copy path")
                                
                                Button {
                                    NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                                } label: {
                                    Image(systemName: "folder")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Reveal in Finder")
                            }
                            .padding(10)
                            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                            )
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            
            // CLI Diagnostics disclosure
            if !preview.rawOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DisclosureGroup("Diagnostics & Dry-Run Log") {
                    ScrollView(.vertical) {
                        Text(preview.rawOutput)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    }
                    .frame(maxHeight: 120)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
            
            // Bottom Action Buttons
            HStack(spacing: 10) {
                CopyCommandButton(command: preview.app.uninstallCommand, title: "Copy 'mo uninstall'")
                
                Button {
                    dismiss()
                    moleStore.uninstallInTerminal(app: preview.app)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "terminal")
                        Text("Uninstall in Terminal")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                if !preview.isRootProtected {
                    Button(role: .destructive) {
                        dismiss()
                        Task { await moleStore.uninstallApp(preview.app, dryRun: false, withData: false) }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash.fill")
                            Text("Uninstall with Mole")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.danger)
                }
            }
        }
        .padding(22)
        .frame(width: 560)
    }
}

