import SwiftUI

struct OverviewPage: View {
    let onNavigate: (AppSection) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let featureColumns = [GridItem(.adaptive(minimum: 175), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 27) {
            welcomeCard

            LazyVGrid(columns: columns, spacing: 12) {
                OverviewStatusCard(
                    title: "Homebrew",
                    value: "Not checked",
                    detail: "Detection is not active yet",
                    symbol: "shippingbox",
                    statusSymbol: "circle.dashed"
                )
                OverviewStatusCard(
                    title: "Installed packages",
                    value: "Not loaded",
                    detail: "Formulae and casks",
                    symbol: "square.stack.3d.up",
                    statusSymbol: "tray"
                )
                OverviewStatusCard(
                    title: "Available updates",
                    value: "Not checked",
                    detail: "No update scan has run",
                    symbol: "arrow.triangle.2.circlepath",
                    statusSymbol: "clock"
                )
            }

            VStack(alignment: .leading, spacing: 13) {
                SectionCaption(title: "Your toolkit", trailing: "6 tools")
                LazyVGrid(columns: featureColumns, alignment: .leading, spacing: 12) {
                    FeatureTile(section: .installed, detail: "Browse formulae, casks, and services") { onNavigate(.installed) }
                    FeatureTile(section: .discover, detail: "Search Homebrew packages") { onNavigate(.discover) }
                    FeatureTile(section: .updates, detail: "Review pending package updates") { onNavigate(.updates) }
                    FeatureTile(section: .cleaner, detail: "Review caches and leftovers safely") { onNavigate(.cleaner) }
                    FeatureTile(section: .ports, detail: "Inspect listening ports and owners") { onNavigate(.ports) }
                    FeatureTile(section: .commands, detail: "Browse and copy common commands") { onNavigate(.commands) }
                }
            }

            VStack(alignment: .leading, spacing: 13) {
                SectionCaption(title: "Recent activity", trailing: "This session")
                HStack(spacing: 14) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A quiet start")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Actions and results will appear here when integrations are added.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(AppTheme.panel, in: AppTheme.cardShape)
                .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(AppTheme.success)
                Text("Local-first by design")
                    .fontWeight(.semibold)
                Text("•  No background agent or scheduled jobs")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
        }
    }

    private var welcomeCard: some View {
        HStack(alignment: .center, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                StatusPill(title: "DESIGN PREVIEW", symbol: "sparkles", tint: AppTheme.accent)

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

                Button {
                    onNavigate(.settings)
                } label: {
                    HStack(spacing: 8) {
                        Text("Personalize BrewDesk")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.07))
                    .frame(width: 170, height: 170)
                Circle()
                    .strokeBorder(AppTheme.accent.opacity(0.12), lineWidth: 1)
                    .frame(width: 136, height: 136)
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 62, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.accent)
                    .rotationEffect(.degrees(-6))
            }
            .frame(width: 190, height: 190)
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
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
}
