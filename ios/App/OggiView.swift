import SwiftUI
import StepTellerCore

/// Pagina «Oggi»: illustrazione a tutto schermo (scarpa e strada), passi nell'anello a pennello in alto,
/// minuti sul tappeto a destra e velocità scelta trascinando il pallino rosso lungo la strada.
struct OggiView: View {
    @Environment(StepsStore.self) private var store
    let onSettings: () -> Void
    let onHistory: () -> Void

    var body: some View {
        GeometryReader { geo in
            let safe = geo.safeAreaInsets
            let full = CGSize(width: geo.size.width, height: geo.size.height + safe.top + safe.bottom)
            let art = OggiArt.rect(in: full)
            let p = store.plan
            ZStack(alignment: .topLeading) {
                Theme.bg
                Image("ArtOggi").resizable().interpolation(.high)
                    .frame(width: art.width, height: art.height)
                    .position(x: art.midX, y: art.midY)
                    .accessibilityHidden(true)

                hero(full: full, safe: safe, art: art)

                let dockHeight: CGFloat = 104
                let dockY = full.height - max(safe.bottom, 12) - dockHeight / 2 - 2
                if !p.isDone {
                    RoadSpeedControl(speed: Binding(get: { store.speed }, set: { store.speed = $0 }),
                                     samples: OggiArt.roadSamples(art: art, limitY: dockY - dockHeight / 2 - 26))
                        .transition(.opacity)
                }

                topBar
                    .frame(width: full.width - 44)
                    .position(x: full.width / 2, y: safe.top + 30)

                dock(p)
                    .frame(width: full.width - 28, height: dockHeight)
                    .position(x: full.width / 2, y: dockY)
            }
            .frame(width: full.width, height: full.height)
            .contentShape(Rectangle())
            // scorrere verso sinistra porta allo Storico (il cursore sulla strada ha la precedenza)
            .gesture(DragGesture(minimumDistance: 24).onEnded { g in
                if g.translation.width < -60, abs(g.translation.width) > abs(g.translation.height) * 1.3 { onHistory() }
            })
            .offset(y: -safe.top)
            .animation(.easeInOut(duration: 0.3), value: p.isDone)
        }
    }

    // MARK: streak, Jolly e impostazioni

    private var topBar: some View {
        let streak = store.history.shownStreak
        let jolly = store.history.shownJolly
        return HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").font(.system(size: 22))
                    .foregroundStyle(streak > 0 ? Theme.accent : Theme.soft)
                    .symbolEffect(.bounce, value: streak)
                Text("\(streak)").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: streak)
            }
            .padding(.horizontal, 14).frame(height: 44)
            .glass(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Streak: \(streak) giorni")

            HStack(spacing: 6) {
                GemShape().fill(Theme.ink).frame(width: 19, height: 19)
                Text("\(jolly)").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: jolly)
            }
            .padding(.horizontal, 14).frame(height: 44)
            .glass(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Jolly disponibili: \(jolly)")

            Spacer()
            RoundIconButton(label: "Impostazioni", action: onSettings) { SlidersIcon() }
        }
    }

    // MARK: passi nell'anello

    private func hero(full: CGSize, safe: EdgeInsets, art: CGRect) -> some View {
        let p = store.plan
        let top = safe.top + 64
        let bottom = max(top + 200, art.minY + art.height * 0.30)
        let rect = CGRect(x: 16, y: top, width: full.width - 32, height: bottom - top)
        let numberWidth = rect.width * 0.64
        let text = ItalianFormat.integer(store.steps)
        let size = SketchFont.fitted(text, base: min(116, rect.height * 0.46), width: numberWidth)
        return ZStack {
            BrushGauge(progress: p.progress, width: 13)
                .frame(width: rect.width, height: rect.height)
                .animation(.spring(duration: 0.9, bounce: 0.15), value: p.progress)
                .accessibilityHidden(true)
            VStack(spacing: 2) {
                Text("PASSI DI OGGI").font(.system(size: 15, weight: .semibold)).tracking(15 * 0.22)
                    .foregroundStyle(Theme.ink.opacity(0.75))
                SketchText(text, size: size)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: store.steps)
                    .frame(height: size * 1.12)
                    .accessibilityLabel("Passi di oggi: \(text)")
                Text("su \(ItalianFormat.integer(p.goal))")
                    .font(.system(size: 21, weight: .semibold)).monospacedDigit().foregroundStyle(Theme.ink.opacity(0.8))
                sourceBlock.padding(.top, 4)
            }
            .offset(y: rect.height * 0.04)
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    /// «da Salute · 21:04» / «manuale · 21:04», con «Usa Salute» quando c'è una sovrascrittura.
    private var sourceBlock: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if store.hasOverride {
                    Button("Usa Salute") { Task { await store.useHealth() } }
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                }
                Text(sourceText).font(.system(size: 14)).monospacedDigit().foregroundStyle(Theme.ink.opacity(0.7))
            }
            if store.showsNoDataWarning {
                Text("Nessun dato da Salute. Controlla Salute → Condivisione → App → Step Teller")
                    .font(.system(size: 12)).foregroundStyle(Theme.ink.opacity(0.7)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Apri Impostazioni") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: 260)
    }

    private var sourceText: String {
        let origin = store.origin == .health ? "da Salute" : "manuale"
        guard let date = store.lastUpdate else { return origin }
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "HH:mm"
        return "\(origin) · \(f.string(from: date))"
    }

    // MARK: minuti e velocità

    /// Barra in vetro in basso: velocità e minuti affiancati (o «Obiettivo fatto») e la bandierina per lo Storico.
    private func dock(_ p: Plan) -> some View {
        HStack(spacing: 0) {
            if p.isDone {
                VStack(alignment: .leading, spacing: 0) {
                    dockLabel("OBIETTIVO")
                    SketchText("FATTO", size: 50, color: Theme.accent).fixedSize()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Obiettivo raggiunto")
                Spacer(minLength: 8)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    dockLabel("VELOCITÀ · \(Text(p.gait.label.uppercased()).foregroundStyle(Theme.accent))")
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        SketchText(ItalianFormat.number(p.speed, decimals: 1), size: 46)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: p.speed)
                        Text("km/h").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                    }
                    .fixedSize()
                }
                .accessibilityHidden(true)       // la velocità si legge (e si cambia) dal pallino sulla strada
                Spacer(minLength: 8)
                Rectangle().fill(Theme.ink.opacity(0.15)).frame(width: 1, height: 56)
                Spacer(minLength: 8)
                VStack(alignment: .leading, spacing: 0) {
                    dockLabel("MINUTI SUL TAPPETO")
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        SketchText(ItalianFormat.integer(p.minutes), size: 46)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: p.minutes)
                        Text("min").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink)
                    }
                    .fixedSize()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(p.minutes) minuti sul tappeto per \(ItalianFormat.integer(p.remaining)) passi")
                Spacer(minLength: 8)
            }
            Button(action: onHistory) {
                Image(systemName: "flag.checkered").font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Theme.accent))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Storico")
        }
        .padding(.leading, 20).padding(.trailing, 14)
        .glass(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: p.isDone)
    }

    private func dockLabel(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 10, weight: .semibold)).tracking(1)
            .foregroundStyle(Theme.ink.opacity(0.75)).lineLimit(1).fixedSize()
    }
}

/// Posizione dell'illustrazione e della strada (coordinate normalizzate dell'immagine 944×1680).
enum OggiArt {
    static let aspect: CGFloat = 1680.0 / 944.0

    /// Larga quanto lo schermo e appoggiata in basso; sugli schermi bassi lascia comunque il 22% in alto
    /// (la parte bassa dell'immagine esce dallo schermo).
    static func rect(in size: CGSize) -> CGRect {
        let h = size.width * aspect
        let top = max(size.height - h, size.height * 0.22)
        return CGRect(x: 0, y: top, width: size.width, height: h)
    }

    /// Linea tratteggiata al centro della strada, dal basso a sinistra (3 km/h) alla curva dietro la scarpa (12 km/h).
    static let road: [CGPoint] = [
        CGPoint(x: 0.03, y: 0.972), CGPoint(x: 0.132, y: 0.911), CGPoint(x: 0.242, y: 0.857), CGPoint(x: 0.35, y: 0.808),
        CGPoint(x: 0.443, y: 0.771), CGPoint(x: 0.53, y: 0.744), CGPoint(x: 0.606, y: 0.714), CGPoint(x: 0.69, y: 0.683),
        CGPoint(x: 0.77, y: 0.655), CGPoint(x: 0.83, y: 0.638), CGPoint(x: 0.855, y: 0.615), CGPoint(x: 0.835, y: 0.597),
        CGPoint(x: 0.785, y: 0.592), CGPoint(x: 0.735, y: 0.587), CGPoint(x: 0.69, y: 0.576),
    ]

    /// Punti della strada sullo schermo; il tratto iniziale sotto `limitY` (fuori schermo o sotto la barra
    /// di sistema) non si usa.
    static func roadSamples(art: CGRect, limitY: CGFloat) -> [CGPoint] {
        let all = SmoothCurve.samples(road, in: art)
        guard let first = all.firstIndex(where: { $0.y <= limitY }) else { return all }
        return Array(all[first...])
    }
}

/// Cursore della velocità: pallino rosso trascinabile lungo la strada (3–12 km/h, passo 0,1).
struct RoadSpeedControl: View {
    @Binding var speed: Double
    let samples: [CGPoint]
    private let range = CadenceModel.minSpeed...CadenceModel.maxSpeed

    /// Lunghezza cumulata normalizzata 0…1 di ogni punto.
    private var fractions: [CGFloat] {
        var acc: [CGFloat] = [0]
        for i in 1..<max(1, samples.count) {
            acc.append(acc[i - 1] + hypot(samples[i].x - samples[i - 1].x, samples[i].y - samples[i - 1].y))
        }
        let total = max(acc.last ?? 1, 1)
        return acc.map { $0 / total }
    }

    var body: some View {
        let f = fractions
        let t = CGFloat((speed - range.lowerBound) / (range.upperBound - range.lowerBound))
        ZStack(alignment: .topLeading) {
            RoadHitShape(samples: samples).fill(Color.clear)
            PulsingDot().position(point(at: t, fractions: f))
                .allowsHitTesting(false)
        }
        .contentShape(RoadHitShape(samples: samples))
        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
            guard !samples.isEmpty else { return }
            let i = samples.indices.min(by: { dist(samples[$0], drag.location) < dist(samples[$1], drag.location) }) ?? 0
            let v = range.lowerBound + Double(f[i]) * (range.upperBound - range.lowerBound)
            speed = min(range.upperBound, max(range.lowerBound, (v * 10).rounded() / 10))
        })
        .sensoryFeedback(.selection, trigger: Int(speed))      // tocco aptico a ogni km/h intero
        .accessibilityElement()
        .accessibilityLabel("Velocità")
        .accessibilityValue("\(ItalianFormatBridge.speed(speed)) chilometri orari")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: speed = min(range.upperBound, ((speed + 0.1) * 10).rounded() / 10)
            case .decrement: speed = max(range.lowerBound, ((speed - 0.1) * 10).rounded() / 10)
            @unknown default: break
            }
        }
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private func point(at t: CGFloat, fractions f: [CGFloat]) -> CGPoint {
        guard let last = samples.last else { return .zero }
        guard let i = f.firstIndex(where: { $0 >= t }), i > 0 else { return t <= 0 ? samples.first ?? last : last }
        let span = max(f[i] - f[i - 1], 0.0001)
        let k = (t - f[i - 1]) / span
        return CGPoint(x: samples[i - 1].x + (samples[i].x - samples[i - 1].x) * k,
                       y: samples[i - 1].y + (samples[i].y - samples[i - 1].y) * k)
    }
}

/// Pallino della velocità con un'onda che pulsa (ferma con «Riduci movimento»).
private struct PulsingDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle().stroke(Theme.accent.opacity(pulse ? 0 : 0.6), lineWidth: 2)
                .frame(width: 32, height: 32)
                .scaleEffect(pulse ? 2.1 : 1)
            RoadDot(size: 32)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
        }
    }
}

/// Zona sensibile al tocco: una fascia larga 64 pt attorno alla strada.
private struct RoadHitShape: Shape {
    let samples: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addLines(samples)
        return p.strokedPath(StrokeStyle(lineWidth: 64, lineCap: .round, lineJoin: .round))
    }
}
