import AppKit
import SwiftUI

struct OverviewPage: View {
    let onNavigate: (AppSection) -> Void
    @ObservedObject var homebrew: HomebrewStore
    @AppStorage("customHomebrewPath") private var customHomebrewPath = ""
    @State private var checkGeneration = 0

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let featureColumns = [GridItem(.adaptive(minimum: 175), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 27) {
            welcomeCard

            if let error = homebrew.installationError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: "Homebrew wasn't detected",
                    message: "\(error) Open Settings to verify or configure the Homebrew executable path.",
                    tint: AppTheme.warning
                )
            }

            LazyVGrid(columns: columns, spacing: 12) {
                OverviewStatusCard(
                    title: "Homebrew",
                    value: homebrewStatus,
                    detail: homebrew.installation?.prefix ?? "Checks a local executable only",
                    symbol: "shippingbox",
                    statusSymbol: homebrew.installation != nil ? "checkmark.circle.fill" : (homebrew.isCheckingInstallation ? "hourglass" : "circle.dashed")
                )
                OverviewStatusCard(
                    title: "Installed packages",
                    value: homebrew.hasLoadedPackages ? "\(homebrew.packages.count)" : "Not loaded",
                    detail: homebrew.hasLoadedPackages ? "\(homebrew.formulaCount) formulae · \(homebrew.caskCount) casks" : "Open Installed to load local packages",
                    symbol: "square.stack.3d.up",
                    statusSymbol: homebrew.hasLoadedPackages ? "checkmark.circle.fill" : "tray"
                )
                OverviewStatusCard(
                    title: "Available updates",
                    value: updatesStatus,
                    detail: updatesDetail,
                    symbol: "arrow.triangle.2.circlepath",
                    statusSymbol: updatesStatusSymbol
                )
            }

            VStack(alignment: .leading, spacing: 13) {
                SectionCaption(title: "Your toolkit", trailing: "6 tools")
                LazyVGrid(columns: featureColumns, alignment: .leading, spacing: 12) {
                    FeatureTile(section: .installed, detail: "Browse formulae and casks installed locally") { onNavigate(.installed) }
                    FeatureTile(section: .discover, detail: "Search the online Homebrew catalogue") { onNavigate(.discover) }
                    FeatureTile(section: .updates, detail: "Review pending package updates") { onNavigate(.updates) }
                    FeatureTile(section: .cleaner, detail: "Review caches and leftovers safely") { onNavigate(.cleaner) }
                    FeatureTile(section: .ports, detail: "Inspect listening ports and owners") { onNavigate(.ports) }
                    FeatureTile(section: .commands, detail: "Browse and copy common commands") { onNavigate(.commands) }
                }
            }

            VStack(alignment: .leading, spacing: 13) {
                SectionCaption(title: "Recent activity", trailing: "This session")
                HStack(spacing: 14) {
                    Image(systemName: homebrew.installation == nil ? "clock.arrow.circlepath" : "checkmark.circle")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(homebrew.installation == nil ? Color.secondary : AppTheme.success)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(homebrew.installation?.version ?? (homebrew.installationError == nil ? "Ready to check Homebrew" : "Homebrew needs attention"))
                            .font(.system(size: 12, weight: .semibold))
                        Text(homebrew.installation?.executablePath ?? "Only a user-triggered local version check runs here; no recurring refresh is scheduled.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            }
        }
        .task(id: checkGeneration) {
            if checkGeneration > 0 || (homebrew.installation == nil && homebrew.installationError == nil) {
                await homebrew.checkInstallation(customPath: customHomebrewPath)
            }
        }
    }

    private var homebrewStatus: String {
        if homebrew.isCheckingInstallation { return "Checking…" }
        if let installation = homebrew.installation { return installation.version }
        if homebrew.installationError != nil { return "Not found" }
        return "Not checked"
    }

    private var updatesStatus: String {
        if homebrew.isCheckingUpdates { return "Checking…" }
        if homebrew.hasCheckedUpdates {
            return homebrew.outdatedPackages.isEmpty ? "Up to date" : "\(homebrew.outdatedPackages.count)"
        }
        return "Not checked"
    }

    private var updatesDetail: String {
        if homebrew.hasCheckedUpdates {
            if homebrew.outdatedPackages.isEmpty {
                return "All packages are on latest versions"
            }
            let formulaCount = homebrew.outdatedPackages.filter { $0.kind == .formula }.count
            let caskCount = homebrew.outdatedPackages.filter { $0.kind == .cask }.count
            return "\(formulaCount) formulae · \(caskCount) casks"
        }
        return "Open Updates to check for pending updates"
    }

    private var updatesStatusSymbol: String {
        if homebrew.isCheckingUpdates { return "hourglass" }
        if homebrew.hasCheckedUpdates {
            return homebrew.outdatedPackages.isEmpty ? "checkmark.circle.fill" : "arrow.up.circle.fill"
        }
        return "clock"
    }

    private var welcomeCard: some View {
        HStack(alignment: .center, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                StatusPill(
                    title: homebrew.installation == nil ? "LOCAL SYSTEM STATUS" : "HOMEBREW CONNECTED",
                    symbol: homebrew.installation == nil ? "desktopcomputer" : "checkmark.circle.fill",
                    tint: homebrew.installation == nil ? AppTheme.accent : AppTheme.success
                )

                Text("Your Mac,\nneatly managed.")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A focused home for Homebrew and everyday system utilities.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 390, alignment: .leading)

                HStack(spacing: 9) {
                    Button {
                        checkGeneration += 1
                    } label: {
                        Label(homebrew.isCheckingInstallation ? "Checking…" : "Check Homebrew", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(homebrew.isCheckingInstallation)

                    Button {
                        onNavigate(.settings)
                    } label: {
                        Text("Settings")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer(minLength: 0)

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 230, alignment: .leading)
        .background {
            AppTheme.cardShape.fill(
                LinearGradient(
                    colors: [AppTheme.accent.opacity(0.10), AppTheme.accent.opacity(0.025), AppTheme.panel.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .glassEffect(.regular, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.accent.opacity(0.12), lineWidth: 0.8))
    }
}

private struct OverviewStatusCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let statusSymbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Image(systemName: statusSymbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}
