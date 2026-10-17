import SwiftUI

struct InstalledView: View {
    let searchText: String
    @ObservedObject var homebrew: HomebrewStore
    @Binding var selectedFilter: InstalledFilter
    @State private var showDirectOnly = false
    @State private var refreshGeneration = 0
    @State private var hasCopiedCommand = false
    @State private var copiedServiceID: String?
    
    init(
        searchText: String,
        homebrew: HomebrewStore,
        selectedFilter: Binding<InstalledFilter> = .constant(.all)
    ) {
        self.searchText = searchText
        self.homebrew = homebrew
        self._selectedFilter = selectedFilter
    }
    
    private var currentBrewCommand: String {
        switch selectedFilter {
        case .services:
            return "brew services list"
        case .formulae:
            return showDirectOnly ? "brew leaves" : "brew list --formula"
        case .casks:
            return "brew list --cask"
        case .all:
            return showDirectOnly ? "brew leaves" : "brew list"
        }
    }
    
    private var filteredPackages: [HomebrewPackage] {
        homebrew.packages.filter { package in
            let matchesSearch = searchText.isEmpty || package.name.localizedStandardContains(searchText)
            let matchesDirect = !showDirectOnly || package.isDirect
            let matchesKind: Bool
            switch selectedFilter {
            case .all: matchesKind = true
            case .formulae: matchesKind = package.kind == .formula
            case .casks: matchesKind = package.kind == .cask
            case .services: matchesKind = false
            }
            return matchesSearch && matchesDirect && matchesKind
        }
    }
    
    private var filteredServices: [HomebrewService] {
        homebrew.services.filter { service in
            searchText.isEmpty || service.name.localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "PACKAGE LIBRARY",
                title: selectedFilter == .services ? "Background services" : "Everything you have installed",
                description: selectedFilter == .services
                ? "Manage background services configured through Homebrew. Start and stop services with a single click."
                : "Browse locally installed Homebrew formulae and casks. BrewDesk reads this information only when you open this screen or refresh it."
            )
            
            HStack(spacing: 12) {
                Picker("Package type", selection: $selectedFilter) {
                    ForEach(InstalledFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)
                
                if selectedFilter != .services {
                    Button {
                        showDirectOnly.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showDirectOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 12))
                            Text(showDirectOnly ? "Direct only" : "All packages")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(showDirectOnly ? AppTheme.accent : nil)
                    .help(Text(verbatim: showDirectOnly ? "Showing direct/top-level apps only. Click to view all packages including dependencies." : "Click to view direct apps instead of transitive dependencies."))
                }
                
                Spacer(minLength: 10)
                
                if homebrew.isLoadingPackages || homebrew.isLoadingServices {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Loading")
                }
                
                Button {
                    if ClipboardService.copy(currentBrewCommand) {
                        hasCopiedCommand = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopiedCommand = false
                        }
                    }
                } label: {
                    Image(systemName: hasCopiedCommand ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(hasCopiedCommand ? AppTheme.success : AppTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(hasCopiedCommand ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help(Text(verbatim: hasCopiedCommand ? "Copied!" : "Copy command: \(currentBrewCommand)"))
                
                Button {
                    refreshGeneration += 1
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(homebrew.isLoadingPackages || homebrew.isLoadingServices)
                .help(Text(verbatim: "Reload local package and service data"))
            }
            
            if let error = selectedFilter == .services ? homebrew.servicesError : homebrew.packagesError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: selectedFilter == .services ? "Could not load services" : "Could not load installed packages",
                    message: error,
                    tint: AppTheme.warning
                )
            }
            
            if selectedFilter == .services {
                servicesTable
            } else {
                packagesTable
            }
            
            
        }
        .task(id: refreshGeneration) {
            if selectedFilter == .services {
                await homebrew.loadServices()
            } else {
                await homebrew.loadInstalledPackages()
            }
        }
        .task(id: selectedFilter) {
            if selectedFilter == .services && !homebrew.hasLoadedServices {
                await homebrew.loadServices()
            } else if selectedFilter != .services && !homebrew.hasLoadedPackages {
                await homebrew.loadInstalledPackages()
            }
        }
        .onChange(of: selectedFilter) { _, newFilter in
            if newFilter == .services && !homebrew.hasLoadedServices {
                Task { await homebrew.loadServices() }
            } else if newFilter != .services && !homebrew.hasLoadedPackages {
                Task { await homebrew.loadInstalledPackages() }
            }
        }
    }
    
    private var packagesTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PACKAGE")
                Spacer(minLength: 12)
                Text("INSTALLATION").frame(width: 100, alignment: .leading)
                Text("TYPE").frame(width: 80, alignment: .leading)
                Text("VERSION").frame(width: 140, alignment: .leading)
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            
            Divider().overlay(AppTheme.separator)
            
            if homebrew.isLoadingPackages && homebrew.packages.isEmpty {
                EmptyStateView(
                    symbol: "hourglass",
                    title: "Loading installed packages",
                    message: "BrewDesk is reading Homebrew's local package list. No installation or update is being run."
                )
            } else if !homebrew.hasLoadedPackages && homebrew.packagesError == nil {
                EmptyStateView(
                    symbol: "shippingbox",
                    title: "Loading your package library",
                    message: "BrewDesk will query Homebrew when this screen opens. Use Refresh to retry if needed."
                )
            } else if filteredPackages.isEmpty {
                EmptyStateView(
                    symbol: searchText.isEmpty ? "shippingbox" : "magnifyingglass",
                    title: searchText.isEmpty ? "No packages found" : "No matching packages",
                    message: searchText.isEmpty
                    ? (showDirectOnly ? "No direct packages found. Try turning off 'Direct only' to see all dependencies." : "Homebrew returned no packages for this filter. Try another package type or refresh.")
                    : "No installed packages match “\(searchText)”. Clear the search field to see all results."
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredPackages) { package in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(package.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(package.kind == .formula ? "Command-line tool or library" : "Homebrew cask")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            
                            HStack {
                                if package.isDirect {
                                    Text("Direct")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(AppTheme.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.accent.opacity(0.12), in: Capsule())
                                } else {
                                    Text("Dependency")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.subtleFill, in: Capsule())
                                }
                            }
                            .frame(width: 100, alignment: .leading)
                            
                            Text(package.kind.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppTheme.subtleFill, in: Capsule())
                                .frame(width: 80, alignment: .leading)
                            
                            Text(package.versionLabel)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(width: 140, alignment: .leading)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        
                        if package.id != filteredPackages.last?.id {
                            Divider().overlay(AppTheme.separator.opacity(0.7))
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    private var servicesTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SERVICE")
                Spacer(minLength: 12)
                Text("STATUS").frame(width: 90, alignment: .leading)
                Text("COMMAND").frame(width: 80, alignment: .center)
                Text("ACTION").frame(width: 85, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            
            Divider().overlay(AppTheme.separator)
            
            if homebrew.isLoadingServices && homebrew.services.isEmpty {
                EmptyStateView(
                    symbol: "hourglass",
                    title: "Loading services",
                    message: "BrewDesk is running `brew services list` to discover registered services."
                )
            } else if filteredServices.isEmpty {
                EmptyStateView(
                    symbol: "gearshape.2",
                    title: searchText.isEmpty ? "No background services registered" : "No matching services",
                    message: searchText.isEmpty
                    ? "Homebrew has no services installed or running (such as redis or postgresql). Install service-capable formulae to manage them here."
                    : "No background services match “\(searchText)”."
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredServices) { service in
                        HStack(spacing: 12) {
                            Image(systemName: serviceIcon(for: service.name))
                                .font(.system(size: 13))
                                .foregroundStyle(service.status.isRunning ? AppTheme.success : .secondary)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(service.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if let user = service.user {
                                    Text("User: \(user)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                } else {
                                    Text("Homebrew background service")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer(minLength: 8)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(service.status.isRunning ? AppTheme.success : (service.status == .error ? AppTheme.warning : Color.secondary.opacity(0.4)))
                                    .frame(width: 6, height: 6)
                                Text(service.status.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(service.status.isRunning ? AppTheme.success : .secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(AppTheme.subtleFill, in: Capsule())
                            .frame(width: 90, alignment: .leading)
                            
                            let serviceCommand = service.status.isRunning
                            ? "brew services stop \(service.name)"
                            : "brew services start \(service.name)"
                            
                            Button {
                                if ClipboardService.copy(serviceCommand) {
                                    copiedServiceID = service.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if copiedServiceID == service.id {
                                            copiedServiceID = nil
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: copiedServiceID == service.id ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundStyle(copiedServiceID == service.id ? AppTheme.success : AppTheme.accent)
                                    .frame(width: 26, height: 26)
                                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(copiedServiceID == service.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(Text(verbatim: copiedServiceID == service.id ? "Copied!" : "Copy command: \(serviceCommand)"))
                            .frame(width: 80, alignment: .center)
                            
                            HStack {
                                if homebrew.mutatingService == service.name {
                                    ProgressView().controlSize(.small)
                                } else if service.status.isRunning {
                                    Button {
                                        Task { await homebrew.stopService(name: service.name) }
                                    } label: {
                                        Label("Stop", systemImage: "stop.fill")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(AppTheme.warning)
                                    .controlSize(.small)
                                } else {
                                    Button {
                                        Task { await homebrew.startService(name: service.name) }
                                    } label: {
                                        Label("Start", systemImage: "play.fill")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .frame(width: 85, alignment: .trailing)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        
                        if service.id != filteredServices.last?.id {
                            Divider().overlay(AppTheme.separator.opacity(0.7)).padding(.leading, 18)
                        }
                    }
                }
            }
        }
        .background(AppTheme.panel, in: AppTheme.cardShape)
        .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
    }
    
    private func serviceIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("redis") || lower.contains("memcached") {
            return "memorychip"
        } else if lower.contains("postgres") || lower.contains("mysql") || lower.contains("mariadb") || lower.contains("mongo") || lower.contains("sql") {
            return "cylinder"
        } else if lower.contains("nginx") || lower.contains("apache") || lower.contains("http") || lower.contains("caddy") {
            return "network"
        } else {
            return "gearshape.2"
        }
    }
}

enum InstalledFilter: String, CaseIterable, Identifiable, Hashable {
    case all, formulae, casks, services
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: "All"
        case .formulae: "Formulae"
        case .casks: "Casks"
        case .services: "Services"
        }
    }
}

typealias InstalledPage = InstalledView
