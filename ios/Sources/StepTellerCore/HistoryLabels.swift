import Foundation

/// Date labels of the History screen: period titles, letters under the bars, record dates.
/// `italian` is hand-written and gives the same result on Linux, macOS and iOS (golden tests); for the other
/// languages the app builds one with the system formatters and the phone's language.
public struct HistoryLabels: Sendable {
    /// Weekday initials, Monday to Sunday.
    public var weekdayLetters: [String]
    /// Month initials, January to December.
    public var monthLetters: [String]
    /// Title of a week: «19 – 25 ottobre», «29 set – 5 ott».
    public var week: @Sendable (_ start: Date, _ end: Date, _ calendar: Calendar) -> String
    /// Month and year: «Ottobre 2026».
    public var month: @Sendable (_ date: Date, _ calendar: Calendar) -> String
    /// One day: «17 giu 2026».
    public var day: @Sendable (_ date: Date, _ calendar: Calendar) -> String
    /// Week of a record: «8 – 14 giu 2026», «29 giu – 5 lug 2026».
    public var weekRange: @Sendable (_ start: Date, _ end: Date, _ calendar: Calendar) -> String
    /// Range of days (longest streak): «3 – 17 ott 2026», «giu – set 2024», «dic 2025 – feb 2026».
    public var span: @Sendable (_ start: Date, _ end: Date, _ calendar: Calendar) -> String

    public init(weekdayLetters: [String], monthLetters: [String],
                week: @escaping @Sendable (Date, Date, Calendar) -> String,
                month: @escaping @Sendable (Date, Calendar) -> String,
                day: @escaping @Sendable (Date, Calendar) -> String,
                weekRange: @escaping @Sendable (Date, Date, Calendar) -> String,
                span: @escaping @Sendable (Date, Date, Calendar) -> String) {
        self.weekdayLetters = weekdayLetters
        self.monthLetters = monthLetters
        self.week = week
        self.month = month
        self.day = day
        self.weekRange = weekRange
        self.span = span
    }

    static let monthNames = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
                             "agosto", "settembre", "ottobre", "novembre", "dicembre"]
    static let shortMonths = ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"]

    /// Italian, independent of the device settings.
    public static let italian = HistoryLabels(
        weekdayLetters: ["L", "M", "M", "G", "V", "S", "D"],
        monthLetters: ["G", "F", "M", "A", "M", "G", "L", "A", "S", "O", "N", "D"],
        week: { start, end, cal in
            let a = cal.dateComponents([.day, .month], from: start)
            let b = cal.dateComponents([.day, .month], from: end)
            if a.month == b.month { return "\(a.day!) – \(b.day!) \(monthNames[b.month! - 1])" }
            return "\(a.day!) \(shortMonths[a.month! - 1]) – \(b.day!) \(shortMonths[b.month! - 1])"
        },
        month: { date, cal in
            let c = cal.dateComponents([.year, .month], from: date)
            return monthNames[c.month! - 1].capitalized + " \(c.year!)"
        },
        day: { date, cal in
            let c = cal.dateComponents([.day, .month, .year], from: date)
            return "\(c.day!) \(shortMonths[c.month! - 1]) \(c.year!)"
        },
        weekRange: { start, end, cal in
            let a = cal.dateComponents([.day, .month, .year], from: start)
            let b = cal.dateComponents([.day, .month, .year], from: end)
            return a.month == b.month ? "\(a.day!) – \(b.day!) \(shortMonths[b.month! - 1]) \(b.year!)"
                                      : "\(a.day!) \(shortMonths[a.month! - 1]) – \(b.day!) \(shortMonths[b.month! - 1]) \(b.year!)"
        },
        span: { start, end, cal in
            let a = cal.dateComponents([.day, .month, .year], from: start)
            let b = cal.dateComponents([.day, .month, .year], from: end)
            let ma = shortMonths[a.month! - 1], mb = shortMonths[b.month! - 1]
            if a.year == b.year && a.month == b.month {
                return a.day == b.day ? "\(b.day!) \(mb) \(b.year!)" : "\(a.day!) – \(b.day!) \(mb) \(b.year!)"
            }
            if a.year == b.year { return "\(ma) – \(mb) \(b.year!)" }
            return "\(ma) \(a.year!) – \(mb) \(b.year!)"
        }
    )
}
