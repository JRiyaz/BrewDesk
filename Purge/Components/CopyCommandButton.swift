import AppKit
import SwiftUI

struct CopyCommandButton: View {
    let command: String
    var title: String? = nil
    var size: CGFloat = 28
    
    @State private var isCopied = false
    
    var body: some View {
        Button {
            if ClipboardService.copy(command) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCopied = false
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCopied ? AppTheme.success : AppTheme.accent)
                
                if let title = title {
                    Text(isCopied ? "Copied!" : title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isCopied ? AppTheme.success : .secondary)
                }
            }
            .frame(height: size)
            .padding(.horizontal, title != nil ? 9 : 0)
            .frame(width: title == nil ? size : nil)
            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isCopied ? AppTheme.success.opacity(0.45) : AppTheme.separator, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .help("Copy command: \(command)")
    }
}
