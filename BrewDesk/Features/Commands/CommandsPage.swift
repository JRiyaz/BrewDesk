import SwiftUI

struct CommandsPage: View {
    let searchText: String
    @State private var copiedCommandID: String?

    private var filteredCommands: [CommandReference] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return CommandCatalog.items }
        return CommandCatalog.items.filter { item in
            item.title.localizedCaseInsensitiveContains(query)
                || item.description.localizedCaseInsensitiveContains(query)
                || item.command.localizedCaseInsensitiveContains(query)
                || item.riskLabel.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "REFERENCE",
                title: "The right command, clearly explained",
                description: "A curated Homebrew command catalogue. Copying only copies text; BrewDesk never executes commands from this screen."
            )

            NotePanel(
                symbol: "doc.on.clipboard",
                title: "Preview before you act",
                message: "Commands that change system state are labeled. Replace placeholders such as `<formula>` with a package name and review the command before running it yourself.",
                tint: AppTheme.accent
            )

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
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(item.description)
                        .font(.system(size: 10))
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
