import SwiftUI

struct UpdatesView: View {
    @ObservedObject var homebrew: HomebrewStore
    @State private var showDirectOnly = true
    @State private var refreshGeneration = 0
    @State private var copiedPackageID: String?
    
    private var filteredPackages: [HomebrewOutdatedPackage] {
        homebrew.outdatedPackages.filter { package in
            !showDirectOnly || package.isDirect
        }
    }
    
    private var formulaOutdatedCount: Int {
        filteredPackages.filter { $0.kind == .formula }.count
    }
    
    private var totalFormulaOutdatedCount: Int {
        homebrew.outdatedPackages.filter { $0.kind == .formula }.count
    }
    
    private var caskOutdatedCount: Int {
        filteredPackages.filter { $0.kind == .cask }.count
    }
    
    private var lastCheckedFormatted: String {
        guard let date = homebrew.updatesCheckedAt else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "MAINTENANCE",
                title: "Stay up to date",
                description: "Review outdated formulae and casks before choosing what to update. Purge runs `brew outdated` on demand."
            )
            
            HStack(spacing: 12) {
                MetricCard(
                    title: "Formulae",
                    value: homebrew.hasCheckedUpdates
                        ? (formulaOutdatedCount == 0
                            ? (showDirectOnly && totalFormulaOutdatedCount > 0 ? "Up to date (direct)" : "Up to date")
                            : "\(formulaOutdatedCount) available")
                        : "Not checked",
                    symbol: "terminal"
                )
                MetricCard(
                    title: "Casks",
                    value: homebrew.hasCheckedUpdates ? (caskOutdatedCount == 0 ? "Up to date" : "\(caskOutdatedCount) available") : "Not checked",
                    symbol: "macwindow"
                )
                MetricCard(
                    title: "Last check",
                    value: lastCheckedFormatted,
                    symbol: "clock"
                )
            }
            
            HStack(spacing: 12) {
                Button {
                    showDirectOnly.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showDirectOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 12))
                        Text(showDirectOnly ? "Direct only" : "All packages")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .tint(showDirectOnly ? AppTheme.accent : nil)
                .help(Text(verbatim: showDirectOnly ? "Showing direct/top-level apps only. Click to view all packages including dependencies." : "Click to view direct apps instead of transitive dependencies."))
                
                if homebrew.isCheckingUpdates {
                    ProgressView().controlSize(.small)
                    Text("Checking for updates…")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else if homebrew.hasCheckedUpdates {
                    if homebrew.outdatedPackages.isEmpty {
                        StatusPill(title: "ALL CURRENT", symbol: "checkmark.circle.fill", tint: AppTheme.success)
                    } else if filteredPackages.isEmpty {
                        StatusPill(title: "NO DIRECT UPDATES", symbol: "checkmark.circle.fill", tint: AppTheme.success)
                    } else {
                        StatusPill(
                            title: showDirectOnly && filteredPackages.count != homebrew.outdatedPackages.count
                                ? "\(filteredPackages.count) DIRECT UPDATES"
                                : "\(filteredPackages.count) UPDATES",
                            symbol: "arrow.triangle.2.circlepath",
                            tint: AppTheme.warning
                        )
                    }
                }
                
                Spacer()
                
                Button {
                    refreshGeneration += 1
                } label: {
                    Label(homebrew.isCheckingUpdates ? "Checking…" : "Check for updates", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(homebrew.isCheckingUpdates || homebrew.isUpgradingAll || homebrew.updatingPackage != nil)
                
                if !filteredPackages.isEmpty {
                    Button {
                        Task { await homebrew.upgradePackages(filteredPackages) }
                    } label: {
                        HStack(spacing: 6) {
                            if homebrew.isUpgradingAll {
                                ProgressView().controlSize(.small)
                            }
                            Label(homebrew.isUpgradingAll ? "Updating all…" : "Update all (\(filteredPackages.count))", systemImage: "arrow.up.circle.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(homebrew.isCheckingUpdates || homebrew.isUpgradingAll || homebrew.updatingPackage != nil)
                }
            }
            
            if let error = homebrew.updatesError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: "Could not check for updates",
                    message: error,
                    tint: AppTheme.warning
                )
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("PACKAGE")
                    Spacer(minLength: 12)
                    Text("INSTALLATION").frame(width: 90, alignment: .leading)
                    Text("TYPE").frame(width: 75, alignment: .leading)
                    Text("CURRENT").frame(width: 105, alignment: .leading)
                    Text("LATEST").frame(width: 105, alignment: .leading)
                    Text("COMMAND").frame(width: 75, alignment: .center)
                    Text("ACTION").frame(width: 85, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                
                Divider().overlay(AppTheme.separator)
                
                if homebrew.isCheckingUpdates && homebrew.outdatedPackages.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Checking for updates",
                        message: "Purge is querying Homebrew to check for available updates."
                    )
                } else if !homebrew.hasCheckedUpdates && homebrew.updatesError == nil {
                    EmptyStateView(
                        symbol: "arrow.triangle.2.circlepath",
                        title: "Updates not checked yet",
                        message: "Click 'Check for updates' above to discover outdated formulae and casks."
                    )
                } else if homebrew.outdatedPackages.isEmpty {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: "All packages are up to date",
                        message: "No newer versions were reported for your installed formulae and casks."
                    )
                } else if filteredPackages.isEmpty {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: "All direct packages are up to date",
                        message: "No newer versions were reported for direct packages. Click 'Direct only' to switch to 'All packages' and see \(homebrew.outdatedPackages.count) dependency update\(homebrew.outdatedPackages.count == 1 ? "" : "s")."
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPackages) { package in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(package.name)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(package.kind == .formula ? "Formula update" : "Cask update")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                                
                                Spacer(minLength: 8)
                                
                                HStack {
                                    if package.isDirect {
                                        Text("Direct")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(AppTheme.accent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.accent.opacity(0.12), in: Capsule())
                                    } else {
                                        Text("Dependency")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.subtleFill, in: Capsule())
                                    }
                                }
                                .frame(width: 90, alignment: .leading)
                                
                                Text(package.kind.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.subtleFill, in: Capsule())
                                    .frame(width: 75, alignment: .leading)
                                
                                Text(package.installedVersion)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(width: 105, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.accent)
                                    Text(package.currentVersion)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppTheme.accent)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .frame(width: 105, alignment: .leading)
                                
                                Button {
                                    if ClipboardService.copy(package.upgradeCommand) {
                                        copiedPackageID = package.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if copiedPackageID == package.id {
                                                copiedPackageID = nil
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: copiedPackageID == package.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(copiedPackageID == package.id ? AppTheme.success : AppTheme.accent)
                                        .frame(width: 26, height: 26)
                                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .strokeBorder(copiedPackageID == package.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                                        )
                                }
                                .buttonStyle(.plain)
                                .help(Text(verbatim: copiedPackageID == package.id ? "Copied!" : "Copy update command: \(package.upgradeCommand)"))
                                .frame(width: 75, alignment: .center)
                                
                                HStack {
                                    if homebrew.updatingPackage == package.name {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Button {
                                            Task { await homebrew.upgradePackage(package: package) }
                                        } label: {
                                            Label("Update", systemImage: "arrow.up")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        .disabled(homebrew.isUpgradingAll || homebrew.updatingPackage != nil)
                                    }
                                }
                                .frame(width: 85, alignment: .trailing)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            
                            if package.id != filteredPackages.last?.id {
                                Divider().overlay(AppTheme.separator.opacity(0.7)).padding(.leading, 18)
                            }
                        }
                    }
                }
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
        .task(id: refreshGeneration) {
            await homebrew.checkUpdates()
        }
    }
}

typealias UpdatesPage = UpdatesView
