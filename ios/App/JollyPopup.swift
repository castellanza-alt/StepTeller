import SwiftUI
import StepTellerCore

/// A Jolly pop-up waiting to be shown: the latest event of its kind and how many were found together.
struct JollyPopupItem: Identifiable, Equatable {
    let event: StreakEvent
    let count: Int
    var id: String { event.id }
}

/// «Jolly earned» / «Jolly used» pop-up (D-038, design `docs/design/T-005-popup-jolly.md`): at the first opening
/// after the event, never repeated, one at a time (used → earned → goal celebration). A slanted panel with the
/// Jolly flame and «+N» / «−N»; it stays until «OK» or a tap anywhere: it shows once and must be read.
struct JollyPopup: View {
    let item: JollyPopupItem
    let onClose: () -> Void

    @Environment(\.manga) private var c
    @Environment(\.season) private var season
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var shown = false
    @State private var closing = false
    @State private var pop: CGFloat = 0.6
    @State private var tilt: Double = -12
    @State private var flame: CGFloat = 0
    @State private var shake = 0
    @State private var sparkOrigin = CGPoint.zero

    private var earned: Bool { item.event.kind == .jollyEarned }
    private var streak: Int { item.event.streak }
    private var jolly: Int { item.event.jolly }

    var body: some View {
        ZStack {
            c.paper.opacity(0.94)
            if earned {
                RaysView(rays: Self.rays)
                    .frame(width: Manga.frameWidth, height: Manga.frameHeight)
                    .mask(RadialGradient(stops: [.init(color: .clear, location: 0.2), .init(color: .white, location: 0.5)],
                                         center: UnitPoint(x: 0.5, y: 380 / Manga.frameHeight), startRadius: 0, endRadius: 420))
                    .opacity(shown ? 1 : 0)
                if !reduceMotion {
                    TimelineView(.animation) { timeline in
                        Canvas { ctx, _ in
                            Sparks.draw(&ctx, origin: sparkOrigin, t: timeline.date.timeIntervalSince(start) - 0.15,
                                        colors: sparkColors)
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
                AntonText(L10n.text(earned ? "jolly.earned.title" : "jolly.used.title"), 30, tracking: 0.02)
                    .manga(rotate: -5, skew: -10)
                HStack(spacing: 10) {
                    flameIcon
                    GlyphText(text: (earned ? "+" : "\u{2212}") + LocalFormat.integer(item.count), size: 112,
                              lineHeight: 0.9, tracking: -0.03, fill: earned ? c.red : c.paper, stroke: c.ink,
                              strokeWidth: 2.5, shadow: (earned ? c.ink : c.red, 5, 5))
                }
                .manga(rotate: -5, skew: -10)
                .padding(.top, 12)
                sentence(earned ? L10n.format("jolly.earned.days", streak) : L10n.format("jolly.used.missed", item.count),
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
                    Text(L10n.text("jolly.earned.note"))
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

    /// Jolly flame 78 × 95: in «earned» it pops in and throws the sparks, in «used» it shakes. In season, the hat.
    private var flameIcon: some View {
        FlameIcon(kind: .jolly)
            .frame(width: 78, height: 95)
            .overlay(alignment: .topLeading) {
                if season != nil { SeasonAccessory(width: 46, rotation: -10).offset(x: 39, y: 16) }
            }
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
        L10n.format(earned ? "jolly.earned.vo" : "jolly.used.vo", LocalFormat.integer(streak), LocalFormat.integer(jolly))
    }

    private var sparkColors: [Color] {
        guard let season else { return [c.red, c.ink] }
        let p = SeasonPalette.of(season, c.theme)
        return [c.red, c.ink, p.pine, p.gold]
    }

    private static let rays = KineticLines.rays(cx: 195, cy: 380, count: 90, innerMin: 150, innerMax: 230, outer: 700,
                                                seed: 7, redEvery: 7)

    // MARK: motion

    private func appear() {
        start = Date()
        if reduceMotion {
            pop = 1; tilt = -4; flame = 1
            withAnimation(.easeOut(duration: 0.3)) { shown = true }
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { shown = true }
        withAnimation(.spring(duration: 0.5, bounce: 0.45).delay(0.05)) { pop = 1; tilt = -4 }
        if earned {
            withAnimation(.spring(duration: 0.45, bounce: 0.5).delay(0.15)) { flame = 1 }
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
