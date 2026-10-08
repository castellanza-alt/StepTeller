import SwiftUI

/// Arco di 270° (apertura in basso) con avanzamento, come nel widget. A obiettivo chiuso diventa
/// un anello pieno. Il contenuto va sovrapposto da chi lo usa.
struct ArcGauge: View {
    let progress: Double
    let done: Bool
    var lineWidth: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = side / 2 - lineWidth / 2 - 2
            let line = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            ZStack {
                if done {
                    Circle().inset(by: lineWidth / 2 + 2).stroke(Theme.accent, style: line)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 6)
                } else {
                    Circle().inset(by: lineWidth / 2 + 2).trim(from: 0, to: 0.75)
                        .stroke(Theme.ink.opacity(0.10), style: line).rotationEffect(.degrees(135))
                    Circle().inset(by: lineWidth / 2 + 2).trim(from: 0, to: 0.75 * min(1, max(0, progress)))
                        .stroke(Theme.accent, style: line).rotationEffect(.degrees(135))
                        .shadow(color: Theme.accent.opacity(0.45), radius: 6)
                    let angle = (135 + 270 * min(1, max(0, progress))) * .pi / 180
                    Circle().fill(Theme.ink).frame(width: lineWidth + 4, height: lineWidth + 4)
                        .shadow(color: Theme.accent.opacity(0.8), radius: 5)
                        .offset(x: radius * cos(angle), y: radius * sin(angle))
                }
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
