import SwiftUI

/// Tappeto in vista laterale: stesse coordinate dei path SVG della web app (viewBox 360×200).
/// Il nastro ha un tratteggio animato (dash 2,5/11, periodo 13,5) la cui velocità segue `v/6`;
/// con obiettivo chiuso o «Riduci movimento» resta fermo.
struct TreadmillView: View {
    let speed: Double
    let moving: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = BeltClock()

    // Path del sorgente web, invariati.
    private static let frame = Path(svg: "M40 150 L290 140 C302 139.5 306 146 306 152 L306 154 C306 161 300 165 292 165 L48 168 C38 168.4 32 162 32 156 C32 152 36 150.2 40 150 Z")
    private static let belt = Path(svg: "M46 147.4 L286 137.8 L286.6 143.6 L46.6 153 Z")
    private static let run = Path(svg: "M282 139.2 L50 148.6")
    private static let frame2 = Path(svg: "M290 141 C300 140.6 304 146 304 152 L304 154 C304 160 299 163.6 292 163.8 L288 164 L288 141.2 Z")
    private static let post2 = Path(svg: "M268 141 C272 118 279 80 288 48")
    private static let post = Path(svg: "M282 140 C286 117 293 78 302 44")
    private static let rail = Path(svg: "M298 68 C268 68 240 72 232 80 C226 87 230 94 240 94 C258 93.5 276 93 293 92.5")
    private static let rail2 = Path(svg: "M285 70 C258 71 236 75 228 82 C223 88 226 95 234 95.5")

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !(moving && !reduceMotion))) { timeline in
            let phase = (moving && !reduceMotion) ? clock.phase(at: timeline.date, rate: speed / 6) : clock.frozenPhase
            Canvas { ctx, size in
                draw(&ctx, size: size, phase: phase)
            }
        }
        .aspectRatio(360.0 / 200.0, contentMode: .fit)
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, phase: Double) {
        let s = size.width / 360
        ctx.scaleBy(x: s, y: s)

        // ombra morbida e pavimento
        var shadow = ctx
        shadow.addFilter(.blur(radius: 6))
        shadow.fill(Path(ellipseIn: CGRect(x: 176 - 148, y: 176 - 7, width: 296, height: 14)), with: .color(Theme.mShadow))
        ctx.stroke(Path { $0.move(to: CGPoint(x: 10, y: 178)); $0.addLine(to: CGPoint(x: 350, y: 178)) },
                   with: .color(Theme.hair), lineWidth: 1)

        ctx.fill(Self.frame, with: .color(Theme.mFrame))
        ctx.fill(Self.belt, with: .color(Theme.mBelt))
        ctx.stroke(Self.run, with: .color(Theme.accent.opacity(0.95)),
                   style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [2.5, 11], dashPhase: phase * 13.5))
        ctx.fill(Self.frame2, with: .color(Theme.mFrame2))
        for c in [CGPoint(x: 46, y: 170), CGPoint(x: 268, y: 168)] {
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3.6, y: c.y - 3.6, width: 7.2, height: 7.2)), with: .color(Theme.mFrame2))
        }

        let thin = StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
        let thick = StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
        ctx.stroke(Self.post2, with: .color(Theme.mSoft), style: thin)
        ctx.stroke(Self.post, with: .color(Theme.mFrame), style: thick)

        // console, ruotata di −8° attorno a (300, 40)
        var console = ctx
        console.translateBy(x: 300, y: 40)
        console.rotate(by: .degrees(-8))
        console.translateBy(x: -300, y: -40)
        console.fill(Path(roundedRect: CGRect(x: 270, y: 33, width: 60, height: 13), cornerRadius: 6.5), with: .color(Theme.mFrame))
        console.fill(Path(roundedRect: CGRect(x: 277, y: 36.5, width: 46, height: 6), cornerRadius: 3), with: .color(Theme.accent.opacity(0.85)))

        ctx.stroke(Self.rail, with: .color(Theme.mFrame), style: thick)
        ctx.stroke(Self.rail2, with: .color(Theme.mSoft), style: thin)
    }
}

/// Accumula la fase del nastro in modo che un cambio di velocità non faccia «saltare» il tratteggio.
final class BeltClock {
    private var phaseValue = 0.0
    private var last: Date?
    private(set) var frozenPhase = 0.0

    /// Fase normalizzata 0…1 (un periodo = 1,1 s a velocità 6 km/h).
    func phase(at date: Date, rate: Double) -> Double {
        defer { last = date }
        if let last {
            let dt = min(0.25, max(0, date.timeIntervalSince(last)))
            phaseValue = (phaseValue + dt * rate / 1.1).truncatingRemainder(dividingBy: 1)
        }
        frozenPhase = phaseValue
        return phaseValue
    }
}
