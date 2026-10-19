import SwiftUI
import StepTellerCore

/// Festa «Obiettivo raggiunto»: la prima volta che si apre l'app dopo aver chiuso l'obiettivo del
/// giorno, in stile manga: raggi, esplosione a stella con i passi e scintille rosse e nere; si chiude
/// da sola dopo qualche secondo o con un tocco. Con «Riduci movimento» niente scintille né scatti.
struct GoalCelebration: View {
    let steps: Int
    let goal: Int
    let streak: Int
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var shown = false
    @State private var closing = false
    @State private var sparkOrigin = CGPoint.zero

    @Environment(\.manga) private var c
    @State private var pop: CGFloat = 0.6

    var body: some View {
        ZStack {
            c.paper.opacity(0.94)
            RaysView(rays: Self.rays)
                .frame(width: 390, height: 844)
                .mask(RadialGradient(stops: [.init(color: .clear, location: 0.2), .init(color: .white, location: 0.5)],
                                     center: .center, startRadius: 0, endRadius: 420))
                .opacity(shown ? 1 : 0)

            if !reduceMotion {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        Sparks.draw(&ctx, origin: sparkOrigin, t: timeline.date.timeIntervalSince(start), colors: [c.red, c.ink])
                    }
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: 18) {
                AntonText(L10n.text("party.title"), 30, tracking: 0.02)
                    .manga(rotate: -5, skew: -10)
                ZStack {
                    KineticLines.star(cx: 160, cy: 90, points: 16, outer: 92, inner: 62, rotation: 0.1)
                        .fill(c.ink)
                    KineticLines.star(cx: 160, cy: 90, points: 16, outer: 80, inner: 52, rotation: 0.1)
                        .fill(c.red)
                    GlyphText(text: LocalFormat.integer(steps), size: 96, lineHeight: 0.9, tracking: -0.03, fill: c.paper,
                              stroke: c.ink, strokeWidth: 2.5, shadow: (c.ink, 5, 5))
                        .manga(rotate: -5, skew: -10)
                }
                .frame(width: 320, height: 180)
                .scaleEffect(pop)
                .background(GeometryReader { g in
                    let f = g.frame(in: .named("festa"))
                    Color.clear
                        .onAppear { sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
                        .onChange(of: f) { _, f in sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
                })
                TagText(text: L10n.format("party.of", LocalFormat.integer(goal)), size: 18, tracking: 0.14,
                        foreground: c.paper, background: c.ink)
                    .manga(rotate: -3, skew: -10)
                if streak > 0 {
                    HStack(spacing: 6) {
                        FlameIcon(kind: .streak).frame(width: 22, height: 27)
                        AntonText(L10n.format("party.streak", streak), 22, tracking: 0.04)
                    }
                    .manga(rotate: -3, skew: -8)
                }
            }
            .opacity(shown ? 1 : 0)
            .scaleEffect(closing ? 0.96 : 1)
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "festa")
        .opacity(closing ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .sensoryFeedback(.success, trigger: shown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("party.vo", LocalFormat.integer(steps), LocalFormat.integer(goal)))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.text("party.close.vo"))
        .task {
            start = Date()
            if reduceMotion {
                pop = 1
                withAnimation(.easeOut(duration: 0.3)) { shown = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
                withAnimation(.spring(duration: 0.5, bounce: 0.45).delay(0.05)) { pop = 1 }
            }
            try? await Task.sleep(for: .seconds(3.4))
            close()
        }
    }

    private static let rays = KineticLines.rays(cx: 195, cy: 422, count: 90, innerMin: 150, innerMax: 230, outer: 700, seed: 7, redEvery: 7)

    private func close() {
        guard !closing else { return }
        withAnimation(.easeIn(duration: 0.3)) { closing = true }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onClose()
        }
    }
}

/// Scintille: due scoppi dal centro dell'arco, con gravità leggera e dissolvenza. Deterministiche
/// (stesso disegno a ogni festa), nei colori della palette.
private enum Sparks {
    private struct Spark {
        let angle, speed, size, delay, spin: Double
        let color: Int
        let long: Bool
    }

    private static let sparks: [Spark] = {
        var seed: UInt64 = 0x5EED_57E9
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(1 << 53)
        }
        return (0..<56).map { i in
            Spark(angle: rnd() * 2 * .pi, speed: 180 + rnd() * 260, size: 3 + rnd() * 4,
                  delay: 0.15 + (i < 36 ? 0 : 0.35) + rnd() * 0.12, spin: (rnd() - 0.5) * 10,
                  color: Int(rnd() * 4), long: rnd() < 0.5)
        }
    }()

    /// `origin`: centro dell'arco, nello spazio della festa.
    static func draw(_ ctx: inout GraphicsContext, origin: CGPoint, t: Double, colors: [Color]) {
        for s in sparks {
            let life = t - s.delay
            guard life > 0, life < 1.8 else { continue }
            let drag = 1 - exp(-2.6 * life)                       // rallenta come nell'aria
            let dist = s.speed * drag / 2.6
            let x = origin.x + cos(s.angle) * dist
            let y = origin.y + sin(s.angle) * dist + 120 * life * life   // gravità
            let alpha = min(1, life * 6) * max(0, 1 - life / 1.8)
            var c = ctx
            c.opacity = alpha
            c.translateBy(x: x, y: y)
            c.rotate(by: .radians(s.spin * life))
            let rect = s.long ? CGRect(x: -s.size, y: -s.size * 0.32, width: s.size * 2, height: s.size * 0.64)
                              : CGRect(x: -s.size / 2, y: -s.size / 2, width: s.size, height: s.size)
            c.fill(Path(roundedRect: rect, cornerRadius: s.size * 0.32), with: .color(colors[s.color % colors.count]))
        }
    }
}
