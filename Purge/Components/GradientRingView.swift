import SwiftUI

struct GradientRingView<CenterContent: View>: View {
    let value: Double
    var size: CGFloat = 110
    var strokeWidth: CGFloat = 8
    var gradient: [Color]
    var trackColor: Color = Color.primary.opacity(0.08)
    @ViewBuilder var centerContent: () -> CenterContent
    
    var body: some View {
        let clamped = min(max(value, 0.0), 100.0)
        let pct = clamped / 100.0
        
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            
            Circle()
                .trim(from: 0.001, to: max(pct, 0.001))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient.count > 1 ? gradient : [gradient.first ?? .blue, gradient.first ?? .blue]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.78), value: value)
            
            centerContent()
        }
        .frame(width: size, height: size)
    }
}
