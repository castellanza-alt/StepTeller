import SwiftUI
import StepTellerCore

/// Calendario del mese (settimana da lunedì): obiettivo = cerchio pieno, Jolly = cerchio solo bordo
/// (accent), oggi = bordo chiaro, futuro = numero tenue.
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
                    Text(l).font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(Theme.ink.opacity(0.45))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(0..<(weekday + days), id: \.self) { i in
                    if i < weekday {
                        Color.clear.frame(width: 30, height: 30)
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
        let text = Text("\(day)").font(.system(size: 12, weight: .semibold)).monospacedDigit()
        Group {
            switch mark {
            case .reached:
                text.foregroundStyle(Theme.onAccent)
                    .frame(width: 30, height: 30).background(Circle().fill(Theme.accent))
                    .overlay { if isToday { Circle().strokeBorder(Theme.ink, lineWidth: 1.5).padding(-3) } }
            case .saved:
                text.foregroundStyle(Theme.accent)
                    .frame(width: 30, height: 30).overlay(Circle().strokeBorder(Theme.accent, lineWidth: 1.5))
            case .todayOpen:
                text.foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30).overlay(Circle().strokeBorder(Theme.ink, lineWidth: 1.5))
            case .missed:
                text.foregroundStyle(Theme.ink.opacity(0.55)).frame(width: 30, height: 30)
            case .future:
                text.foregroundStyle(Theme.ink.opacity(0.28)).frame(width: 30, height: 30)
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
