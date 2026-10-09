import SwiftUI

/// Arco di 270° (apertura in basso) con avanzamento, come nel widget. A obiettivo chiuso l'arco
/// arriva a fondo scala e si ferma lì: resta sempre un arco, mai un anello. Il contenuto va
/// sovrapposto da chi lo usa.
struct ArcGauge: View {
    let progress: Double
    var lineWidth: CGFloat = 7

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let p = min(1, max(0, progress))
            ZStack {
                ArcShape(progress: 1, lineWidth: lineWidth)
                    .stroke(Theme.ink.opacity(0.10), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                ArcShape(progress: p, lineWidth: lineWidth)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 6)
                ArcKnob(progress: p, lineWidth: lineWidth)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

/// Tratto di arco da 135° a 135° + 270°·progress; animabile.
struct ArcShape: Shape {
    var progress: Double
    var lineWidth: CGFloat
    var animatableData: Double { get { progress } set { progress = newValue } }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2 - 2
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius,
                    startAngle: .degrees(135), endAngle: .degrees(135 + 270 * progress), clockwise: false)
        return path
    }
}

/// Pallino in cima all'avanzamento; segue l'arco durante l'animazione.
private struct ArcKnob: View, Animatable {
    var progress: Double
    let lineWidth: CGFloat
    var animatableData: Double { get { progress } set { progress = newValue } }

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 - lineWidth / 2 - 2
            let angle = (135 + 270 * progress) * .pi / 180
            Circle().fill(Theme.ink).frame(width: lineWidth + 4, height: lineWidth + 4)
                .shadow(color: Theme.accent.opacity(0.8), radius: 5)
                .position(x: geo.size.width / 2 + radius * cos(angle), y: geo.size.height / 2 + radius * sin(angle))
        }
    }
}
