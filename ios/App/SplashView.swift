import SwiftUI

/// Whether the opening animation plays: once per process (cold launch), never on return from the background.
enum Splash {
    /// Whether it plays at this launch; if so, the icon art starts rasterizing right away, alongside the app launch.
    @MainActor static func prepareAtLaunch() -> Bool {
        guard showsAtLaunch else { return false }
        art = Task { await SplashArt() }
        return true
    }

    /// The art being rasterized (released when the animation ends).
    @MainActor fileprivate static var art: Task<SplashArt, Never>?

    private static var showsAtLaunch: Bool {
        #if DEBUG
        let d = UserDefaults.standard
        // `-stepteller.skipSplash 1|0` wins; otherwise any `-stepteller.debug…` option (screenshots) skips it,
        // so the existing screenshots stay identical.
        if d.object(forKey: "stepteller.skipSplash") != nil { return !d.bool(forKey: "stepteller.skipSplash") }
        if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("-stepteller.debug") }) { return false }
        #endif
        return true
    }

    /// Debug only: `-stepteller.splashSlow 3` plays it three times slower (videos).
    static var slow: Double {
        #if DEBUG
        let v = UserDefaults.standard.double(forKey: "stepteller.splashSlow")
        if v > 0 { return v }
        #endif
        return 1
    }
}

/// Opening animation «Stomp», «Dan Dan Dan» style with the app icon art: on the icon black the shoe falls and
/// stamps (red burst behind it, kinetic rays, light haptic), «NEAT» slams in with a red hard shadow, then a red
/// slash wipes upwards and reveals Home (or the introduction). It lies above the app, which loads Health and the
/// history underneath meanwhile. The first frame is the plain black of the static launch screen. 1.2 s; a tap
/// skips it; with «Reduce Motion» it is a short fade.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var clock = Clock()
    @State private var skippedAt: Double?
    @State private var finished = false
    /// The icon art rasterized off the main thread: the animation waits on the black frame until it is ready,
    /// so the first frames with the shoe do not stall while iOS decodes the vectors.
    @State private var bitmaps: SplashArt?

    private let slow = Splash.slow

    /// Seconds, at normal speed.
    static let duration = 1.2
    private static let stillDuration = 0.7
    private static let skipFade = 0.15
    private var duration: Double { reduceMotion ? Self.stillDuration : Self.duration }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = clock.tick(timeline.date, running: scenePhase == .active && bitmaps != nil, slow: slow)
                let h = geo.size.height / (geo.size.width / Manga.frameWidth)
                MangaCanvas(width: geo.size.width, height: h) {
                    Group { if reduceMotion { still(t: t, h: h) } else { stomp(t: t, h: h) } }
                        .frame(width: Manga.frameWidth, height: h)
                }
                .opacity(skippedAt.map { max(0, 1 - (t - $0) / Self.skipFade) } ?? 1)
                .sensoryFeedback(.impact(weight: .light), trigger: !reduceMotion && t >= Stomp.impact) { _, hit in hit }
                .onChange(of: t >= (skippedAt.map { $0 + Self.skipFade } ?? duration)) { _, done in if done { finish() } }
            }
        }
        .task { bitmaps = await (Splash.art ?? Task { await SplashArt() }).value }
        // leaving the app during the animation ends it (before iOS takes the app-switcher snapshot):
        // the return from the background shows the app
        .onChange(of: scenePhase) { _, phase in if phase != .active, clock.time > 0 { finish() } }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { if skippedAt == nil, !finished { skippedAt = clock.time } }
        .accessibilityHidden(true)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        Splash.art = nil
        onFinish()
    }

    /// Animation time: it advances with the frames, at most 1/30 s per frame, and only in the foreground
    /// (a background launch by Health does not consume it). It starts after a few regular frames: the first
    /// frames draw the app underneath for the first time, and meanwhile the screen stays the launch-screen
    /// black (at most `settleLimit`). Later a slow frame pauses the animation instead of skipping part of it.
    private final class Clock {
        private(set) var time: Double = 0
        private var last: Date?
        private var waitingSince: Date?
        private var regularFrames = 0
        private static let settleFrames = 3
        private static let regularFrame = 1.0 / 24
        private static let settleLimit = 0.6

        func tick(_ date: Date, running: Bool, slow: Double) -> Double {
            defer { last = date }
            guard running, let last else { return time }
            let dt = max(0, date.timeIntervalSince(last))
            if regularFrames < Self.settleFrames {
                let since = waitingSince ?? date
                waitingSince = since
                regularFrames = dt < Self.regularFrame ? regularFrames + 1 : 0
                if date.timeIntervalSince(since) > Self.settleLimit { regularFrames = Self.settleFrames }
                return time
            }
            time += min(dt, 1.0 / 30) / slow
            return time
        }
    }

    // MARK: - Pieces

    private static let side = Manga.splashArtSide
    private static let artCenter = CGPoint(x: Manga.frameWidth / 2, y: Manga.splashArtTop + Manga.splashArtSide / 2)
    private static func titleCenter(_ h: CGFloat) -> CGPoint {
        CGPoint(x: Manga.frameWidth / 2, y: (Manga.splashArtTop + side + h) / 2 + 6)
    }

    /// Red sole and white shoe, the two layers of the icon.
    @ViewBuilder private var art: some View {
        if let bitmaps {
            ZStack {
                Image(uiImage: bitmaps.sole).resizable()
                Image(uiImage: bitmaps.shoe).resizable()
            }
            .frame(width: Self.side, height: Self.side)
        }
    }

    private func title(shadow: CGFloat) -> some View {
        GlyphText(text: "NEAT", size: Manga.splashTitleSize, lineHeight: 0.9, tracking: 0.02, fill: MangaPalette.iconWhite,
                  shadow: shadow > 0 ? (MangaPalette.iconRed, shadow, shadow) : nil)
            .manga(rotate: Manga.splashTitleRotation, skew: Manga.splashTitleSkew)
    }

    /// Reduce Motion: the final frame fades in over the launch black, then everything fades out.
    private func still(t: Double, h: CGFloat) -> some View {
        ZStack {
            MangaPalette.iconBlack
            ZStack {
                art.position(Self.artCenter)
                title(shadow: Manga.splashShadow).position(Self.titleCenter(h))
            }
            .opacity(min(1, t / 0.18))
        }
        .opacity(t < 0.45 ? 1 : max(0, 1 - (t - 0.45) / 0.25))
    }

    // MARK: - Stomp

    private enum Stomp {
        static let impact = 0.24
        static let exit = 0.86
        /// Red burst behind the shoe at the impact: short and partly transparent (no full-screen flash).
        static let burstDuration = 0.05
        static let burstOpacity = 0.65
        static let wipeAngle = -14.0
        static let wipeBand: CGFloat = 30

        struct Pose { var y: CGFloat = -640; var scale: CGFloat = 1.3; var rot: Double = -10; var title: CGFloat = 0; var shadow: CGFloat = 0 }
        static let timeline = KeyframeTimeline(initialValue: Pose()) {
            KeyframeTrack(\.y) { LinearKeyframe(0, duration: impact, timingCurve: .easeIn) }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1, duration: impact, timingCurve: .easeIn)
                LinearKeyframe(0.95, duration: 0.04)
                SpringKeyframe(1, duration: 0.3, spring: .snappy)
            }
            KeyframeTrack(\.rot) { LinearKeyframe(0, duration: impact, timingCurve: .easeIn) }
            KeyframeTrack(\.title) {
                LinearKeyframe(0, duration: 0.36)
                MoveKeyframe(1.9)
                LinearKeyframe(1, duration: 0.09, timingCurve: .easeIn)
                LinearKeyframe(1.04, duration: 0.03)
                SpringKeyframe(1, duration: 0.2, spring: .snappy)
            }
            KeyframeTrack(\.shadow) {
                LinearKeyframe(0, duration: 0.47)
                LinearKeyframe(Manga.splashShadow, duration: 0.07, timingCurve: .easeOut)
            }
        }
    }

    private func stomp(t: Double, h: CGFloat) -> some View {
        let p = Stomp.timeline.value(time: t)
        let since = t - Stomp.impact
        let amp = since > 0 && since < 0.16 ? 7 * (1 - since / 0.16) : 0
        let shake = CGSize(width: amp * sin(t * 95), height: amp * cos(t * 120))
        let rays = since > 0 ? min(1, since / 0.38) : 0
        let burst = since > 0 ? min(1, since / Stomp.burstDuration) : 0
        let wipe = UnitCurve.easeIn.value(at: max(0, min(1, (t - Stomp.exit) / (Self.duration - Stomp.exit))))
        let slope = tan(abs(Stomp.wipeAngle) * .pi / 180) * Manga.frameWidth / 2 + Stomp.wipeBand + 4
        let edge = (h + slope) - (h + 2 * slope) * wipe
        let impactCenter = CGPoint(x: Self.artCenter.x, y: Self.artCenter.y + 20)
        return ZStack {
            ZStack {
                MangaPalette.iconBlack
                if since < 0 { dropStreaks(artY: p.y, t: t) }
                if since > 0 && rays < 1 {
                    impactRays(center: impactCenter, inner: 110 + 320 * UnitCurve.easeOut.value(at: rays))
                        .opacity(1 - rays)
                }
                if since > 0 && burst < 1 {
                    KineticLines.star(cx: impactCenter.x, cy: impactCenter.y, points: 14, outer: 150, inner: 105, rotation: 0.2)
                        .fill(MangaPalette.iconRed)
                        .scaleEffect(0.8 + 0.4 * burst)
                        .opacity(Stomp.burstOpacity * (1 - burst))
                }
                art
                    .scaleEffect(p.scale)
                    .rotationEffect(.degrees(p.rot))
                    .position(x: Self.artCenter.x, y: Self.artCenter.y + p.y)
                if p.title > 0 {
                    title(shadow: p.shadow)
                        .scaleEffect(p.title)
                        .position(Self.titleCenter(h))
                }
            }
            .offset(shake)
            .mask(HalfPlane(y: edge, angle: Stomp.wipeAngle, above: true))
            if wipe > 0 {
                HalfPlane(y: edge, angle: Stomp.wipeAngle, above: false, thickness: Stomp.wipeBand).fill(MangaPalette.iconRed)
            }
        }
    }

    /// Kinetic rays bursting out of the impact, white with a red one every five.
    private func impactRays(center: CGPoint, inner: CGFloat) -> some View {
        let list = KineticLines.rays(cx: center.x, cy: center.y, count: 90, innerMin: Int(inner), innerMax: Int(inner) + 90,
                                     outer: 900, seed: 7, redEvery: 5)
        return Canvas { ctx, _ in
            for ray in list {
                var p = Path(); p.addLines(ray.points); p.closeSubpath()
                ctx.fill(p, with: .color(ray.red ? MangaPalette.iconRed : MangaPalette.iconWhite))
            }
        }
    }

    /// Vertical speed lines trailing the falling shoe.
    private func dropStreaks(artY: CGFloat, t: Double) -> some View {
        Canvas { ctx, _ in
            var g = ProtoRandom(r: 11)
            for _ in 0..<16 {
                let x = CGFloat(g.next() % 390), len = CGFloat(160 + g.next() % 260), w = 1 + CGFloat(g.next() % 4)
                let bottom = Self.artCenter.y + artY + CGFloat(g.next() % 200) - 60
                ctx.fill(Path(CGRect(x: x, y: bottom - len, width: w, height: len)), with: .color(MangaPalette.iconWhite))
            }
        }
        .opacity(min(1, t / 0.06))
    }
}

/// Red sole and white shoe of the icon as bitmaps, rendered once off the main thread at the size of the largest
/// iPhone (440 pt wide, 3×); smaller screens scale them down.
private struct SplashArt {
    let sole: UIImage
    let shoe: UIImage

    /// The two layers in parallel.
    init() async {
        async let sole = Self.render("SplashSole")
        async let shoe = Self.render("SplashShoe")
        (self.sole, self.shoe) = await (sole, shoe)
    }

    @concurrent private static func render(_ name: String) async -> UIImage {
        let side = Manga.splashArtSide * 440 / Manga.frameWidth
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            UIImage(named: name)?.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
}

/// Half-plane above (or below) a line through (midX, `y`) tilted by `angle` degrees; with `thickness`,
/// only the band of that height along the line on that side (the red slash of the wipe).
private struct HalfPlane: Shape {
    var y: CGFloat
    var angle: Double
    var above: Bool
    var thickness: CGFloat? = nil

    func path(in r: CGRect) -> Path {
        let k = tan(angle * .pi / 180)
        let x0 = r.minX - 100, x1 = r.maxX + 100
        func line(_ x: CGFloat, _ shift: CGFloat) -> CGPoint { CGPoint(x: x, y: y + shift + k * (x - r.midX)) }
        let far = (thickness ?? 4000) * (above ? -1 : 1)
        var p = Path()
        p.addLines([line(x0, 0), line(x1, 0), line(x1, far), line(x0, far)])
        p.closeSubpath()
        return p
    }
}
