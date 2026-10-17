import SwiftUI

struct CleanerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "SPACE & HYGIENE",
                title: "Clean with confidence",
                description: "Review potential caches, logs, and application leftovers before taking action."
            )

            HStack(spacing: 12) {
                MetricCard(title: "Caches", value: "Not scanned", symbol: "archivebox")
                MetricCard(title: "Logs", value: "Not scanned", symbol: "doc.text")
                MetricCard(title: "App leftovers", value: "Not scanned", symbol: "folder.badge.questionmark")
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

typealias CleanerPage = CleanerView
