import SwiftUI

struct InstalledPage: View {
    let searchText: String
    @State private var selectedFilter: InstalledFilter = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "PACKAGE LIBRARY",
                title: "Everything you have installed",
                description: "Browse formulae, casks, services, and GUI apps in one place. The live Homebrew connection is not enabled in this preview."
            )

            HStack(spacing: 12) {
                Picker("Package type", selection: $selectedFilter) {
                    ForEach(InstalledFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)
                Spacer()
                Text("No live data")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                HStack {
                    Text("PACKAGE")
                    Spacer()
                    Text("TYPE")
                        .frame(width: 100, alignment: .leading)
                    Text("VERSION")
                        .frame(width: 100, alignment: .leading)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)

                Divider().overlay(AppTheme.separator)

                EmptyStateView(
                    symbol: "shippingbox",
                    title: searchText.isEmpty ? "No packages loaded" : "No local matches yet",
                    message: searchText.isEmpty
                        ? "Connect Homebrew to see installed packages. This preview has not inspected your system."
                        : "Local package search will work once the Homebrew integration is connected. No command has been run."
                )
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            NotePanel(
                symbol: "info.circle",
                title: "Formulae and casks are different",
                message: "Formulae install command-line tools and libraries; casks commonly install GUI apps. Services are a management state, not a separate universal package type."
            )
        }
    }
}

private enum InstalledFilter: String, CaseIterable, Identifiable, Hashable {
    case all, formulae, casks, services, guiApps
    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .formulae: "Formulae"
        case .casks: "Casks"
        case .services: "Services"
        case .guiApps: "GUI apps"
        }
    }
}

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
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "MAINTENANCE",
                title: "Stay up to date",
                description: "Review outdated formulae and casks before choosing what to update."
            )

            HStack(spacing: 12) {
                UpdateSummaryCard(title: "Formulae", value: "Not checked", symbol: "terminal")
                UpdateSummaryCard(title: "Casks", value: "Not checked", symbol: "macwindow")
                UpdateSummaryCard(title: "Last check", value: "Never", symbol: "clock")
            }

            NotePanel(
                symbol: "arrow.triangle.2.circlepath",
                title: "Update checking is not connected yet",
                message: "This screen does not run `brew outdated` or `brew upgrade`. When enabled, BrewDesk will separate metadata refresh (`brew update`) from installing updates (`brew upgrade`) and show the exact command before changes."
            )

            HStack {
                Spacer()
                Button("Check for updates") { }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
                    .help("Available after the Homebrew process runner is implemented")
            }
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
