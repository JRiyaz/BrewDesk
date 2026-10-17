import SwiftUI

struct UpdatesView: View {
    @ObservedObject var homebrew: HomebrewStore
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
                MetricCard(
                    title: "Formulae",
                    value: homebrew.hasCheckedUpdates ? (formulaOutdatedCount == 0 ? "Up to date" : "\(formulaOutdatedCount) available") : "Not checked",
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
                if homebrew.isCheckingUpdates {
                    ProgressView().controlSize(.small)
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
                        Task { await homebrew.upgradeAll() }
                    } label: {
                        HStack(spacing: 6) {
                            if homebrew.isUpgradingAll {
                                ProgressView().controlSize(.small)
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
                    Text("TYPE").frame(width: 80, alignment: .leading)
                    Text("CURRENT").frame(width: 120, alignment: .leading)
                    Text("LATEST").frame(width: 120, alignment: .leading)
                    Text("ACTION").frame(width: 90, alignment: .trailing)
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
                                .frame(width: 90, alignment: .trailing)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            if package.id != homebrew.outdatedPackages.last?.id {
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
