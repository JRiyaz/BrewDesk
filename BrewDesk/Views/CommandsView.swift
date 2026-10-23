import SwiftUI

struct CommandReference: Identifiable {
    let id: String
    let title: String
    let description: String
    let command: String
    let riskLabel: String
    let changesSystem: Bool
}

enum CommandCatalog {
    static let items: [CommandReference] = [
        .init(id: "version", title: "Homebrew version", description: "Show the installed Homebrew version.", command: "brew --version", riskLabel: "Read only", changesSystem: false),
        .init(id: "doctor", title: "Diagnostics", description: "Check the Homebrew environment for common issues.", command: "brew doctor", riskLabel: "Read only", changesSystem: false),
        .init(id: "search", title: "Search packages", description: "Search the catalogue for a formula or cask by name.", command: "brew search <name>", riskLabel: "Read only", changesSystem: false),
        .init(id: "info", title: "Package details", description: "Show metadata and dependencies for a package.", command: "brew info <formula-or-cask>", riskLabel: "Read only", changesSystem: false),
        .init(id: "list-formula", title: "List formulae", description: "List formulae currently installed by Homebrew.", command: "brew list --formula", riskLabel: "Read only", changesSystem: false),
        .init(id: "list-cask", title: "List casks", description: "List installed casks, commonly GUI applications.", command: "brew list --cask", riskLabel: "Read only", changesSystem: false),
        .init(id: "outdated", title: "Check outdated packages", description: "Report packages for which Homebrew lists an update.", command: "brew outdated --json=v2", riskLabel: "Read only", changesSystem: false),
        .init(id: "update", title: "Refresh package metadata", description: "Fetch the latest Homebrew package definitions. Does not itself upgrade installed packages.", command: "brew update", riskLabel: "Changes metadata", changesSystem: true),
        .init(id: "upgrade", title: "Upgrade packages", description: "Upgrade installed packages that have newer versions. Dependencies may also change.", command: "brew upgrade", riskLabel: "Changes system", changesSystem: true),
        .init(id: "uninstall", title: "Uninstall a package", description: "Uninstall a specific formula. Review dependencies and package type first.", command: "brew uninstall <formula>", riskLabel: "Destructive", changesSystem: true),
        .init(id: "cleanup", title: "Cleanup old versions", description: "Remove old versions and stale downloads managed by Homebrew.", command: "brew cleanup", riskLabel: "Destructive", changesSystem: true),
        .init(id: "services", title: "List Homebrew services", description: "Show service status supported by the installed Homebrew version.", command: "brew services list", riskLabel: "Read only", changesSystem: false)
    ]
}

struct CommandsView: View {
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
                description: "A curated Homebrew command catalogue. Copying only copies text; Purge never executes commands from this screen."
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

typealias CommandsPage = CommandsView
