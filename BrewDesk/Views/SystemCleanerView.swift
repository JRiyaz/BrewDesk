import SwiftUI

struct SystemCleanerView: View {
    let searchText: String
    @StateObject private var systemCleaner = SystemCleanerService()
    @State private var selectedFilter: FilterType = .all
    @State private var categoryToClean: SystemCleanCategory?
    @State private var copiedCategoryID: String?

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case developer = "Developer"
        case system = "System"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "MAC STORAGE HYGIENE",
                title: "System Cleaner",
                description: "Reclaim gigabytes of disk space across Xcode DerivedData, build caches, application logs, and the macOS Trash."
            )

            // Top Metrics
            HStack(spacing: 12) {
                MetricCard(
                    title: "Reclaimable Space",
                    value: systemCleaner.lastScannedAt != nil ? systemCleaner.totalReclaimableFormatted : "Scanning…",
                    detail: "\(systemCleaner.categories.filter { $0.exists && $0.sizeBytes > 0 }.count) cleanable locations detected",
                    symbol: "internaldrive",
                    tint: systemCleaner.totalReclaimableBytes > 0 ? AppTheme.accent : AppTheme.success
                )

                MetricCard(
                    title: "Developer Caches",
                    value: developerCachesFormatted,
                    detail: "Xcode DerivedData, SwiftPM, NPM",
                    symbol: "hammer",
                    tint: AppTheme.accent
                )

                MetricCard(
                    title: "System Caches & Logs",
                    value: systemCachesFormatted,
                    detail: "macOS Trash, user caches & logs",
                    symbol: "trash",
                    tint: .secondary
                )
            }

            // Action & Filter Bar
            HStack(spacing: 12) {
                // Segmented Filter
                HStack(spacing: 4) {
                    ForEach(FilterType.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: selectedFilter == filter ? .semibold : .medium))
                                .foregroundStyle(selectedFilter == filter ? .primary : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    if selectedFilter == filter {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(AppTheme.subtleFill)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(AppTheme.separator, lineWidth: 0.8))

                if systemCleaner.isScanning || systemCleaner.isCleaning {
                    ProgressView().controlSize(.small)
                    Text(systemCleaner.isCleaning ? "Cleaning files…" : "Scanning directories…")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Scan / Refresh Button
                Button {
                    Task {
                        await systemCleaner.scanAll()
                    }
                } label: {
                    Label(systemCleaner.isScanning ? "Scanning…" : "Scan System", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(systemCleaner.isScanning || systemCleaner.isCleaning)
                .help(Text(verbatim: "Scan system cache and developer directories"))
            }

            if let message = systemCleaner.message {
                NotePanel(
                    symbol: "info.circle",
                    title: "Notice",
                    message: message,
                    tint: AppTheme.accent
                )
            }

            // Categories Table
            VStack(spacing: 0) {
                HStack {
                    Text("LOCATION / CACHE")
                    Spacer(minLength: 12)
                    Text("CATEGORY").frame(width: 110, alignment: .leading)
                    Text("EST. SIZE").frame(width: 90, alignment: .leading)
                    Text("ACTION").frame(width: 80, alignment: .center)
                    Text("COMMAND").frame(width: 80, alignment: .center)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)

                Divider().overlay(AppTheme.separator)

                if filteredCategories.isEmpty {
                    EmptyStateView(
                        symbol: "sparkles",
                        title: "No Matching Categories",
                        message: "Try clearing your search query or switching filters."
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCategories) { cat in
                            categoryRow(cat)

                            if cat.id != filteredCategories.last?.id {
                                Divider().overlay(AppTheme.separator.opacity(0.7)).padding(.leading, 18)
                            }
                        }
                    }
                }
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))
        }
        .task {
            await systemCleaner.scanAll()
        }
        .confirmationDialog(
            "Clean \(categoryToClean?.name ?? "Cache")?",
            isPresented: Binding(
                get: { categoryToClean != nil },
                set: { if !$0 { categoryToClean = nil } }
            ),
            presenting: categoryToClean
        ) { target in
            Button("Clean \(target.name)", role: .destructive) {
                Task {
                    _ = await systemCleaner.cleanCategory(target)
                    categoryToClean = nil
                }
            }
            Button("Cancel", role: .cancel) {
                categoryToClean = nil
            }
        } message: { target in
            Text("BrewDesk will remove temporary files in \(target.path). Applications will recreate any required cache files automatically.")
        }
    }

    private func categoryRow(_ cat: SystemCleanCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: cat.symbol)
                .font(.system(size: 14))
                .foregroundStyle(cat.sizeBytes > 0 ? AppTheme.accent : .secondary)
                .frame(width: 28, height: 28)
                .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(cat.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(cat.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(cat.isDeveloperFocused ? "Developer" : "System")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.subtleFill, in: Capsule())
                .frame(width: 110, alignment: .leading)

            Text(cat.sizeFormatted)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(cat.sizeBytes > 0 ? AppTheme.accent : .secondary)
                .frame(width: 90, alignment: .leading)

            // Clean button
            Button {
                categoryToClean = cat
            } label: {
                Text("Clean")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(cat.sizeBytes == 0 || systemCleaner.isCleaning || systemCleaner.isScanning)
            .frame(width: 80, alignment: .center)

            // Copy command button
            Button {
                if ClipboardService.copy(cat.cleanCommand) {
                    copiedCategoryID = cat.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedCategoryID == cat.id {
                            copiedCategoryID = nil
                        }
                    }
                }
            } label: {
                Image(systemName: copiedCategoryID == cat.id ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(copiedCategoryID == cat.id ? AppTheme.success : AppTheme.accent)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(copiedCategoryID == cat.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .help(Text(verbatim: copiedCategoryID == cat.id ? "Copied!" : "Copy command: \(cat.cleanCommand)"))
            .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var filteredCategories: [SystemCleanCategory] {
        systemCleaner.categories.filter { cat in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .developer: matchesFilter = cat.isDeveloperFocused
            case .system: matchesFilter = !cat.isDeveloperFocused
            }

            guard matchesFilter else { return false }

            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }

            return cat.name.localizedCaseInsensitiveContains(trimmed) ||
                cat.path.localizedCaseInsensitiveContains(trimmed) ||
                cat.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var developerCachesFormatted: String {
        let bytes = systemCleaner.categories.filter { $0.isDeveloperFocused }.reduce(0) { $0 + $1.sizeBytes }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private var systemCachesFormatted: String {
        let bytes = systemCleaner.categories.filter { !$0.isDeveloperFocused }.reduce(0) { $0 + $1.sizeBytes }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
