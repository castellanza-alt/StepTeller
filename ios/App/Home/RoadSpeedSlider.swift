import SwiftUI
import StepTellerCore

/// Cursore della velocità che scorre **sulla linea tratteggiata della strada** (`SpeedTrack.road`).
/// Vive nello spazio dell'illustrazione (390 × 790 pt). Si prende con un tocco o un trascinamento entro
/// 20 pt dal tracciato; il dito si proietta sul punto più vicino e la velocità va a scatti di 0,5.
struct RoadSpeedSlider: View {
    @Binding var speed: Double
    @Environment(\.manga) private var c
    private let track = SpeedTrack.road
    private let k = Manga.artScale

    var body: some View {
        let q = track.point(atFraction: SpeedTrack.fraction(forSpeed: speed))
        let p = CGPoint(x: q.x * k, y: q.y * k)
        let f = (speed - SpeedTrack.minSpeed) / (SpeedTrack.maxSpeed - SpeedTrack.minSpeed)
        let flip = p.x > Manga.knobFlipX
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(TrackHitShape(track: track, scale: k, width: 2 * Manga.trackTouchRadius))
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    let n = track.nearest(to: SpeedTrack.Point(v.location.x / k, v.location.y / k))
                    let new = SpeedTrack.speed(forFraction: n.fraction)
                    if new != speed { speed = new }
                })
            trail(at: p, f: f)
            knobAndLabel(flip: flip)
                .frame(width: 0, height: 0, alignment: flip ? .trailing : .leading)
                .offset(x: p.x + (flip ? Manga.knobSize / 2 : -Manga.knobSize / 2), y: p.y)
                .allowsHitTesting(false)
        }
        .sensoryFeedback(.selection, trigger: speed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Velocità")
        .accessibilityValue("\(ItalianFormat.number(speed, decimals: 1)) chilometri orari")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: speed = SpeedTrack.snap(speed + SpeedTrack.step)
            case .decrement: speed = SpeedTrack.snap(speed - SpeedTrack.step)
            @unknown default: break
            }
        }
    }

    // MARK: pallino e valore

    @ViewBuilder private func knobAndLabel(flip: Bool) -> some View {
        HStack(spacing: Manga.knobLabelGap) {
            if flip { label; knob } else { knob; label }
        }
    }

    private var knob: some View {
        ZStack {
            Circle().fill(MangaPalette.knobGlow)
                .frame(width: Manga.knobSize + 10, height: Manga.knobSize + 10)
                .blur(radius: 8)
            Circle()
                .fill(RedGradient.fill(red: c.red, center: UnitPoint(x: 0.35, y: 0.3),
                                       size: Manga.knobSize - 2 * Manga.knobBorder, mid: 0.45))
                .padding(Manga.knobBorder)
            Circle().strokeBorder(c.paper, lineWidth: Manga.knobBorder)
            Circle().strokeBorder(c.red, lineWidth: Manga.knobRing)
                .padding(-Manga.knobRing)
        }
        .frame(width: Manga.knobSize, height: Manga.knobSize)
    }

    private var label: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            AntonText(ItalianFormat.number(speed, decimals: 1), 26)
            AntonText("km/h", 15)
        }
        .shadow(color: c.paper, radius: 2)
        .shadow(color: c.paper, radius: 4)
        .shadow(color: c.paper, radius: 6)
        .manga(rotate: -4, skew: -8)
    }

    // MARK: scia

    /// Tre triangoli rastremati dietro il pallino, ruotati −8°: nero 4 pt, rosso 6 pt, nero 3 pt.
    /// Lunghezze: rosso 18 + f·120, neri 12 + f·90 (f = (v − 3) / 13).
    private func trail(at p: CGPoint, f: Double) -> some View {
        let black = (12 + f * 90).rounded(), red = (18 + f * 120).rounded()
        return ZStack(alignment: .topLeading) {
            streak(color: c.ink, length: black, height: 4, right: p.x - 10, top: p.y - 9)
            streak(color: c.red, length: red, height: 6, right: p.x - 12, top: p.y + 1)
            streak(color: c.ink, length: black, height: 3, right: p.x - 10, top: p.y + 10)
        }
        .allowsHitTesting(false)
    }

    private func streak(color: Color, length: CGFloat, height: CGFloat, right: CGFloat, top: CGFloat) -> some View {
        TrailTriangle()
            .fill(LinearGradient(colors: [color.opacity(0), color], startPoint: .leading, endPoint: .trailing))
            .frame(width: length, height: height)
            .rotationEffect(.degrees(-8), anchor: .trailing)
            .offset(x: right - length, y: top)
    }
}

/// `clip-path: polygon(0 50%, 100% 0, 100% 100%)`: punta a sinistra, base a destra.
private struct TrailTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Zona sensibile: il tracciato ingrossato di `width` pt (20 pt per lato).
private struct TrackHitShape: Shape {
    let track: SpeedTrack
    let scale: CGFloat
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addLines(track.samples.map { CGPoint(x: $0.x * scale, y: $0.y * scale) })
        return p.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
