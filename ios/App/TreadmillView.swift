import SwiftUI

/// Foto del tappeto di Will (Technogym MyRun), con sfondo rimosso, e sopra un nastro animato:
/// tratteggi trasversali accent che scorrono sul piano di corsa a velocità `v/6`.
/// Con obiettivo chiuso o «Riduci movimento» il nastro resta fermo.
struct TreadmillView: View {
    let speed: Double
    let moving: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = BeltClock()

    /// Dimensione della foto ritagliata (pixel): le coordinate sotto sono in questo spazio.
    private static let imageSize = CGSize(width: 843, height: 717)
    /// Angoli del nastro nella foto: dietro-sinistra, dietro-destra, davanti-destra, davanti-sinistra.
    private static let belt: [CGPoint] = [
        CGPoint(x: 150, y: 548), CGPoint(x: 585, y: 447), CGPoint(x: 705, y: 487), CGPoint(x: 225, y: 592)
    ]
    private static let stripes = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !(moving && !reduceMotion))) { timeline in
            let phase = (moving && !reduceMotion) ? clock.phase(at: timeline.date, rate: speed / 6) : clock.frozenPhase
            ZStack {
                Image("Treadmill")
                    .resizable().scaledToFit()
                Canvas { ctx, size in
                    drawBelt(&ctx, size: size, phase: phase)
                }
            }
        }
        .aspectRatio(Self.imageSize.width / Self.imageSize.height, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func drawBelt(_ ctx: inout GraphicsContext, size: CGSize, phase: Double) {
        let s = size.width / Self.imageSize.width
        let p = Self.belt.map { CGPoint(x: $0.x * s, y: $0.y * s) }
        func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        // le linee scorrono dalla console verso l'utente (da destra a sinistra)
        for i in 0..<Self.stripes {
            let t = (Double(i) + (1 - phase)).truncatingRemainder(dividingBy: Double(Self.stripes)) / Double(Self.stripes)
            let a = lerp(p[0], p[1], t), b = lerp(p[3], p[2], t)
            // dissolvenza ai bordi del nastro
            let fade = min(1, min(t, 1 - t) * 8)
            var line = Path(); line.move(to: a); line.addLine(to: b)
            ctx.stroke(line, with: .color(Theme.accent.opacity(0.55 * fade)),
                       style: StrokeStyle(lineWidth: 1.6 * s * 1.6, lineCap: .round, dash: [5 * s, 9 * s]))
        }
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
