import SwiftUI
import StepTellerCore

/// Home («Today»): full-screen illustration, today's steps, minutes left and the speed slider running
/// on the road. 390 × 844 pt handoff canvas, scaled to the width (or to the height if the screen is
/// shorter than the reference).
struct HomeView: View {
    let size: CGSize
    /// Settings, a pop-up or the celebration over Home: NEAT waits (a line counts as seen only when it shows).
    var covered = false
    @Environment(StepsStore.self) private var store
    @Environment(\.manga) private var c
    @State private var minutesWidth: CGFloat = 96
    @State private var doneWidth: CGFloat = 130
    @State private var motion = ParallaxMotion()
    /// Never started: the leg of the soft fill at the edges (`edgeFill`) stays still.
    @State private var stillMotion = ParallaxMotion()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.season) private var season

    var body: some View {
        // Normally the canvas scales to the width; on short phones (e.g. SE, 375 × 667) it fits the height,
        // so road and slider stay on screen (the `paper` background shows on the sides, or, in season, the
        // same illustration stretched and soft, `edgeFill`).
        let s = min(size.width / Manga.frameWidth, size.height / Manga.frameHeight)
        MangaCanvas(width: Manga.frameWidth * s, height: size.height / s) {
            Board {
                // in season the same scene drawn for it (snow in the picture, the boot as the leg, T-015 §2)
                let look = season.map(SeasonLook.of)
                Group {
                    if look != nil {
                        // in season the top edge fades into the soft fill behind the status bar (T-019)
                        scene(look, motion: motion).mask {
                            VStack(spacing: 0) {
                                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 20)
                                Color.black
                            }
                        }
                    } else {
                        scene(nil, motion: motion)
                    }
                }
                .at(0, Manga.artTop)
                stepsBlock
                    .manga(rotate: -15, skew: -10, anchor: .topLeading)
                    .at(14, Manga.artTop + 112)
                notices
                    .at(20, Manga.artTop + 286)
                // NEAT's heart and bubble, in the room of the notices: the «no data» warning wins (T-023 §2)
                if !store.showsNoDataWarning, store.voice != .normale, let quote = store.homeQuote {
                    HomeVoice(level: store.voice, quote: quote, first: store.showsFirstLine, motion: store.heart) {
                        store.tapHeart()
                    }
                    .at(HomeVoice.origin.x, HomeVoice.origin.y)
                }
                if store.plan.isDone {
                    doneBlock
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { doneWidth = $0 }
                        .at(min(250, Manga.frameWidth - 10 - doneWidth), Manga.artTop + 452)
                } else {
                    minutesBlock
                        .manga(rotate: -5, skew: -9)
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { minutesWidth = $0 }
                        .at(min(290, Manga.frameWidth - 8 - minutesWidth),
                            Manga.artTop + 480 - (look?.slider ?? .knob).minutesLift)
                }
                if !store.plan.isDone {
                    RoadSpeedSlider(speed: Binding(get: { store.speed }, set: { store.speed = $0 }), unit: store.unit,
                                    look: look?.slider ?? .knob)
                        .frame(width: Manga.artSize.width, height: Manga.artSize.height)
                        .at(0, Manga.artTop)
                        .transition(.opacity)
                }
            }
            // in season the edge fill shows above and below the illustration (T-019)
            .background(season == nil ? c.paper : .clear)
            .animation(.easeInOut(duration: 0.25), value: store.plan.isDone)
        }
        .frame(width: size.width)
        .background(alignment: .topLeading) {
            if let look = season.map(SeasonLook.of) { edgeFill(look, s: s) }
        }
        .onAppear { updateMotion(); speak() }
        .onDisappear { motion.stop() }
        .onChange(of: scenePhase) { _, _ in updateMotion(); speak() }
        .onChange(of: reduceMotion) { _, _ in updateMotion() }
        // the bubble follows the day: steps, goal, voice, catalog, the time (situations change at 11 and 18)
        .onChange(of: store.steps) { _, _ in speak() }
        .onChange(of: store.goal) { _, _ in speak() }
        .onChange(of: store.voice) { _, _ in speak() }
        .onChange(of: store.catalogEdition) { _, _ in speak() }
        .onChange(of: store.showsNoDataWarning) { _, _ in speak() }
        .onChange(of: covered) { _, _ in speak() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in speak() }
    }

    /// NEAT's line in the bubble, only with Home on screen (a line counts as seen when it shows).
    private func speak() {
        guard scenePhase == .active, !covered else { return }
        store.updateHomeLine()
    }

    /// Parallax only with the app in the foreground and without «Reduce Motion».
    private func updateMotion() {
        if scenePhase == .active, !reduceMotion { motion.start() } else { motion.stop() }
    }

    // MARK: today's steps

    /// «PASSI DI OGGI» / number / «SU 10.000»: centered column, rotated −15° and skewed −10° from the
    /// top-left corner.
    private var stepsBlock: some View {
        VStack(spacing: 0) {
            AntonText(L10n.text("home.steps.label"), 27, tracking: 0.01)
                .padding(.bottom, TitleFont.gap(27))
            AntonText(LocalFormat.integer(store.steps), 108, lineHeight: 0.92, tracking: -0.035)
                .manga(scaleX: 0.86)
                .contentTransition(.numericText())
                .animation(.snappy, value: store.steps)
            AntonText(L10n.format("home.steps.of", LocalFormat.integer(store.goal)), 19, tracking: 0.02)
                .padding(.top, TitleFont.gap(19))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("home.steps.vo", LocalFormat.integer(store.steps), LocalFormat.integer(store.goal)))
    }

    /// Illustration and leg (parallax), 390 × 790, clipped to their frame.
    private func scene(_ look: SeasonLook?, motion: ParallaxMotion) -> some View {
        ZStack(alignment: .topLeading) {
            Image(look?.homeArt(c.theme) ?? c.homeArt)
                .resizable()
                .frame(width: Manga.artSize.width, height: Manga.artSize.height)
                .accessibilityHidden(true)
            ParallaxLeg(image: look?.homeLeg(c.theme) ?? c.homeLeg, motion: motion)
        }
        .frame(width: Manga.artSize.width, height: Manga.artSize.height, alignment: .topLeading)
        .clipped()
    }

    /// In season, the illustration to every edge of the screen, behind the canvas, in screen points: the
    /// status bar strip above `artTop` and what is left below (T-019), the sides of short phones (T-018). The same
    /// scene, still and soft: stretched only across, so every horizontal line meets the real one, and mirrored
    /// above and below its edges, so sky and road go on without a seam. Road and slider stay on the real one.
    private func edgeFill(_ look: SeasonLook, s: CGFloat) -> some View {
        let band = scene(look, motion: stillMotion)
            .scaleEffect(x: size.width / Manga.frameWidth, y: s, anchor: .topLeading)
            .frame(width: size.width, height: Manga.artSize.height * s, alignment: .topLeading)
        return VStack(spacing: 0) {
            band.scaleEffect(y: -1)
            band
            band.scaleEffect(y: -1)
        }
        .offset(y: (Manga.artTop - Manga.artSize.height) * s)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .blur(radius: 6 * s, opaque: true)
        .accessibilityHidden(true)
    }

    /// Warning when Health gives no data.
    @ViewBuilder private var notices: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.showsNoDataWarning {
                VStack(alignment: .leading, spacing: 6) {
                    TagText(text: L10n.text("home.noData.title"), size: 14, tracking: 0.06, foreground: c.paper, background: c.ink)
                    AntonText(L10n.text("home.noData.path"), 11, tracking: 0.04)
                        // over the moon at night (T-001, T-018): a `paper` halo, like the slider's value
                        .shadow(color: c.paper, radius: 2)
                        .shadow(color: c.paper, radius: 4)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } label: {
                        TagText(text: L10n.text("home.noData.button"), size: 13, tracking: 0.06, foreground: c.ink, background: c.paper, border: c.ink)
                    }
                    .buttonStyle(PressScale())
                }
                .accessibilityElement(children: .combine)
            }
        }
        .manga(rotate: -6, skew: -8, anchor: .topLeading)
    }

    // MARK: minutes left

    private var minutesBlock: some View {
        let p = store.plan, unit = store.unit
        return VStack(alignment: .leading, spacing: 0) {
            // at Christmas the block sits higher, over the boot's fur: a `paper` halo like the slider's value
            Group {
                AntonText(L10n.text("home.minutes.1"), 17)
                AntonText(L10n.text("home.minutes.2"), 17)
            }
            .shadow(color: season != nil ? c.paper : .clear, radius: 2)
            .shadow(color: season != nil ? c.paper : .clear, radius: 4)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                AntonText(LocalFormat.integer(p.minutes), 68, lineHeight: 0.95, tracking: -0.02)
                    .contentTransition(.numericText())
                AntonText(L10n.text("home.minutes.unit"), 18)
            }
            .padding(.top, 2)
            AntonText(L10n.format(unit.pick("home.minutes.km", "home.minutes.mi"), unit.distanceText(km: p.km)), 15, color: c.red)
                .padding(.top, 3)
        }
        .animation(.snappy(duration: 0.2), value: p.minutes)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format(unit.pick("home.minutes.vo", "home.minutes.vo.mi"), "\(p.minutes)",
                                        unit.speedText(kmh: p.speed), unit.distanceText(km: p.km)))
    }

    // MARK: goal reached

    /// «OBIETTIVO / RAGGIUNTO / FATTO! / +729 PASSI» in a slanted panel like those of the History screen:
    /// the `paper` background separates the text from the leg and laces of the illustration.
    private var doneBlock: some View {
        Vignette(shape: .panelA) {
            VStack(alignment: .leading, spacing: 0) {
                AntonText(L10n.text("home.done.1"), 17, tracking: 0.04)
                AntonText(L10n.text("home.done.2"), 17, tracking: 0.04)
                AntonText(L10n.text("home.done.3"), 68, lineHeight: 0.95, tracking: -0.02, color: c.red).padding(.top, 2)
                if store.steps > store.goal {
                    AntonText(L10n.format("home.done.extra", LocalFormat.integer(store.steps - store.goal)), 15, color: c.red)
                        .padding(.top, 3)
                }
            }
            .manga(skew: -9)
            .padding(.trailing, 4)
        }
        .rotationEffect(.degrees(-5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text("home.done.vo"))
    }
}
