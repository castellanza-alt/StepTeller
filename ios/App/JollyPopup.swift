import SwiftUI
import StepTellerCore

/// A Jolly pop-up waiting to be shown: the latest event of its kind and how many were found together, or the
/// Christmas gift (T-015 §4).
struct JollyPopupItem: Identifiable, Equatable {
    enum Kind: Equatable { case used, earned, gift }
    let kind: Kind
    /// Streak and Jollies after the event, for the texts.
    let streak: Int
    let jolly: Int
    let count: Int
    let id: String

    init(event: StreakEvent, count: Int) {
        kind = event.kind == .jollyEarned ? .earned : .used
        streak = event.streak
        jolly = event.jolly
        self.count = count
        id = event.id
    }

    private init(kind: Kind, streak: Int, jolly: Int, count: Int, id: String) {
        self.kind = kind; self.streak = streak; self.jolly = jolly; self.count = count; self.id = id
    }

    static func gift(streak: Int, jolly: Int) -> JollyPopupItem {
        JollyPopupItem(kind: .gift, streak: streak, jolly: jolly, count: 1, id: "gift")
    }
}

/// «Jolly earned» / «Jolly used» pop-up (D-038, design `docs/design/T-005-popup-jolly.md`): at the first opening
/// after the event, never repeated, one at a time (gift → used → earned → goal celebration). A slanted panel with
/// the Jolly flame and «+N» / «−N»; it stays until «OK» or a tap anywhere: it shows once and must be read.
/// «Jolly in regalo» (T-015 §4.2) is the «earned» panel with the gift illustration and its own texts.
struct JollyPopup: View {
    let item: JollyPopupItem
    let onClose: () -> Void

    @Environment(\.manga) private var c
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var shown = false
    @State private var closing = false
    @State private var pop: CGFloat = 0.6
    @State private var tilt: Double = -12
    @State private var flame: CGFloat = 0
    @State private var shake = 0
    @State private var sparkOrigin = CGPoint.zero
    /// The sparks last about 2 s: then the timeline stops (the pop-up can stay on screen for a long time).
    @State private var sparksDone = false

    /// «Earned» and «gift» share the panel: red «+N», rays and sparks.
    private var earned: Bool { item.kind != .used }
    private var gift: Bool { item.kind == .gift }
    private var streak: Int { item.streak }
    private var jolly: Int { item.jolly }

    var body: some View {
        ZStack {
            c.paper.opacity(0.94)
            if earned {
                RaysView(rays: Self.rays)
                    .frame(width: Manga.frameWidth, height: Manga.frameHeight)
                    .mask(RadialGradient(stops: [.init(color: .clear, location: 0.2), .init(color: .white, location: 0.5)],
                                         center: UnitPoint(x: 0.5, y: 380 / Manga.frameHeight), startRadius: 0, endRadius: 420))
                    .opacity(shown ? 1 : 0)
                if !reduceMotion && !sparksDone {
                    TimelineView(.animation) { timeline in
                        Canvas { ctx, _ in
                            Sparks.draw(&ctx, origin: sparkOrigin, t: timeline.date.timeIntervalSince(start) - 0.15,
                                        colors: [c.red, c.ink])
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            panel
                .scaleEffect(pop)
                .rotationEffect(.degrees(tilt))
                .offset(y: 430 - Manga.frameHeight / 2)
                .opacity(shown ? 1 : 0)
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "jolly")
        .scaleEffect(closing ? 0.96 : 1)
        .opacity(closing ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .sensoryFeedback(earned ? .success : .warning, trigger: shown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOver)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.text("party.close.vo"))
        .accessibilityAction { close() }
        .task { appear() }
    }

    // MARK: panel

    private var panel: some View {
        Vignette(shape: .panelB, width: 318) {
            VStack(alignment: .leading, spacing: 0) {
                // extra top margin: the slanted title rises to the right, where the panel's top edge drops (T-013)
                Color.clear.frame(height: Self.titleRoom)
                AntonText(L10n.text(gift ? "jolly.gift.title" : earned ? "jolly.earned.title" : "jolly.used.title"), 30,
                          tracking: 0.02)
                    .manga(rotate: -5, skew: -10)
                HStack(spacing: gift ? 6 : 10) {
                    flameIcon
                    GlyphText(text: (earned ? "+" : "\u{2212}") + LocalFormat.integer(item.count), size: 112,
                              lineHeight: 0.9, tracking: -0.03, fill: earned ? c.red : c.paper, stroke: c.ink,
                              strokeWidth: 2.5, shadow: (earned ? c.ink : c.red, 5, 5))
                }
                .manga(rotate: -5, skew: -10)
                .padding(.top, 12)
                sentence(gift ? L10n.text("jolly.gift.line")
                            : earned ? L10n.format("jolly.earned.days", streak) : L10n.format("jolly.used.missed", item.count),
                         color: c.ink)
                    .padding(.top, 10)
                if !earned {
                    sentence(L10n.format("jolly.used.saved", streak), color: c.red)
                        .padding(.top, 2)
                }
                TagText(text: tag, size: 16, tracking: 0.1, foreground: c.paper, background: c.ink)
                    .manga(rotate: -3, skew: -10)
                    .padding(.top, 12)
                if earned {
                    Text(L10n.text(gift ? "jolly.gift.note" : "jolly.earned.note"))
                        .font(.antonText(14))
                        .tracking(14 * TitleFont.tracking(0.04))
                        .foregroundStyle(c.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                HStack {
                    Spacer()
                    Button(action: close) {
                        TagText(text: L10n.text("jolly.ok"), size: 20, tracking: 0.1, foreground: c.ink, background: c.paper,
                                border: c.ink, padding: EdgeInsets(top: 6, leading: 22, bottom: 6, trailing: 22))
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScale())
                }
                .padding(.top, 16)
            }
        }
    }

    /// Jolly flame 78 × 95: in «earned» it pops in and throws the sparks, in «used» it shakes. The gift: its
    /// illustration 128 × 126.3, which pops in and shakes too.
    @ViewBuilder private var picture: some View {
        if gift {
            Image("RegaloJolly").resizable().frame(width: 128, height: 126.3)
        } else {
            FlameIcon(kind: .jolly).frame(width: 78, height: 95)
        }
    }

    private var flameIcon: some View {
        picture
            .scaleEffect(earned ? flame : 1)
            .keyframeAnimator(initialValue: 0.0, trigger: shake) { view, angle in
                view.rotationEffect(.degrees(angle))
            } keyframes: { _ in
                LinearKeyframe(0, duration: 0.2)          // waits for the panel
                LinearKeyframe(-8, duration: 0.1)
                LinearKeyframe(8, duration: 0.1)
                LinearKeyframe(-5, duration: 0.1)
                LinearKeyframe(0, duration: 0.1)
            }
            .background(GeometryReader { g in
                let f = g.frame(in: .named("jolly"))
                Color.clear
                    .onAppear { sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
                    .onChange(of: f) { _, f in sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
            })
    }

    /// Anton 20, at most 2 lines.
    private func sentence(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.antonText(20))
            .tracking(20 * TitleFont.tracking(0.02))
            .foregroundStyle(color)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var tag: String {
        if earned { return L10n.format("jolly.count", jolly) }
        return jolly > 0 ? L10n.format("jolly.left", jolly) : L10n.text("jolly.left.none")
    }

    private var voiceOver: String {
        if gift { return L10n.format("jolly.gift.vo", LocalFormat.integer(jolly)) }
        return L10n.format(earned ? "jolly.earned.vo" : "jolly.used.vo", LocalFormat.integer(streak), LocalFormat.integer(jolly))
    }

    /// Room above the title inside the panel, so the rotated title never touches the top edge.
    static let titleRoom: CGFloat = 16

    private static let rays = KineticLines.rays(cx: 195, cy: 380, count: 90, innerMin: 150, innerMax: 230, outer: 700,
                                                seed: 7, redEvery: 7)

    // MARK: motion

    private func appear() {
        start = Date()
        #if DEBUG
        // Simulator checks of the queue (no taps there): `-stepteller.debugPopupClose 2` closes it after 2 s.
        let auto = UserDefaults.standard.double(forKey: "stepteller.debugPopupClose")
        if auto > 0 { Task { try? await Task.sleep(for: .seconds(auto)); close() } }
        #endif
        if reduceMotion {
            pop = 1; tilt = -4; flame = 1
            withAnimation(.easeOut(duration: 0.3)) { shown = true }
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { shown = true }
        withAnimation(.spring(duration: 0.5, bounce: 0.45).delay(0.05)) { pop = 1; tilt = -4 }
        if earned {
            withAnimation(.spring(duration: 0.45, bounce: 0.5).delay(0.15)) { flame = 1 }
            if gift { shake += 1 }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                sparksDone = true
            }
        } else {
            shake += 1
        }
    }

    private func close() {
        guard !closing else { return }
        withAnimation(.easeIn(duration: 0.3)) { closing = true }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onClose()
        }
    }
}
