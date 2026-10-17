import SwiftUI
import StepTellerCore

/// Calendario del mese (settimana da lunedì): obiettivo = cerchio rosso pieno, Jolly = rombo rosso,
/// oggi = cerchio a matita, futuro = numero tenue.
struct CalendarGrid: View {
    /// Primo giorno del mese.
    let monthStart: Date
    let mark: (Date) -> CalendarMark
    let today: Date

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    var body: some View {
        let cal = calendar
        let days = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let weekday = (cal.component(.weekday, from: monthStart) + 5) % 7   // lunedì = 0
        VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(["L", "M", "M", "G", "V", "S", "D"].enumerated()), id: \.offset) { _, l in
                    Text(l).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink.opacity(0.8))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<(weekday + days), id: \.self) { i in
                    if i < weekday {
                        Color.clear.frame(width: 34, height: 34)
                    } else {
                        let d = cal.date(byAdding: .day, value: i - weekday, to: monthStart) ?? monthStart
                        cell(day: i - weekday + 1, mark: mark(d), isToday: cal.isDate(d, inSameDayAs: today))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(day: Int, mark: CalendarMark, isToday: Bool) -> some View {
        let text = Text("\(day)").font(.system(size: 15, weight: .semibold)).monospacedDigit()
        Group {
            switch mark {
            case .reached:
                text.foregroundStyle(Theme.onAccent)
                    .frame(width: 34, height: 34)
                    .background(InkCircle(fill: Theme.accent))
                    .overlay { if isToday { Circle().strokeBorder(Theme.ink, lineWidth: 2).padding(-3) } }
            case .saved:
                text.foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)
                    .background(DiamondShape().fill(Theme.bg).overlay(DiamondShape().stroke(Theme.accent, lineWidth: 2)))
            case .todayOpen:
                text.foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34).overlay(Circle().strokeBorder(Theme.ink, lineWidth: 2.2))
            case .missed:
                text.foregroundStyle(Theme.ink).frame(width: 34, height: 34)
            case .future:
                text.foregroundStyle(Theme.ink.opacity(0.35)).frame(width: 34, height: 34)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day), \(label(mark))")
    }

    private func label(_ m: CalendarMark) -> String {
        switch m {
        case .reached: "obiettivo raggiunto"
        case .saved: "salvato da un Jolly"
        case .todayOpen: "oggi, in corso"
        case .missed: "obiettivo non raggiunto"
        case .future: "giorno futuro"
        }
    }
}

/// Cerchio pieno con un bordo a matita leggermente spostato (aspetto disegnato a mano).
private struct InkCircle: View {
    let fill: Color
    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(fill.opacity(0.6), lineWidth: 1.2).offset(x: 0.8, y: -0.6)
            Circle().fill(RadialGradient(colors: [.white.opacity(0.25), .clear], center: UnitPoint(x: 0.3, y: 0.25),
                                         startRadius: 0, endRadius: 14))
        }
    }
}
