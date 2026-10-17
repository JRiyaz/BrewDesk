import SwiftUI

struct PortsView: View {
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageIntro(
                eyebrow: "NETWORK DIAGNOSTICS",
                title: "Know what is using your ports",
                description: "Identify listening ports, associated processes, and process ownership before deciding what to do."
            )

            HStack(spacing: 12) {
                MetricCard(title: "Listening ports", value: "Not scanned", symbol: "point.3.connected.trianglepath.dotted")
                MetricCard(title: "Processes", value: "Not scanned", symbol: "cpu")
                MetricCard(title: "Permissions", value: "Not checked", symbol: "lock.shield")
            }

            VStack(spacing: 0) {
                HStack {
                    Text("PORT / ADDRESS")
                    Spacer()
                    Text("PROCESS").frame(width: 145, alignment: .leading)
                    Text("PID").frame(width: 75, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                Divider().overlay(AppTheme.separator)
                EmptyStateView(
                    symbol: "point.3.connected.trianglepath.dotted",
                    title: searchText.isEmpty ? "No scan has run" : "No process results",
                    message: "The port scanner is not connected in this preview. No processes have been inspected or terminated."
                )
            }
            .background(AppTheme.panel, in: AppTheme.cardShape)
            .overlay(AppTheme.cardShape.strokeBorder(AppTheme.separator, lineWidth: 0.8))

            NotePanel(
                symbol: "exclamationmark.triangle",
                title: "Process termination needs care",
                message: "The planned implementation will show PID, process name, and port in a confirmation, try graceful termination first, protect critical processes, and never silently elevate privileges.",
                tint: AppTheme.warning
            )
        }
    }
}

typealias PortsPage = PortsView
