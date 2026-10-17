import SwiftUI
import StepTellerCore

/// Grafico a barre dei passi «a matita»: barre tratteggiate, rosse se l'obiettivo è raggiunto, nere se no,
/// rosso tenue per il periodo in corso; linea tratteggiata dell'obiettivo con l'etichetta a sinistra
/// (solo grafici a giorni); assi disegnati.
struct SketchBarChart: View {
    let bars: [HistoryBar]
    let period: HistoryPeriod
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0→1 all'apertura e a ogni cambio di periodo: le barre crescono dal basso.
    @State private var grow: CGFloat = 0

    var body: some View {
        let showGoal = period == .week || period == .month
        let goal = Double(bars.last(where: { !$0.isFuture })?.goal ?? bars.first?.goal ?? 0)
        let maxValue = max(Double(bars.map(\.steps).max() ?? 1), showGoal ? goal : 0, 1) * 1.1
        HStack(alignment: .top, spacing: 6) {
            // etichetta dell'obiettivo a sinistra, all'altezza della linea
            GeometryReader { geo in
                if showGoal && goal > 0 {
                    Text(ItalianFormat.integer(Int(goal))).font(.system(size: 13, weight: .medium)).monospacedDigit()
                        .foregroundStyle(Theme.ink).fixedSize()
                        .position(x: geo.size.width / 2, y: geo.size.height * (1 - CGFloat(goal / maxValue)))
                }
            }
            .frame(width: showGoal ? 44 : 0, height: 110)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    let h = geo.size.height
                    ZStack(alignment: .bottomLeading) {
                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(bars) { b in bar(b, h: h, maxValue: maxValue) }
                        }
                        .padding(.horizontal, 6)
                        if showGoal && goal > 0 {
                            Path { p in
                                let y = h * (1 - CGFloat(goal / maxValue))
                                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(Theme.ink.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                        }
                        // assi
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 0, y: h))
                            p.addLine(to: CGPoint(x: geo.size.width, y: h))
                        }
                        .stroke(Theme.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(height: 110)
                labels
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Grafico: \(bars.count) barre, \(bars.filter(\.reachedGoal).count) a obiettivo")
        .onAppear { animateGrow() }
        .onChange(of: bars) { _, _ in animateGrow() }
    }

    private func animateGrow() {
        guard !reduceMotion else { grow = 1; return }
        var reset = Transaction(); reset.disablesAnimations = true
        withTransaction(reset) { grow = 0 }
        DispatchQueue.main.async { withAnimation(.spring(duration: 0.7, bounce: 0.25)) { grow = 1 } }
    }

    private var spacing: CGFloat { period == .month ? 2.5 : (period == .week ? 14 : 8) }
    private var maxBarWidth: CGFloat { period == .week ? 40 : (period == .month ? 12 : 22) }

    @ViewBuilder
    private func bar(_ b: HistoryBar, h: CGFloat, maxValue: Double) -> some View {
        let height = max(3, h * CGFloat(Double(b.steps) / maxValue) * grow)
        Group {
            if b.isFuture {
                Rectangle().fill(Theme.ink.opacity(0.18)).frame(height: 2)
            } else {
                let color: Color = b.isCurrent ? Theme.accent.opacity(0.45)
                    : (b.goal == 0 || b.reachedGoal ? Theme.accent : Theme.ink.opacity(0.72))
                Rectangle().fill(color)
                    .overlay(Hatch(spacing: 3.2).stroke(Theme.bg.opacity(0.45), lineWidth: 0.8).clipped())
                    .overlay(Rectangle().stroke(color, lineWidth: 1))
                    .frame(height: height)
            }
        }
        .frame(maxWidth: maxBarWidth)
        .frame(maxWidth: .infinity)
    }

    private var labels: some View {
        HStack(spacing: spacing) {
            ForEach(bars) { b in
                Text(showLabel(b) ? b.label : "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(b.isCurrent ? Theme.accent : Theme.ink)
                    .lineLimit(1)
                    .fixedSize()                    // le etichette del mese sono più larghe della barra: non vanno ridotte
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
    }

    /// Mese: solo alcuni giorni (1, 8, 15, 22, ultimo); gli altri periodi: tutte le etichette.
    private func showLabel(_ b: HistoryBar) -> Bool {
        guard period == .month else { return true }
        return [0, 7, 14, 21, bars.count - 1].contains(b.id)
    }
}
