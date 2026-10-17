import SwiftUI

struct DiscoverPage: View {
    let searchText: String
    @State private var selectedKind: CatalogueKind = .formulae

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "HOME BREW CATALOGUE",
                title: "Find your next tool",
                description: "Search the Homebrew catalogue for formulae and casks. Online catalogue search is not connected in this design build."
            )

            HStack(spacing: 12) {
                Picker("Catalogue type", selection: $selectedKind) {
                    ForEach(CatalogueKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                Spacer()
                StatusPill(title: "NETWORK IDLE", symbol: "wifi.slash", tint: .secondary)
            }

            VStack(spacing: 0) {
                EmptyStateView(
                    symbol: "sparkle.magnifyingglass",
                    title: searchText.isEmpty ? "Search the catalogue" : "Ready for catalogue search",
                    message: searchText.isEmpty
                        ? "Enter a package name in the search field above. No network request is made by this preview."
                        : "“\(searchText)” will be searched as a \(selectedKind.title.lowercased()) when online search is implemented."
                )
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            NotePanel(
                symbol: "hand.raised",
                title: "No silent installs",
                message: "The finished workflow will show the exact Homebrew command before an install and ask for confirmation before changing your system.",
                tint: AppTheme.success
            )
        }
    }
}

private enum CatalogueKind: String, CaseIterable, Identifiable, Hashable {
    case formulae, casks
    var id: String { rawValue }
    var title: String {
        switch self {
        case .formulae: return "Formulae"
        case .casks: return "Casks"
        }
    }
}

struct UpdatesPage: View {
    @ObservedObject var homebrew: HomebrewStore
    @AppStorage("customHomebrewPath") private var customHomebrewPath = ""
    @State private var refreshGeneration = 0

    private var formulaOutdatedCount: Int {
        homebrew.outdatedPackages.filter { $0.kind == .formula }.count
    }

    private var caskOutdatedCount: Int {
        homebrew.outdatedPackages.filter { $0.kind == .cask }.count
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
                description: "Review outdated formulae and casks before choosing what to update. BrewDesk runs `brew outdated` on demand."
            )

            HStack(spacing: 12) {
                UpdateSummaryCard(
                    title: "Formulae",
                    value: homebrew.hasCheckedUpdates ? (formulaOutdatedCount == 0 ? "Up to date" : "\(formulaOutdatedCount) available") : "Not checked",
                    symbol: "terminal"
                )
                UpdateSummaryCard(
                    title: "Casks",
                    value: homebrew.hasCheckedUpdates ? (caskOutdatedCount == 0 ? "Up to date" : "\(caskOutdatedCount) available") : "Not checked",
                    symbol: "macwindow"
                )
                UpdateSummaryCard(
                    title: "Last check",
                    value: lastCheckedFormatted,
                    symbol: "clock"
                )
            }

            HStack(spacing: 12) {
                if homebrew.isCheckingUpdates {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking for updates…")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else if homebrew.hasCheckedUpdates {
                    if homebrew.outdatedPackages.isEmpty {
                        StatusPill(title: "ALL CURRENT", symbol: "checkmark.circle.fill", tint: AppTheme.success)
                    } else {
                        StatusPill(title: "\(homebrew.outdatedPackages.count) UPDATES", symbol: "arrow.triangle.2.circlepath", tint: AppTheme.warning)
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

                if !homebrew.outdatedPackages.isEmpty {
                    Button {
                        Task {
                            await homebrew.upgradeAll(customPath: customHomebrewPath)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if homebrew.isUpgradingAll {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Label(homebrew.isUpgradingAll ? "Updating all…" : "Update all (\(homebrew.outdatedPackages.count))", systemImage: "arrow.up.circle.fill")
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
                    Text("TYPE")
                        .frame(width: 80, alignment: .leading)
                    Text("CURRENT")
                        .frame(width: 120, alignment: .leading)
                    Text("LATEST")
                        .frame(width: 120, alignment: .leading)
                    Text("ACTION")
                        .frame(width: 90, alignment: .trailing)
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
                        message: "BrewDesk is querying Homebrew to check for available updates."
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
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(homebrew.outdatedPackages) { package in
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

                                Text(package.kind.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.subtleFill, in: Capsule())
                                    .frame(width: 80, alignment: .leading)

                                Text(package.installedVersion)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(width: 120, alignment: .leading)

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
                                .frame(width: 120, alignment: .leading)

                                HStack {
                                    if homebrew.updatingPackage == package.name {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Button {
                                            Task {
                                                await homebrew.upgradePackage(package: package, customPath: customHomebrewPath)
                                            }
                                        } label: {
                                            Label("Update", systemImage: "arrow.up")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        .disabled(homebrew.isUpgradingAll || homebrew.updatingPackage != nil)
                                    }
                                }
                                .frame(width: 90, alignment: .trailing)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            if package.id != homebrew.outdatedPackages.last?.id {
                                Divider().overlay(AppTheme.separator.opacity(0.7))
                                    .padding(.leading, 18)
                            }
                        }
                    }
                }
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
        .task(id: refreshGeneration) {
            await homebrew.checkUpdates(customPath: customHomebrewPath)
        }
    }
}

private struct UpdateSummaryCard: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 14, weight: .semibold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}

struct CleanerPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "SPACE & HYGIENE",
                title: "Clean with confidence",
                description: "Review potential caches, logs, and application leftovers before taking action."
            )

            HStack(spacing: 12) {
                CleanerCategoryCard(title: "Caches", subtitle: "Not scanned", symbol: "archivebox")
                CleanerCategoryCard(title: "Logs", subtitle: "Not scanned", symbol: "doc.text")
                CleanerCategoryCard(title: "App leftovers", subtitle: "Not scanned", symbol: "folder.badge.questionmark")
            }

            NotePanel(
                symbol: "shield.lefthalf.filled",
                title: "Safety comes before space savings",
                message: "This preview has not scanned or changed any files. The intended cleaner is allowlist-based, excludes protected and active app data, checks resolved paths, previews each finding, and prefers moving reviewed items to Trash.",
                tint: AppTheme.success
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan and review")
                        .font(.system(size: 12, weight: .semibold))
                    Text("No unattended cleanup or scheduled deletion")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Scan locations") { }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .help("Available after the safe scanner is implemented")
            }
            .padding(17)
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
    }
}

private struct CleanerCategoryCard: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 11, weight: .medium))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}

struct PortsPage: View {
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "NETWORK DIAGNOSTICS",
                title: "Know what is using your ports",
                description: "Identify listening ports, associated processes, and process ownership before deciding what to do."
            )

            HStack(spacing: 12) {
                PortMetricCard(title: "Listening ports", value: "Not scanned", symbol: "point.3.connected.trianglepath.dotted")
                PortMetricCard(title: "Processes", value: "Not scanned", symbol: "cpu")
                PortMetricCard(title: "Permissions", value: "Not checked", symbol: "lock.shield")
            }

            VStack(spacing: 0) {
                HStack {
                    Text("PORT / ADDRESS")
                    Spacer()
                    Text("PROCESS").frame(width: 145, alignment: .leading)
                    Text("PID").frame(width: 75, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                Divider().overlay(AppTheme.separator)
                EmptyStateView(
                    symbol: "point.3.connected.trianglepath.dotted",
                    title: searchText.isEmpty ? "No scan has run" : "No process results",
                    message: "The port scanner is not connected in this preview. No processes have been inspected or terminated."
                )
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            NotePanel(
                symbol: "exclamationmark.triangle",
                title: "Process termination needs care",
                message: "The planned implementation will show PID, process name, and port in a confirmation, try graceful termination first, protect critical processes, and never silently elevate privileges.",
                tint: AppTheme.warning
            )
        }
    }
}

private struct PortMetricCard: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 34, height: 34)
                .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 12, weight: .semibold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}
