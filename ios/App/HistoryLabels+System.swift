import Foundation
import StepTellerCore

extension HistoryLabels {
    /// Etichette dello Storico nella lingua del telefono: in italiano quelle di sempre (`italian`), nelle altre
    /// lingue nomi dei mesi, iniziali e intervalli di date scritti da iOS.
    static let current: HistoryLabels = LocalFormat.isItalian ? .italian : system(locale: .current)

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
        FormatterCache.shared.date(template: template, locale: locale, calendar: calendar).string(from: date)
    }

    private static func interval(_ start: Date, _ end: Date, template: String, locale: Locale, calendar: Calendar) -> String {
        FormatterCache.shared.interval(template: template, locale: locale, calendar: calendar).string(from: start, to: end)
    }

    private static func capitalizedFirst(_ text: String, _ locale: Locale) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased(with: locale) + text.dropFirst()
    }
}

/// Formattatori riusati per (modello, lingua, calendario): crearne uno costa 0,1–0,25 ms e un body dello Storico ne
/// chiede 6–8. Un `NSLock` perché le etichette sono closure `@Sendable`; i formattatori di Foundation sono thread-safe.
private final class FormatterCache: @unchecked Sendable {
    static let shared = FormatterCache()
    private let lock = NSLock()
    private var dates: [String: DateFormatter] = [:]
    private var intervals: [String: DateIntervalFormatter] = [:]

    private func key(_ template: String, _ locale: Locale, _ calendar: Calendar) -> String {
        "\(template)|\(locale.identifier)|\(calendar.identifier)|\(calendar.timeZone.identifier)|\(calendar.firstWeekday)"
    }

    func date(template: String, locale: Locale, calendar: Calendar) -> DateFormatter {
        let k = key(template, locale, calendar)
        return lock.withLock {
            if let f = dates[k] { return f }
            let f = DateFormatter()
            f.locale = locale
            f.calendar = calendar
            f.timeZone = calendar.timeZone
            f.setLocalizedDateFormatFromTemplate(template)
            dates[k] = f
            return f
        }
    }

    func interval(template: String, locale: Locale, calendar: Calendar) -> DateIntervalFormatter {
        let k = key(template, locale, calendar)
        return lock.withLock {
            if let f = intervals[k] { return f }
            let f = DateIntervalFormatter()
            f.locale = locale
            f.calendar = calendar
            f.timeZone = calendar.timeZone
            f.dateTemplate = template
            intervals[k] = f
            return f
        }
    }
}
