import SwiftUI
import StepTellerCore

/// Speed slider running **on the dashed line of the road** (`SpeedTrack.road`).
/// Lives in the illustration space (390 × 790 pt). Grabbed with a tap or a drag within
/// 20 pt of the path; the finger is projected onto the nearest point and the speed snaps to 0.5.
/// Same road in both units: 3–16 km/h or 2–10 mph; `speed` stays in km/h.
struct RoadSpeedSlider: View {
    @Binding var speed: Double
    let unit: DistanceUnit
    @Environment(\.manga) private var c
    private let track = SpeedTrack.road
    private let k = Manga.artScale

    var body: some View {
        let f = unit.fraction(forKmh: speed)
        let q = track.point(atFraction: f)
        let p = CGPoint(x: q.x * k, y: q.y * k)
        let flip = p.x > Manga.knobFlipX
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(TrackHitShape(track: track, scale: k, width: 2 * Manga.trackTouchRadius))
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    let n = track.nearest(to: SpeedTrack.Point(v.location.x / k, v.location.y / k))
                    let new = unit.kmh(forFraction: n.fraction)
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
        .accessibilityLabel(L10n.text("home.speed.vo"))
        .accessibilityValue(L10n.format(unit.pick("home.speed.value.vo", "home.speed.value.vo.mi"), unit.speedText(kmh: speed)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: speed = unit.kmh(speed, steps: 1)
            case .decrement: speed = unit.kmh(speed, steps: -1)
            @unknown default: break
            }
        }
    }

    // MARK: knob and value

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
            AntonText(unit.speedText(kmh: speed), 26)
            AntonText(L10n.text(unit.pick("home.speed.unit", "home.speed.unit.mi")), 15)
        }
        .shadow(color: c.paper, radius: 2)
        .shadow(color: c.paper, radius: 4)
        .shadow(color: c.paper, radius: 6)
        .manga(rotate: -4, skew: -8)
    }

    // MARK: trail

    /// Three tapered triangles behind the knob, rotated −8°: black 4 pt, red 6 pt, black 3 pt.
    /// Lengths: red 18 + f·120, black 12 + f·90 (f = fraction of the road, (v − 3) / 13 in km/h).
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

/// `clip-path: polygon(0 50%, 100% 0, 100% 100%)`: tip on the left, base on the right.
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

/// Hit area: the path thickened by `width` pt (20 pt per side).
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
