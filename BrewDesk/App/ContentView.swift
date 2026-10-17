import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection = .overview
    @State private var searchText = ""
    @StateObject private var homebrew = HomebrewStore()

    var body: some View {
        NavigationSplitView {
            AppSidebar(selection: $selection)
        } detail: {
            VStack(spacing: 0) {
                AppHeader(
                    section: selection,
                    searchText: $searchText,
                    onOpenSettings: { selection = .settings }
                )

                Divider()
                    .overlay(AppTheme.separator)

                ScrollView {
                    pageContent
                        .frame(maxWidth: 1020, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 28)
                }
                .scrollIndicators(.visible)
                .background(AppTheme.canvas)
            }
            .background(AppTheme.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 980, minHeight: 680)
        .background(AppTheme.canvas)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selection {
        case .overview:
            OverviewView(onNavigate: navigate, homebrew: homebrew)
        case .installed:
            InstalledView(searchText: searchText, homebrew: homebrew)
        case .discover:
            DiscoverView(searchText: searchText)
        case .updates:
            UpdatesView(homebrew: homebrew)
        case .cleaner:
            CleanerView()
        case .ports:
            PortsView(searchText: searchText)
        case .commands:
            CommandsView(searchText: searchText)
        case .settings:
            SettingsView(homebrew: homebrew)
        }
    }

    private func navigate(to section: AppSection) {
        searchText = ""
        selection = section
    }
}

typealias MyApp = ContentView
