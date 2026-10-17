import SwiftUI
import StepTellerCore

/// Festa «Obiettivo raggiunto»: la prima volta che si apre l'app dopo aver chiuso l'obiettivo del
/// giorno. La pennellata dell'anello si completa, compare la spunta e partono le scintille; si chiude
/// da sola dopo qualche secondo o con un tocco. Con «Riduci movimento» niente scintille né scatti.
struct GoalCelebration: View {
    let steps: Int
    let goal: Int
    let streak: Int
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var arc = 0.0
    @State private var check = 0.0
    @State private var shown = false
    @State private var closing = false
    @State private var sparkOrigin = CGPoint.zero

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Theme.bg.opacity(0.94)

            if !reduceMotion {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        Sparks.draw(&ctx, origin: sparkOrigin, t: timeline.date.timeIntervalSince(start))
                    }
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: 26) {
                ZStack {
                    BrushGauge(progress: arc, width: 10)
                    BrushStroke(shape: CheckShape().trim(from: 0, to: check), width: 8)
                        .frame(width: 70, height: 52)
                        .offset(y: 4)
                }
                .frame(width: 200, height: 170)
                .background(GeometryReader { g in
                    let f = g.frame(in: .named("festa"))
                    Color.clear
                        .onAppear { sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
                        .onChange(of: f) { _, f in sparkOrigin = CGPoint(x: f.midX, y: f.midY) }
                })

                VStack(spacing: 10) {
                    Text("OBIETTIVO RAGGIUNTO")
                        .font(.system(size: 15, weight: .bold)).tracking(15 * 0.24)
                        .foregroundStyle(Theme.accent)
                    SketchText(ItalianFormat.integer(steps), size: 88)
                    Text("passi su \(ItalianFormat.integer(goal))")
                        .font(.system(size: 18, weight: .semibold)).monospacedDigit().foregroundStyle(Theme.ink.opacity(0.8))
                }
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 12)

                if streak > 0 {
                    HStack(spacing: 8) {
                        Image("ArtFiamma").resizable().scaledToFit().frame(width: 40, height: 40)
                        Text(streak == 1 ? "1 giorno di fila" : "\(streak) giorni di fila")
                    }
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.ink)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 12)
                }
            }
            .padding(.horizontal, 32)
            .scaleEffect(closing ? 0.96 : 1)
        }
        .ignoresSafeArea()
        .coordinateSpace(name: "festa")
        .opacity(closing ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .sensoryFeedback(.success, trigger: check >= 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Obiettivo raggiunto: \(ItalianFormat.integer(steps)) passi su \(ItalianFormat.integer(goal))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tocca per chiudere")
        .task {
            start = Date()
            if reduceMotion {
                arc = 1; check = 1
                withAnimation(.easeOut(duration: 0.3)) { shown = true }
            } else {
                withAnimation(.easeInOut(duration: 0.9)) { arc = 1 }
                withAnimation(.easeOut(duration: 0.4).delay(0.85)) { check = 1 }
                withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.6)) { shown = true }
            }
            try? await Task.sleep(for: .seconds(3.4))
            close()
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

/// Spunta dentro l'anello.
private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

/// Scintille: due scoppi dal centro dell'anello, con gravità leggera e dissolvenza. Deterministiche
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
                  delay: 0.85 + (i < 36 ? 0 : 0.35) + rnd() * 0.12, spin: (rnd() - 0.5) * 10,
                  color: Int(rnd() * 4), long: rnd() < 0.5)
        }
    }()

    private static let colors: [Color] = [Theme.accent, Theme.accent.opacity(0.6), Theme.ink.opacity(0.75), Theme.ink.opacity(0.4)]

    /// `origin`: centro dell'anello, nello spazio della festa.
    static func draw(_ ctx: inout GraphicsContext, origin: CGPoint, t: Double) {
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
            c.fill(Path(roundedRect: rect, cornerRadius: s.size * 0.32), with: .color(colors[s.color]))
        }
    }
}
