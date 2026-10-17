import SwiftUI
import StepTellerCore

/// Sfondo del widget: carta (chiaro o scuro come il sistema).
struct StepsWidgetBackground: View {
    var body: some View { Theme.bg }
}

/// Widget piccolo: anello a pennello con i passi al centro e, sotto, i minuti a piedi che mancano
/// (camminata a 4 km/h, solo un'idea di massima). Disegnato nello spazio 340×340 e scalato.
struct StepsWidgetView: View {
    /// `nil` = dato non disponibile.
    let plan: Plan?

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / 340
            content
                .frame(width: 340, height: 340)
                .scaleEffect(k, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            BrushGauge(progress: plan?.progress ?? 0, width: 15)
                .frame(width: 284, height: 226)
                .position(x: 170, y: 140)
            stepsCenter
            bottomLine
        }
    }

    private var stepsCenter: some View {
        let text = plan.map { ItalianFormat.integer($0.steps) } ?? "—"
        return VStack(spacing: 2) {
            Text("PASSI DI OGGI").font(.system(size: 15, weight: .semibold)).tracking(3)
                .foregroundStyle(Theme.ink.opacity(0.75))
            SketchText(text, size: SketchFont.fitted(text, base: 86, width: 180))
            Text(plan.map { "su \(ItalianFormat.integer($0.goal))" } ?? "apri l'app")
                .font(.system(size: 19, weight: .semibold)).monospacedDigit().foregroundStyle(Theme.ink.opacity(0.8))
        }
        .frame(width: 210)
        .position(x: 170, y: 150)
    }

    @ViewBuilder
    private var bottomLine: some View {
        if let plan {
            Group {
                if plan.isDone {
                    Text("OBIETTIVO FATTO").font(.system(size: 19, weight: .bold)).tracking(2)
                        .foregroundStyle(Theme.accent)
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("≈").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.7))
                        SketchText(String(plan.minutes), size: 48, color: Theme.accent)
                        Text("min a piedi").font(.system(size: 19, weight: .semibold)).foregroundStyle(Theme.ink)
                    }
                }
            }
            .position(x: 170, y: 296)
        }
    }
}
