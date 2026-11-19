import SwiftUI
import StepTellerCore

/// NEAT's heart (T-023 §1): Piccante dark with spikes, NASTY black and cracked with horns; none with Normale.
/// The approved drawing split into layers (`docs/design/T-023-nasty/livelli/`) that, stacked in the same square,
/// make exactly `cuore-*.svg`. Day and night by the app's theme (it does not always follow the system's).
struct NastyHeart: View {
    let level: NastyLevel
    let size: CGFloat
    var pose = HeartPose()
    @Environment(\.manga) private var c

    /// Red of the glowing cracks (the night `red`, the same in both themes).
    static let glowRed = Color(hex: 0xFF3B30)

    private var night: Bool { c.theme == .night }
    /// Movements are written for a 200 pt heart (T-023 §3.1).
    private var k: CGFloat { size / 200 }

    var body: some View {
        ZStack {
            if level == .piccante { piccante } else if level == .nasty { nasty }
        }
        .frame(width: size, height: size)
        .scaleEffect(x: pose.scaleX, y: pose.scaleY)
        .rotationEffect(.degrees(pose.rotation))
        .offset(x: pose.x * k, y: pose.y * k)
        .opacity(pose.opacity)
        .accessibilityHidden(true)
    }

    private func layer(_ name: String) -> some View {
        Image(name).resizable().interpolation(.high).frame(width: size, height: size)
    }

    // MARK: Piccante

    private var piccante: some View {
        ZStack {
            layer(night ? "CuorePiccantePunteNotte" : "CuorePiccantePunteGiorno")
                .scaleEffect(pose.spikesScale)
                .rotationEffect(.degrees(pose.spikesRotation))
            ZStack {
                layer("CuorePiccanteCorpo")
                layer("CuorePiccanteLucido")
            }
            .scaleEffect(pose.bodyScale)
            if pose.puffs > 0 { puffs }
        }
    }

    /// Three puffs out of the hump (§3.4, «Sbuffa»): they show at 55% and rise 70 pt opening out.
    private var puffs: some View {
        let q = pose.puffs
        let opacity = Track(.easeOut, [(0, 0), (0.4, 0), (0.55, 1), (1, 0)]).at(q)
        let scale = Track(.easeOut, [(0, 0.3), (0.4, 0.4), (1, 1.25)]).at(q)
        let rise = Track(.easeOut, [(0, 0), (0.4, 0), (1, 1)]).at(q)
        return ZStack {
            ForEach(Array(zip([0.232, 0.505, 0.777], [-40.0, 0, 40])), id: \.0) { cx, dx in
                Ellipse()
                    .fill(c.paper)
                    .overlay(Ellipse().strokeBorder(c.ink, lineWidth: 2.5 * k))
                    .frame(width: 30 * k, height: 24 * k)
                    .scaleEffect(scale)
                    .position(x: size * cx + dx * k * rise, y: size * 0.134 - 70 * k * rise)
                    .opacity(opacity)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: NASTY

    private var nasty: some View {
        ZStack {
            layer(night ? "CuoreNastyScheggeNotte" : "CuoreNastyScheggeGiorno")
                .scaleEffect(pose.shardsScale)
                .rotationEffect(.degrees(pose.shardsRotation))
                .opacity(pose.shardsOpacity)
            layer(night ? "CuoreNastyCornaNotte" : "CuoreNastyCornaGiorno")
            if let split = pose.split {
                core(split.left).clipShape(HalfMask(left: true))
                core(split.right).clipShape(HalfMask(left: false))
            } else {
                core((0, 0, 0))
            }
        }
    }

    /// Body, cracks and gloss: whole, or one half of the split moved by (x, y, degrees).
    private func core(_ move: (Double, Double, Double)) -> some View {
        ZStack {
            layer("CuoreNastyCorpo")
            cracks
            layer("CuoreNastyLucido")
        }
        .rotationEffect(.degrees(move.2))
        .offset(x: move.0 * k, y: move.1 * k)
    }

    /// The cracks lighting up: brightness added as in CSS `brightness()` (the same red added on itself) and a red
    /// glow around them.
    private var cracks: some View {
        let g = pose.glow
        return layer("CuoreNastyCrepe")
            .overlay { if g > 0 { layer("CuoreNastyCrepe").blendMode(.plusLighter).opacity(min(1, g)) } }
            .overlay { if g > 1 { layer("CuoreNastyCrepe").blendMode(.plusLighter).opacity(g - 1) } }
            .shadow(color: pose.glowRadius > 0.1 ? Self.glowRed : .clear, radius: pose.glowRadius * k)
    }
}

/// Half of the heart along the central crack (points in % of the side, T-023 §3.4).
private struct HalfMask: Shape {
    let left: Bool
    func path(in r: CGRect) -> Path {
        let crack = [(52, 0), (49, 22), (55, 38), (46, 55), (53, 72), (50, 100)].map {
            CGPoint(x: r.minX + r.width * CGFloat($0.0) / 100, y: r.minY + r.height * CGFloat($0.1) / 100)
        }
        // generous margin outside the square: the halves move and the shards stick out
        let m = r.width * 0.5
        var p = Path()
        p.move(to: CGPoint(x: crack[0].x, y: r.minY - m))
        crack.forEach { p.addLine(to: $0) }
        p.addLine(to: CGPoint(x: crack[5].x, y: r.maxY + m))
        let side = left ? r.minX - m : r.maxX + m
        p.addLine(to: CGPoint(x: side, y: r.maxY + m))
        p.addLine(to: CGPoint(x: side, y: r.minY - m))
        p.closeSubpath()
        return p
    }
}

/// The heart that lives (Home, first line): beats at rest, speaks, reacts to taps. One clock with the bubble
/// (`HeartMotion`); at 120 Hz while something moves, paused with the app in the background.
struct LiveHeart: View {
    let level: NastyLevel
    let size: CGFloat
    let motion: HeartMotion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(paused: scenePhase != .active || reduceMotion && !motion.busy(Date()))) { t in
            NastyHeart(level: level, size: size,
                       pose: motion.pose(level, at: t.date, rest: true, reduceMotion: reduceMotion))
                // room around the square: shards, puffs and dodges go out of it, the group would cut them
                .padding(size * 0.6)
                .drawingGroup()
                .padding(-size * 0.6)
        }
        .frame(width: size, height: size)
    }
}
