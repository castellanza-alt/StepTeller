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

                if p.isDone {
                    doneBadge
                        .position(x: full.width - 24 - 70, y: art.minY + art.height * 0.675)
                        .transition(.opacity)
                } else {
                    minutesBlock(p)
                        .frame(width: full.width * 0.5, alignment: .trailing)
                        .position(x: full.width - 24 - full.width * 0.25, y: art.minY + art.height * 0.675)
                        .transition(.opacity)
                    speedLabel(p)
                        .frame(width: full.width * 0.6, alignment: .leading)
                        .position(x: 24 + full.width * 0.3, y: art.minY + art.height * 0.735)
                        .transition(.opacity)
                    RoadSpeedControl(speed: Binding(get: { store.speed }, set: { store.speed = $0 }),
                                     samples: OggiArt.roadSamples(art: art, limitY: full.height - safe.bottom - 22))
                        .transition(.opacity)
                }

                topBar
                    .frame(width: full.width - 44)
                    .position(x: full.width / 2, y: safe.top + 30)

                RoundIconButton(label: "Storico", action: onHistory) {
                    Image(systemName: "flag.checkered").font(.system(size: 22, weight: .medium))
                }
                .position(x: full.width - 22 - 28, y: full.height - max(safe.bottom, 12) - 34)
            }
            .frame(width: full.width, height: full.height)
            .offset(y: -safe.top)
            .animation(.easeInOut(duration: 0.3), value: p.isDone)
        }
    }

    // MARK: streak, Jolly e impostazioni

    private var topBar: some View {
        let s = store.history.streak
        return HStack(spacing: 22) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").font(.system(size: 22))
                    .foregroundStyle(s.streak > 0 ? Theme.accent : Theme.soft)
                Text("\(s.streak)").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: s.streak)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Streak: \(s.streak) giorni")

            HStack(spacing: 6) {
                GemShape().fill(Theme.ink).frame(width: 19, height: 19)
                Text("\(s.jolly)").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Jolly disponibili: \(s.jolly)")

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

    private func minutesBlock(_ p: Plan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MINUTI SUL\nTAPPETO")
                .font(.system(size: 14, weight: .semibold)).tracking(14 * 0.2)
                .lineSpacing(2).foregroundStyle(Theme.ink.opacity(0.8))
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                SketchText(ItalianFormat.integer(p.minutes), size: 76)
                Text("min").font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.ink)
            }
        }
        .padding(8)
        .paperHalo()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(p.minutes) minuti sul tappeto per \(ItalianFormat.integer(p.remaining)) passi")
    }

    private func speedLabel(_ p: Plan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("VELOCITÀ · \(Text(p.gait.label.uppercased()).foregroundStyle(Theme.accent))")
                .font(.system(size: 14, weight: .semibold)).tracking(14 * 0.2)
                .foregroundStyle(Theme.ink.opacity(0.8))
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                SketchText(ItalianFormat.number(p.speed, decimals: 1), size: 64)
                Text("km/h").font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.ink)
            }
        }
        .padding(8)
        .paperHalo()
        .accessibilityHidden(true)       // la velocità si legge (e si cambia) dal cursore sulla strada
    }

    private var doneBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("OBIETTIVO").font(.system(size: 14, weight: .semibold)).tracking(14 * 0.2)
                .foregroundStyle(Theme.ink.opacity(0.8))
            SketchText("FATTO", size: 64, color: Theme.accent)
        }
        .padding(8)
        .paperHalo()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Obiettivo raggiunto")
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
            RoadDot(size: 32).position(point(at: t, fractions: f))
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

/// Zona sensibile al tocco: una fascia larga 64 pt attorno alla strada.
private struct RoadHitShape: Shape {
    let samples: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addLines(samples)
        return p.strokedPath(StrokeStyle(lineWidth: 64, lineCap: .round, lineJoin: .round))
    }
}

extension View {
    /// Alone di carta dietro le scritte che stanno sopra l'illustrazione.
    func paperHalo() -> some View {
        background(RoundedRectangle(cornerRadius: 24).fill(Theme.bg.opacity(0.78)).blur(radius: 12))
    }
}
