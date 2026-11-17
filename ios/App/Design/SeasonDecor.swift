import SwiftUI
import StepTellerCore

// Seasonal decorations (D-037, `docs/design/T-004-natale.md`). Shown only when `\.season` is set; all hidden from
// VoiceOver and never hit by touches. Compiled in the app and in the widget (static snow).

// MARK: - Accessory (Christmas: Santa hat, §3)

/// The season's accessory, drawn so that its attach point (center of the rim, (22.1, 28.2) in the 40 × 33 viewBox)
/// sits at the origin of a zero-size frame: place it with `.offset` at the attach point. Stroke 1.5 at every scale.
struct SeasonAccessory: View {
    let width: CGFloat
    var rotation: Double = 0
    @Environment(\.manga) private var c

    static let box = CGSize(width: 40, height: 33)
    static let anchor = CGPoint(x: 22.1, y: 28.2)
    private static let cone = SVGPath.parse("M37.1 25.8 C31.1 13.2 22.1 1.8 11.9 0.6 C7.1 0.0 4.1 3.6 4.7 8.7 C8.3 6.3 11.3 9.0 8.3 25.8 Z")
    private static let rim = Path(roundedRect: CGRect(x: 4.1, y: 23.7, width: 36, height: 9), cornerRadius: 4.5)
    private static let pom = Path(ellipseIn: CGRect(x: 0, y: 4.1, width: 9.6, height: 9.6))

    var body: some View {
        let height = width * Self.box.height / Self.box.width
        let unit = UnitPoint(x: Self.anchor.x / Self.box.width, y: Self.anchor.y / Self.box.height)
        ZStack {
            piece(Self.cone, c.red)
            piece(Self.pom, MangaPalette.iconWhite)
            piece(Self.rim, MangaPalette.iconWhite)      // the rim covers the base of the cone
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(rotation), anchor: unit)
        .offset(x: -width * unit.x, y: -height * unit.y)
        .frame(width: 0, height: 0, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func piece(_ path: Path, _ fill: Color) -> some View {
        let shape = SVGShape(path: path, viewBox: Self.box)
        return ZStack {
            shape.fill(fill)
            shape.stroke(c.ink, lineWidth: 1.5)
        }
    }
}

// MARK: - Snow

enum Snow {
    struct Flake {
        let x, y, radius: CGFloat
        let star: Bool
        var opacity: Double = 0.8
        var period: Double = 4
        var phase: Double = 0
        /// Falling speed, pt/s: big flakes fall faster.
        var speed: CGFloat { 22 + 10 * radius }
    }

    /// Flakes spread on the 390 × 844 frame with the fixed seed of the specification: radius 1.5 / 2 / 2.5 / 3.5
    /// (star) with weights 4 : 3 : 2 : 1, opacity 0.55–0.95, sway period 4 ± 1 s, random phase.
    static func flakes(count: Int, seed start: UInt64 = 0x5A17A) -> [Flake] {
        var seed = start
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(1 << 53)
        }
        return (0..<count).map { _ in
            let w = rnd() * 10
            let radius: CGFloat = w < 4 ? 1.5 : w < 7 ? 2 : w < 9 ? 2.5 : 3.5
            return Flake(x: rnd() * Manga.frameWidth, y: rnd() * Manga.frameHeight, radius: radius, star: radius == 3.5,
                         opacity: 0.55 + rnd() * 0.4, period: 3 + rnd() * 2, phase: rnd() * 2 * .pi)
        }
    }

    /// Fixed flakes of the specification: (x, y, radius), a 3.5 radius is a star.
    static func fixed(_ list: [(CGFloat, CGFloat, CGFloat)]) -> [Flake] {
        list.map { Flake(x: $0.0, y: $0.1, radius: $0.2, star: $0.2 == 3.5) }
    }

    /// A round flake, or a star with 6 arms 7 pt across (stroke 1.2, round caps).
    static func draw(_ ctx: inout GraphicsContext, _ f: Flake, at p: CGPoint, color: Color, opacity: Double) {
        var g = ctx
        g.opacity = opacity
        if f.star {
            var path = Path()
            for k in 0..<3 {
                let a = Double(k) * .pi / 3
                let dx = cos(a) * f.radius, dy = sin(a) * f.radius
                path.move(to: CGPoint(x: p.x - dx, y: p.y - dy))
                path.addLine(to: CGPoint(x: p.x + dx, y: p.y + dy))
            }
            g.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        } else {
            g.fill(Path(ellipseIn: CGRect(x: p.x - f.radius, y: p.y - f.radius, width: 2 * f.radius, height: 2 * f.radius)),
                   with: .color(color))
        }
    }
}

/// Falling snow over the whole Home frame (§4.1). Stops with the app not active; with «Reduce Motion» the flakes
/// stay where they are at t = 0.
struct SnowLayer: View {
    let count: Int
    let color: Color
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        let flakes = Snow.flakes(count: count)
        let still = reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still || scenePhase != .active)) { timeline in
            let t = still ? 0 : timeline.date.timeIntervalSince(start)
            Canvas { ctx, _ in
                let span = Manga.frameHeight + 10
                for f in flakes {
                    let fall = (f.y + 10 + f.speed * t).truncatingRemainder(dividingBy: span) - 10
                    let sway = 8 * sin(2 * .pi * t / f.period + f.phase)
                    Snow.draw(&ctx, f, at: CGPoint(x: f.x + sway, y: fall), color: color, opacity: f.opacity)
                }
            }
        }
        .frame(width: Manga.frameWidth, height: Manga.frameHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Snow that never moves (History, widget): fixed flakes, one opacity.
struct StaticSnow: View {
    let flakes: [Snow.Flake]
    let color: Color
    var opacity: Double = 0.8
    let size: CGSize

    var body: some View {
        Canvas { ctx, _ in
            for f in flakes { Snow.draw(&ctx, f, at: CGPoint(x: f.x, y: f.y), color: color, opacity: opacity) }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // Positions of the specification (§4.2, §4.5).
    static let history = Snow.fixed([(95, 304, 2.5), (354, 266, 1.5), (235, 506, 3.5), (103, 133, 3.5), (211, 307, 3.5),
                                     (248, 87, 2), (336, 293, 1.5), (260, 39, 1.5), (119, 21, 2.5), (185, 401, 3.5),
                                     (277, 512, 3.5), (282, 322, 2), (340, 58, 2), (193, 146, 3.5), (302, 476, 3.5),
                                     (198, 217, 2.5), (208, 229, 2), (349, 380, 1.5)])
    static let widgetSmall = Snow.fixed([(26, 141, 1.5), (45, 84, 2), (81, 65, 1.5), (19, 9, 2), (74, 127, 1.5),
                                         (117, 47, 1.5), (100, 21, 2), (9, 8, 2.5)])
    static let widgetMedium = Snow.fixed([(159, 158, 1.5), (19, 62, 1.5), (123, 112, 2), (45, 38, 1.5), (98, 30, 2),
                                          (107, 134, 2.5), (158, 92, 2), (85, 150, 1.5), (63, 155, 2), (73, 147, 1.5)])
}

// MARK: - Lights on the road

/// 14 bulbs along the road (§4.1), in the illustration space (390 × 790, the frame minus `Manga.artTop`): above
/// the illustration, below the leg. Colors in turn red, gold, pine; a halo at night; blinking 1 ↔ 0.35 in 1.2 s
/// ease-in-out, delay (i mod 3) × 0.4 s, computed from the time at 30 fps and stopped with the app not active
/// (still and lit with «Reduce Motion»).
struct RoadLights: View {
    let palette: SeasonPalette
    @Environment(\.manga) private var c
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()

    /// Frame coordinates of the specification.
    static let points: [CGPoint] = [(36.0, 801.5), (63.7, 794.2), (90.1, 787.8), (118.0, 781.5), (145.7, 775.8),
                                    (173.2, 770.6), (200.3, 766.0), (227.8, 761.3), (254.7, 755.1), (281.1, 746.2),
                                    (304.8, 731.9), (313.2, 706.1), (303.7, 680.6), (278.9, 667.8)]
        .map { CGPoint(x: $0.0, y: $0.1) }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            ZStack(alignment: .topLeading) {
                ForEach(Self.points.indices, id: \.self) { i in
                    bulb([c.red, palette.gold, palette.pine][i % 3])
                        .opacity(reduceMotion ? 1 : Self.blink(t - Double(i % 3) * 0.4))
                        .position(x: Self.points[i].x, y: Self.points[i].y - Manga.artTop)
                }
            }
        }
        .frame(width: Manga.artSize.width, height: Manga.artSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Opacity at `t` seconds: 1 → 0.35 in 1.2 s and back, ease-in-out (lit before its delay).
    static func blink(_ t: Double) -> Double {
        guard t > 0 else { return 1 }
        let x = t.truncatingRemainder(dividingBy: 2.4) / 1.2
        let p = x <= 1 ? x : 2 - x
        return 1 - 0.65 * (0.5 - 0.5 * cos(.pi * p))
    }

    /// Ellipse 6 × 9 centered on the point, with its 4 × 2.5 `ink` cap right above.
    private func bulb(_ color: Color) -> some View {
        ZStack {
            Ellipse().fill(color).frame(width: 6, height: 9)
                .shadow(color: c.theme == .night ? color.opacity(0.8) : .clear, radius: 5)
            Rectangle().fill(c.ink).frame(width: 4, height: 2.5).offset(y: -4.5 - 1.25)
        }
        .frame(width: 6, height: 9)
    }
}
