import Foundation
import StepTellerCore

extension HistoryLabels {
    /// Etichette dello Storico nella lingua del telefono: in italiano quelle di sempre (`italian`), nelle altre
    /// lingue nomi dei mesi, iniziali e intervalli di date scritti da iOS.
    static var current: HistoryLabels { LocalFormat.isItalian ? .italian : system(locale: .current) }

    static func system(locale: Locale) -> HistoryLabels {
        var cal = Calendar.current
        cal.locale = locale
        let weekdays = cal.veryShortStandaloneWeekdaySymbols          // da domenica
        return HistoryLabels(
            weekdayLetters: Array(weekdays[1...] + weekdays[..<1]),
            monthLetters: cal.veryShortStandaloneMonthSymbols,
            week: { start, end, cal in
                let sameMonth = cal.component(.month, from: start) == cal.component(.month, from: end)
                return interval(start, end, template: sameMonth ? "dMMMM" : "dMMM", locale: locale, calendar: cal)
            },
            month: { date, cal in capitalizedFirst(formatDate(date, template: "MMMMy", locale: locale, calendar: cal), locale) },
            day: { date, cal in formatDate(date, template: "dMMMy", locale: locale, calendar: cal) },
            weekRange: { start, end, cal in interval(start, end, template: "dMMMy", locale: locale, calendar: cal) },
            span: { start, end, cal in
                let sameMonth = cal.isDate(start, equalTo: end, toGranularity: .month)
                return interval(start, end, template: sameMonth ? "dMMMy" : "MMMy", locale: locale, calendar: cal)
            }
        )
    }

    private static func formatDate(_ date: Date, template: String, locale: Locale, calendar: Calendar) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.setLocalizedDateFormatFromTemplate(template)
        return f.string(from: date)
    }

    private static func interval(_ start: Date, _ end: Date, template: String, locale: Locale, calendar: Calendar) -> String {
        let f = DateIntervalFormatter()
        f.locale = locale
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.dateTemplate = template
        return f.string(from: start, to: end)
    }

    private static func capitalizedFirst(_ text: String, _ locale: Locale) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased(with: locale) + text.dropFirst()
    }
}
