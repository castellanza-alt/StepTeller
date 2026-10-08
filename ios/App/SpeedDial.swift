import SwiftUI

/// Cursore 3–12 km/h con righello a tacche (una lunga per km/h intero, una corta a metà),
/// numeri sotto e cursore a barra verticale accent con alone. Passo 0,1.
struct SpeedDial: View {
    @Binding var speed: Double
    let range: ClosedRange<Double> = 3...12

    private let inset: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let track = w - 2 * inset
            ZStack(alignment: .topLeading) {
                // tacche
                Canvas { ctx, size in
                    for i in 0...18 {
                        let x = inset + track * CGFloat(i) / 18
                        let major = i % 2 == 0
                        let rect = CGRect(x: x - 0.5, y: major ? 8 : 14, width: 1, height: major ? 16 : 10)
                        ctx.fill(Path(rect), with: .color(major ? Theme.ink.opacity(0.5) : Theme.faint.opacity(0.5)))
                    }
                }
                .allowsHitTesting(false)

                // numeri
                ForEach(3...12, id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.soft)
                        .position(x: inset + track * CGFloat(n - 3) / 9, y: 48)
                }
                .allowsHitTesting(false)

                // cursore
                let x = inset + track * CGFloat((speed - range.lowerBound) / (range.upperBound - range.lowerBound))
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 28, height: 28)
                    Rectangle().fill(Theme.accent).frame(width: 3, height: 36)
                }
                .frame(width: 28, height: 36)
                .position(x: x, y: 18)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                let f = min(1, max(0, (drag.location.x - inset) / track))
                let v = (range.lowerBound + Double(f) * (range.upperBound - range.lowerBound)) * 10
                speed = v.rounded() / 10
            })
        }
        .frame(height: 54)
        .sensoryFeedback(.selection, trigger: Int(speed))      // tocco aptico a ogni km/h intero
        .accessibilityElement()
        .accessibilityLabel("Velocità")
        .accessibilityValue("\(ItalianFormatBridge.speed(speed)) chilometri orari")
        .accessibilityAdjustableAction { direction in
            let step = 0.1
            switch direction {
            case .increment: speed = min(range.upperBound, ((speed + step) * 10).rounded() / 10)
            case .decrement: speed = max(range.lowerBound, ((speed - step) * 10).rounded() / 10)
            @unknown default: break
            }
        }
    }
}
