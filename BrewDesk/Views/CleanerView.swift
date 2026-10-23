import SwiftUI

enum CleanerSection: String, CaseIterable, Identifiable {
    case autoremove = "Autoremove"
    case clean = "Clean"
    case purgeCache = "Purge cache"
    
    var id: String { rawValue }
    var title: String { rawValue }
    
    var symbol: String {
        switch self {
        case .autoremove: return "xmark.bin"
        case .clean: return "sparkles"
        case .purgeCache: return "flame"
        }
    }
    
    var subtitle: String {
        switch self {
        case .autoremove: return "Orphaned dependencies"
        case .clean: return "Outdated packages & locks"
        case .purgeCache: return "Wipe active bottle cache"
        }
    }
    
    var command: String {
        switch self {
        case .autoremove: return "brew autoremove"
        case .clean: return "brew cleanup"
        case .purgeCache: return "brew cleanup --prune=all"
        }
    }
}

struct CleanerView: View {
    @ObservedObject var homebrew: HomebrewStore
    @StateObject private var cleaner = CleanerService()
    @State private var selectedSection: CleanerSection = .clean
    
    @State private var copiedItemID: String?
    @State private var hasCopiedSectionCommand = false
    @State private var showConfirmDialog = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "HOMEBREW HYGIENE",
                title: "Cleaner",
                description: "Keep your Homebrew installation optimized by removing unused dependencies, outdated package versions, and cached bottle archives."
            )
            
            // Main Master-Detail Layout
            HStack(alignment: .top, spacing: 20) {
                // Left Navigation: 3 Cleaner Sections
                VStack(spacing: 12) {
                    ForEach(CleanerSection.allCases) { section in
                        CleanerSectionCard(
                            section: section,
                            isSelected: selectedSection == section,
                            badgeText: badgeText(for: section),
                            isWarning: section == .purgeCache && cleaner.cacheSizeBytes > 0 && cleaner.cleanupItems.isEmpty
                        ) {
                            selectedSection = section
                        }
                    }
                    
                    Spacer(minLength: 16)
                    
                    // Persistent Cache Footprint summary card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.accent)
                            Text("CACHE FOOTPRINT")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Text(cleaner.lastScannedAt != nil ? cleaner.cacheFormattedSize : "Scanning…")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("Stored in ~/Library/Caches/Homebrew")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.separator, lineWidth: 0.8)
                    )
                }
                .frame(width: 260)
                
                // Right Panel: Selected Section Detail
                VStack(alignment: .leading, spacing: 18) {
                    rightSectionHeader
                    
                    rightSectionMetrics
                    
                    rightSectionActionBar
                    
                    if let error = cleaner.cleanerError {
                        NotePanel(
                            symbol: "exclamationmark.triangle",
                            title: "Notice",
                            message: error,
                            tint: AppTheme.warning
                        )
                    }
                    
                    rightSectionContentTable
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .task {
            await cleaner.scanAll(using: homebrew.installation)
        }
        .confirmationDialog(confirmTitle, isPresented: $showConfirmDialog) {
            Button(confirmActionLabel, role: .destructive) {
                runSelectedAction()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmMessage)
        }
    }
    
    // MARK: - Right Panel Components
    
    private var rightSectionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: selectedSection.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(selectedSection.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Text(sectionDescription)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var rightSectionMetrics: some View {
        HStack(spacing: 12) {
            switch selectedSection {
            case .autoremove:
                MetricCard(
                    title: "Orphaned dependencies",
                    value: cleaner.autoremoveItems.isEmpty ? "None" : "\(cleaner.autoremoveItems.count) packages",
                    detail: cleaner.autoremoveItems.isEmpty ? "All dependencies required" : "Safe to remove",
                    symbol: "xmark.bin",
                    tint: cleaner.autoremoveItems.isEmpty ? AppTheme.success : AppTheme.warning
                )
                MetricCard(
                    title: "Safety",
                    value: "100% safe",
                    detail: "Only unneeded sub-dependencies",
                    symbol: "checkmark.shield",
                    tint: AppTheme.success
                )
                MetricCard(
                    title: "CLI Command",
                    value: "brew autoremove",
                    detail: "Standard Homebrew command",
                    symbol: "terminal",
                    tint: AppTheme.accent
                )
                
            case .clean:
                MetricCard(
                    title: "Cleanable files",
                    value: "\(cleaner.cleanupItems.count) items",
                    detail: cleaner.cleanupItems.isEmpty ? "No stale versions found" : "Superseded packages & locks",
                    symbol: "trash",
                    tint: cleaner.cleanupItems.isEmpty ? AppTheme.success : AppTheme.warning
                )
                MetricCard(
                    title: "Current Cache",
                    value: cleaner.cacheFormattedSize,
                    detail: "Active versions preserved",
                    symbol: "archivebox",
                    tint: AppTheme.accent
                )
                MetricCard(
                    title: "CLI Command",
                    value: "brew cleanup",
                    detail: "Safely removes obsolete files",
                    symbol: "terminal",
                    tint: AppTheme.accent
                )
                
            case .purgeCache:
                MetricCard(
                    title: "Total bottle cache",
                    value: cleaner.cacheFormattedSize,
                    detail: "Active formula & cask archives",
                    symbol: "archivebox",
                    tint: AppTheme.accent
                )
                MetricCard(
                    title: "Cached archives",
                    value: "\(cleaner.cachedBottleItems.count) files",
                    detail: "Re-downloaded if reinstalled",
                    symbol: "flame",
                    tint: AppTheme.warning
                )
                MetricCard(
                    title: "CLI Command",
                    value: "brew cleanup --prune=all",
                    detail: "Wipes all cached downloads",
                    symbol: "terminal",
                    tint: AppTheme.warning
                )
            }
        }
    }
    
    private var rightSectionActionBar: some View {
        HStack(spacing: 10) {
            if cleaner.isCleaning || cleaner.isScanning {
                ProgressView().controlSize(.small)
                Text(cleaner.activeAction ?? (cleaner.isCleaning ? "Processing…" : "Scanning…"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Refresh / Scan Button
            Button {
                Task {
                    await cleaner.scanAll(using: homebrew.installation)
                }
            } label: {
                Label(cleaner.isScanning ? "Scanning…" : "Scan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(cleaner.isScanning || cleaner.isCleaning)
            .help(Text(verbatim: "Scan for cleanable items"))
            
            // Action Button + Copy Command Combo
            HStack(spacing: 0) {
                if selectedSection == .purgeCache {
                    Button {
                        showConfirmDialog = true
                    } label: {
                        Label(actionButtonTitle, systemImage: selectedSection.symbol)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.warning)
                    .disabled(cleaner.isCleaning || cleaner.isScanning || isActionButtonDisabled)
                } else {
                    Button {
                        showConfirmDialog = true
                    } label: {
                        Label(actionButtonTitle, systemImage: selectedSection.symbol)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(cleaner.isCleaning || cleaner.isScanning || isActionButtonDisabled)
                }
                
                Button {
                    if ClipboardService.copy(selectedSection.command) {
                        hasCopiedSectionCommand = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopiedSectionCommand = false
                        }
                    }
                } label: {
                    Image(systemName: hasCopiedSectionCommand ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(hasCopiedSectionCommand ? AppTheme.success : (selectedSection == .purgeCache ? AppTheme.warning : .white))
                        .frame(width: 28, height: 28)
                        .background(selectedSection == .purgeCache ? AppTheme.subtleFill : AppTheme.accent)
                }
                .buttonStyle(.plain)
                .help(Text(verbatim: hasCopiedSectionCommand ? "Copied!" : "Copy command: \(selectedSection.command)"))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                selectedSection == .purgeCache
                ? RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(AppTheme.warning.opacity(0.3), lineWidth: 0.8)
                : nil
            )
        }
    }
    
    private var rightSectionContentTable: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                Text(tableFirstColumnHeader)
                Spacer(minLength: 12)
                Text("CATEGORY").frame(width: 140, alignment: .leading)
                Text(selectedSection == .autoremove ? "STATUS" : "EST. SIZE").frame(width: 90, alignment: .leading)
                Text("COMMAND").frame(width: 80, alignment: .center)
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            
            Divider().overlay(AppTheme.separator)
            
            // Table Content
            switch selectedSection {
            case .autoremove:
                if cleaner.isScanning && cleaner.autoremoveItems.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Scanning dependency tree",
                        message: "Purge is running `brew autoremove -n` to detect unneeded packages."
                    )
                } else if cleaner.autoremoveItems.isEmpty {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: "No unneeded dependencies",
                        message: "All installed formula dependencies are actively required by your installed tools or were explicitly requested by you."
                    )
                } else {
                    itemList(cleaner.autoremoveItems)
                }
                
            case .clean:
                if cleaner.isScanning && cleaner.cleanupItems.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Scanning Homebrew cache",
                        message: "Purge is running `brew cleanup -n` to find outdated downloads and lockfiles."
                    )
                } else if cleaner.cleanupItems.isEmpty {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: "Homebrew downloads are clean",
                        message: cleaner.cacheSizeBytes > 0
                        ? "No outdated package versions or stale lockfiles found. Active bottle archives (\(cleaner.cacheFormattedSize)) are kept for your installed software so reinstallations are instant. Select 'Purge cache' if you wish to clear all archived downloads."
                        : "No stale lockfiles, outdated bottle downloads, or orphaned packages found."
                    )
                } else {
                    itemList(cleaner.cleanupItems)
                }
                
            case .purgeCache:
                if cleaner.isScanning && cleaner.cachedBottleItems.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Analyzing bottle cache",
                        message: "Purge is enumerating cached downloads in ~/Library/Caches/Homebrew."
                    )
                } else if cleaner.cacheSizeBytes == 0 {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: "Bottle cache is completely empty",
                        message: "There are no cached bottle archives in ~/Library/Caches/Homebrew."
                    )
                } else {
                    itemList(cleaner.cachedBottleItems)
                }
            }
        }
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    private func itemList(_ items: [CleanableItem]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(item.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer(minLength: 8)
                    
                    Text(item.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.subtleFill, in: Capsule())
                        .frame(width: 140, alignment: .leading)
                    
                    Text(item.sizeString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 90, alignment: .leading)
                    
                    Button {
                        if ClipboardService.copy(item.removeCommand) {
                            copiedItemID = item.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                if copiedItemID == item.id {
                                    copiedItemID = nil
                                }
                            }
                        }
                    } label: {
                        Image(systemName: copiedItemID == item.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(copiedItemID == item.id ? AppTheme.success : AppTheme.accent)
                            .frame(width: 26, height: 26)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(copiedItemID == item.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(Text(verbatim: copiedItemID == item.id ? "Copied!" : "Copy command: \(item.removeCommand)"))
                    .frame(width: 80, alignment: .center)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                
                if item.id != items.last?.id {
                    Divider().overlay(AppTheme.separator.opacity(0.7)).padding(.leading, 18)
                }
            }
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private func badgeText(for section: CleanerSection) -> String {
        switch section {
        case .autoremove:
            return cleaner.autoremoveItems.isEmpty ? "Clean" : "\(cleaner.autoremoveItems.count)"
        case .clean:
            return cleaner.cleanupItems.isEmpty ? "Clean" : "\(cleaner.cleanupItems.count) items"
        case .purgeCache:
            return cleaner.cacheSizeBytes > 0 ? cleaner.cacheFormattedSize : "0 B"
        }
    }
    
    private var sectionDescription: String {
        switch selectedSection {
        case .autoremove:
            return "Homebrew keeps track of whether packages were installed explicitly by you or as dependencies. When you remove a tool, its dependencies may be left behind. Autoremove finds and uninstalls these unused packages."
        case .clean:
            return "Homebrew downloads formula bottles and cask installers into cache folders. Over time, previous versions accumulate. Clean removes outdated downloads and stale lockfiles while keeping active software untouched."
        case .purgeCache:
            return "Homebrew retains downloaded archives for your active packages in ~/Library/Caches/Homebrew so they don't need re-downloading if reinstalled. Purge completely clears this archive store to maximize free disk space."
        }
    }
    
    private var tableFirstColumnHeader: String {
        switch selectedSection {
        case .autoremove: return "PACKAGE / DEPENDENCY"
        case .clean: return "CLEANABLE ITEM / FILE"
        case .purgeCache: return "CACHED ARCHIVE / FEED"
        }
    }
    
    private var actionButtonTitle: String {
        switch selectedSection {
        case .autoremove: return "Run Autoremove"
        case .clean: return "Clean Homebrew"
        case .purgeCache: return "Purge All Cache"
        }
    }
    
    private var isActionButtonDisabled: Bool {
        switch selectedSection {
        case .autoremove:
            return false
        case .clean:
            return cleaner.cleanupItems.isEmpty && cleaner.cacheSizeBytes == 0
        case .purgeCache:
            return cleaner.cacheSizeBytes == 0
        }
    }
    
    private var confirmTitle: String {
        switch selectedSection {
        case .autoremove: return "Run Homebrew Autoremove?"
        case .clean: return "Run Homebrew Cleanup?"
        case .purgeCache: return "Purge All Homebrew Cache?"
        }
    }
    
    private var confirmActionLabel: String {
        switch selectedSection {
        case .autoremove: return "Autoremove Unneeded Packages"
        case .clean: return "Clean Outdated Files"
        case .purgeCache: return "Purge Entire Cache"
        }
    }
    
    private var confirmMessage: String {
        switch selectedSection {
        case .autoremove:
            return "Purge will run `brew autoremove` to uninstall orphaned formula dependencies that are no longer required by any installed software."
        case .clean:
            return "Purge will run `brew cleanup` to safely remove superseded package downloads, old versions, and stale lockfiles. Your installed software will remain intact."
        case .purgeCache:
            return "Purge will run `brew cleanup --prune=all` to delete all bottle downloads and cached archives in ~/Library/Caches/Homebrew (\(cleaner.cacheFormattedSize)). Homebrew will re-download files if needed in the future."
        }
    }
    
    private func runSelectedAction() {
        Task {
            switch selectedSection {
            case .autoremove:
                _ = await cleaner.runAutoremove(using: homebrew.installation)
            case .clean:
                _ = await cleaner.runCleanup(using: homebrew.installation)
            case .purgeCache:
                _ = await cleaner.pruneAllCache(using: homebrew.installation)
            }
        }
    }
}

// MARK: - Section Card Component

private struct CleanerSectionCard: View {
    let section: CleanerSection
    let isSelected: Bool
    let badgeText: String
    let isWarning: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.symbol)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.accent : .secondary)
                    .frame(width: 30, height: 30)
                    .background(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                    
                    Text(section.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                Text(badgeText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? AppTheme.accent : (isWarning ? AppTheme.warning : .secondary))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.subtleFill, in: Capsule())
            }
            .padding(12)
            .background(isSelected ? AppTheme.panel : AppTheme.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.accent.opacity(0.35) : AppTheme.separator, lineWidth: isSelected ? 1.2 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

typealias CleanerPage = CleanerView
