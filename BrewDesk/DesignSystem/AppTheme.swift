import AppKit
import SwiftUI

enum AppTheme {
    static let accent = Color.accentColor
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let insetPanel = Color(nsColor: .underPageBackgroundColor)
    static let separator = Color.primary.opacity(0.08)
    static let subtleFill = Color.primary.opacity(0.035)
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    static let cardShape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    static let compactShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
}
