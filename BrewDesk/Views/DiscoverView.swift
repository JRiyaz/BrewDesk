import SwiftUI

struct DiscoverView: View {
    let searchText: String
    @ObservedObject var homebrew: HomebrewStore
    @State private var selectedKind: CatalogueKind = .formulae
    @State private var copiedResultID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "HOMEBREW CATALOGUE",
                title: "Find your next tool",
                description: "Search the official Homebrew catalogue for formulae and casks, inspect install commands, and install packages."
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

                if homebrew.isSearching {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("SEARCHING")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                } else if !searchText.isEmpty && !homebrew.searchResults.isEmpty {
                    StatusPill(
                        title: "\(homebrew.searchResults.count) FOUND",
                        symbol: "checkmark",
                        tint: AppTheme.success
                    )
                } else {
                    StatusPill(
                        title: "READY",
                        symbol: "magnifyingglass",
                        tint: .secondary
                    )
                }
            }

            if let error = homebrew.searchError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: "Catalogue search error",
                    message: error,
                    tint: AppTheme.warning
                )
            }

            VStack(spacing: 0) {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    EmptyStateView(
                        symbol: "sparkle.magnifyingglass",
                        title: "Search the catalogue",
                        message: "Enter a package or app name (e.g. “redis”, “git”, “docker”) in the search field above to query Homebrew."
                    )
                } else if homebrew.isSearching && homebrew.searchResults.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Searching Homebrew",
                        message: "Querying `brew search \(selectedKind == .formulae ? "--formula" : "--cask") \(searchText)`…"
                    )
                } else if homebrew.searchResults.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No packages found",
                        message: "Homebrew returned no \(selectedKind.title.lowercased()) matching “\(searchText)”. Try a different keyword."
                    )
                } else {
                    HStack {
                        Text("PACKAGE")
                        Spacer(minLength: 12)
                        Text("TYPE").frame(width: 80, alignment: .leading)
                        Text("STATUS").frame(width: 100, alignment: .leading)
                        Text("COMMAND").frame(width: 80, alignment: .center)
                        Text("ACTION").frame(width: 85, alignment: .trailing)
                    }
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)

                    Divider().overlay(AppTheme.separator)

                    LazyVStack(spacing: 0) {
                        ForEach(homebrew.searchResults) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(item.kind == .formula ? "Command-line formula" : "GUI cask application")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Text(item.kind.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.subtleFill, in: Capsule())
                                    .frame(width: 80, alignment: .leading)

                                HStack(spacing: 5) {
                                    if item.isInstalled {
                                        Circle()
                                            .fill(AppTheme.success)
                                            .frame(width: 6, height: 6)
                                        Text("Installed")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(AppTheme.success)
                                    } else if item.isDisabled {
                                        Circle()
                                            .fill(AppTheme.warning)
                                            .frame(width: 6, height: 6)
                                        Text("Disabled")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Circle()
                                            .fill(Color.secondary.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                        Text("Available")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppTheme.subtleFill, in: Capsule())
                                .frame(width: 100, alignment: .leading)

                                Button {
                                    if ClipboardService.copy(item.installCommand) {
                                        copiedResultID = item.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if copiedResultID == item.id {
                                                copiedResultID = nil
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: copiedResultID == item.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(copiedResultID == item.id ? AppTheme.success : AppTheme.accent)
                                        .frame(width: 26, height: 26)
                                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .strokeBorder(copiedResultID == item.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                                        )
                                }
                                .buttonStyle(.plain)
                                .help(Text(verbatim: copiedResultID == item.id ? "Copied!" : "Copy install command: \(item.installCommand)"))
                                .frame(width: 80, alignment: .center)

                                HStack {
                                    if homebrew.installingPackage == item.name {
                                        ProgressView().controlSize(.small)
                                    } else if item.isInstalled {
                                        Text("Installed")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(AppTheme.success)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                    } else {
                                        Button {
                                            Task { await homebrew.installPackage(name: item.name, kind: item.kind) }
                                        } label: {
                                            Label("Install", systemImage: "arrow.down")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        .disabled(homebrew.installingPackage != nil)
                                    }
                                }
                                .frame(width: 85, alignment: .trailing)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            if item.id != homebrew.searchResults.last?.id {
                                Divider().overlay(AppTheme.separator.opacity(0.7)).padding(.leading, 18)
                            }
                        }
                    }
                }
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
        .task(id: "\(searchText):\(selectedKind.rawValue)") {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return
            }
            // Debounce user typing by 250ms
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
            } catch {
                return
            }
            await homebrew.searchCatalogue(query: query, kind: selectedKind == .formulae ? .formula : .cask)
        }
    }
}

private enum CatalogueKind: String, CaseIterable, Identifiable, Hashable {
    case formulae, casks
    var id: String { rawValue }
    var title: String {
        switch self {
        case .formulae: "Formulae"
        case .casks: "Casks"
        }
    }
}

typealias DiscoverPage = DiscoverView
