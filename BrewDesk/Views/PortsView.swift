import SwiftUI

struct PortsView: View {
    let searchText: String
    @StateObject private var scanner = PortScannerService()
    @State private var selectedFilter: PortFilter = .all
    @State private var copiedID: String?
    @State private var hasCopiedLsofCommand = false
    @State private var processToTerminate: ListeningPort?

    private var currentLsofCommand: String {
        "/usr/sbin/lsof -iTCP -sTCP:LISTEN -n -P"
    }

    private var filteredPorts: [ListeningPort] {
        scanner.ports.filter { item in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .custom: matchesFilter = item.isCustom
            case .system: matchesFilter = !item.isCustom
            }

            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let term = searchText.lowercased()
                matchesSearch = "\(item.port)".contains(term) ||
                    item.processName.lowercased().contains(term) ||
                    item.friendlyDescription.lowercased().contains(term) ||
                    "\(item.pid)".contains(term)
            }

            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "NETWORK DIAGNOSTICS",
                title: "Know what is using your ports",
                description: "Inspect active listening TCP ports on your Mac. Differentiate your custom apps (Angular, Flask, Vite, Node, etc.) from macOS system daemons."
            )

            HStack(spacing: 12) {
                MetricCard(
                    title: "Total listening",
                    value: scanner.lastScannedAt != nil ? "\(scanner.ports.count) ports" : "Not scanned",
                    symbol: "point.3.connected.trianglepath.dotted"
                )
                MetricCard(
                    title: "Custom / Dev apps",
                    value: scanner.lastScannedAt != nil ? "\(scanner.customCount) active" : "Not scanned",
                    detail: "Angular, Flask, Node, Python, Vite, etc.",
                    symbol: "chevron.left.forwardslash.chevron.right",
                    tint: AppTheme.accent
                )
                MetricCard(
                    title: "System daemons",
                    value: scanner.lastScannedAt != nil ? "\(scanner.systemCount) active" : "Not scanned",
                    detail: "Protected macOS background services",
                    symbol: "shield.checkered",
                    tint: .secondary
                )
            }

            HStack(spacing: 12) {
                Picker("Port filter", selection: $selectedFilter) {
                    ForEach(PortFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)

                Spacer()

                if scanner.isScanning {
                    ProgressView().controlSize(.small)
                }

                Button {
                    if ClipboardService.copy(currentLsofCommand) {
                        hasCopiedLsofCommand = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopiedLsofCommand = false
                        }
                    }
                } label: {
                    Image(systemName: hasCopiedLsofCommand ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(hasCopiedLsofCommand ? AppTheme.success : AppTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(hasCopiedLsofCommand ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help(Text(verbatim: hasCopiedLsofCommand ? "Copied!" : "Copy command: \(currentLsofCommand)"))

                Button {
                    Task { await scanner.scanPorts() }
                } label: {
                    Label(scanner.isScanning ? "Scanning…" : "Scan ports", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(scanner.isScanning)
                .help(Text(verbatim: "Refresh list of active listening ports"))
            }

            if let error = scanner.scanError {
                NotePanel(
                    symbol: "exclamationmark.triangle",
                    title: "Could not scan ports",
                    message: error,
                    tint: AppTheme.warning
                )
            }

            VStack(spacing: 0) {
                HStack {
                    Text("PORT / ADDRESS").frame(width: 140, alignment: .leading)
                    Text("PROCESS")
                    Spacer(minLength: 12)
                    Text("TYPE").frame(width: 110, alignment: .leading)
                    Text("PID").frame(width: 65, alignment: .leading)
                    Text("COMMAND").frame(width: 80, alignment: .center)
                    Text("ACTION").frame(width: 85, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)

                Divider().overlay(AppTheme.separator)

                if scanner.isScanning && scanner.ports.isEmpty {
                    EmptyStateView(
                        symbol: "hourglass",
                        title: "Scanning listening ports",
                        message: "BrewDesk is inspecting open network sockets with `lsof`."
                    )
                } else if filteredPorts.isEmpty {
                    EmptyStateView(
                        symbol: searchText.isEmpty ? "point.3.connected.trianglepath.dotted" : "magnifyingglass",
                        title: searchText.isEmpty ? "No active ports found" : "No matching ports",
                        message: searchText.isEmpty
                            ? "No listening ports found matching '\(selectedFilter.rawValue)'."
                            : "No open ports match “\(searchText)”."
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPorts) { item in
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Text("\(item.port)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(item.isCustom ? AppTheme.accent : .primary)
                                    Text("(\(item.portAddress))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                                .frame(width: 140, alignment: .leading)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.processName)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(item.friendlyDescription)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }

                                Spacer(minLength: 8)

                                Text(item.typeTitle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(item.isCustom ? AppTheme.accent : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(item.isCustom ? AppTheme.accent.opacity(0.1) : AppTheme.subtleFill, in: Capsule())
                                    .frame(width: 110, alignment: .leading)

                                Text("\(item.pid)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 65, alignment: .leading)

                                Button {
                                    if ClipboardService.copy(item.killCommand) {
                                        copiedID = item.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if copiedID == item.id {
                                                copiedID = nil
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: copiedID == item.id ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundStyle(copiedID == item.id ? AppTheme.success : AppTheme.accent)
                                        .frame(width: 26, height: 26)
                                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .strokeBorder(copiedID == item.id ? AppTheme.success.opacity(0.4) : AppTheme.separator, lineWidth: 0.8)
                                        )
                                }
                                .buttonStyle(.plain)
                                .help(Text(verbatim: copiedID == item.id ? "Copied!" : "Copy terminate command: \(item.killCommand)"))
                                .frame(width: 80, alignment: .center)

                                HStack {
                                    if scanner.terminatingPID == item.pid {
                                        ProgressView().controlSize(.small)
                                    } else if item.isCustom {
                                        Button {
                                            processToTerminate = item
                                        } label: {
                                            Label("Stop", systemImage: "xmark.circle")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(AppTheme.warning)
                                        .controlSize(.small)
                                        .help(Text(verbatim: "Terminate \(item.processName) (PID \(item.pid))"))
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 8))
                                            Text("Protected")
                                                .font(.system(size: 10))
                                        }
                                        .foregroundStyle(.tertiary)
                                    }
                                }
                                .frame(width: 85, alignment: .trailing)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            if item.id != filteredPorts.last?.id {
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
            if scanner.ports.isEmpty {
                await scanner.scanPorts()
            }
        }
        .confirmationDialog(
            "Terminate Process",
            isPresented: Binding(
                get: { processToTerminate != nil },
                set: { if !$0 { processToTerminate = nil } }
            ),
            presenting: processToTerminate
        ) { target in
            Button("Stop \(target.processName) (Port \(target.port))", role: .destructive) {
                Task {
                    _ = await scanner.terminate(port: target)
                    processToTerminate = nil
                }
            }
            Button("Cancel", role: .cancel) {
                processToTerminate = nil
            }
        } message: { target in
            Text("Are you sure you want to stop \(target.processName) (PID: \(target.pid)) listening on port \(target.port)? This will close the application.")
        }
    }
}

typealias PortsPage = PortsView
