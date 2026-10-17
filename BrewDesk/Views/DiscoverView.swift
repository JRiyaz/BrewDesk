import SwiftUI

struct DiscoverView: View {
    let searchText: String
    @State private var selectedKind: CatalogueKind = .formulae

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "HOMEBREW CATALOGUE",
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
        case .formulae: "Formulae"
        case .casks: "Casks"
        }
    }
}

typealias DiscoverPage = DiscoverView
