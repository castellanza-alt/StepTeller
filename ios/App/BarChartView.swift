import SwiftUI
import StepTellerCore

enum HistoryMetric { case steps, km }

/// Grafico a barre dello storico. Passi: linea tratteggiata dell'obiettivo (solo grafici a giorni);
/// barra piena = obiettivo raggiunto, contorno = oggi/periodo in corso, assenti = punto sottile.
struct BarChartView: View {
    let bars: [HistoryBar]
    let metric: HistoryMetric
    let period: HistoryPeriod

    private func value(_ b: HistoryBar) -> Double { metric == .steps ? Double(b.steps) : b.km }

    var body: some View {
        let showGoal = metric == .steps && (period == .week || period == .month)
        let goal = Double(bars.last(where: { !$0.isFuture })?.goal ?? bars.first?.goal ?? 0)
        let maxValue = max(bars.map(value).max() ?? 1, showGoal ? goal : 0, 1)
        VStack(spacing: 6) {
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottom) {
                    if showGoal && goal > 0 {
                        Path { p in
                            let y = h - h * CGFloat(goal / (maxValue * 1.08))
                            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Theme.ink.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        Text(ItalianFormat.integer(Int(goal)))
                            .font(.system(size: 9)).tracking(0.9).foregroundStyle(Theme.ink.opacity(0.45))
                            .position(x: geo.size.width - 18, y: h - h * CGFloat(goal / (maxValue * 1.08)) - 8)
                    }
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(bars) { b in
                            bar(b, h: h, maxValue: maxValue)
                        }
                    }
                }
            }
            .frame(height: 122)
            labels
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Grafico: \(bars.count) barre")
    }

    private var spacing: CGFloat { period == .month ? 2.5 : (period == .week ? 10 : 8) }
    private var maxBarWidth: CGFloat { period == .week ? 30 : (period == .month ? 12 : 22) }

    @ViewBuilder
    private func bar(_ b: HistoryBar, h: CGFloat, maxValue: Double) -> some View {
        let height = max(3, h * CGFloat(value(b) / (maxValue * 1.08)))
        let radius: CGFloat = period == .month ? 3 : 7
        Group {
            if b.isFuture {
                RoundedRectangle(cornerRadius: 2).fill(Theme.ink.opacity(0.14)).frame(height: 3)
            } else if b.isCurrent {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.accent.opacity(0.22))
                    .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.accent.opacity(0.7), lineWidth: 1))
                    .frame(height: height)
            } else if b.goal == 0 || b.reachedGoal {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.accent.opacity(0.9)).frame(height: height)
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.ink.opacity(0.22)).frame(height: height)
            }
        }
        .frame(maxWidth: maxBarWidth)
        .frame(maxWidth: .infinity)
    }

    private var labels: some View {
        HStack(spacing: spacing) {
            ForEach(bars) { b in
                Text(showLabel(b) ? b.label : "")
                    .font(.system(size: 10, weight: .semibold)).tracking(1)
                    .foregroundStyle(b.isCurrent ? Theme.accent : Theme.soft)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
        }
    }

    /// Mese: solo alcuni giorni (1, 8, 15, 22, ultimo); gli altri periodi: tutte le etichette.
    private func showLabel(_ b: HistoryBar) -> Bool {
        guard period == .month else { return true }
        return [0, 7, 14, 21, bars.count - 1].contains(b.id)
    }
}
