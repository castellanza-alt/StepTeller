import Foundation

/// A seasonal theme (D-037): one mechanism for every season, each a value with its period (first and last day
/// included, in the phone's calendar, may cross the new year). The look of each season (colors, particles,
/// accessory, icon) is in the app (`SeasonLook`); here only the dates, which the tests check.
public struct Season: Sendable, Equatable, Hashable {
    public let id: String
    public let startMonth: Int, startDay: Int
    public let endMonth: Int, endDay: Int

    public init(id: String, start: (month: Int, day: Int), end: (month: Int, day: Int)) {
        self.id = id
        startMonth = start.month; startDay = start.day
        endMonth = end.month; endDay = end.day
    }

    /// Christmas: 1 December 00:00 – 6 January 23:59 (Epiphany closes the holidays in Italy).
    public static let christmas = Season(id: "christmas", start: (12, 1), end: (1, 6))
    public static let all: [Season] = [christmas]

    public static func named(_ id: String) -> Season? { all.first { $0.id == id } }

    /// The day of `date` is inside the period (whole days, local time).
    public func contains(_ date: Date, calendar: Calendar) -> Bool {
        let c = calendar.dateComponents([.month, .day], from: date)
        let today = (c.month ?? 0) * 100 + (c.day ?? 0)
        let start = startMonth * 100 + startDay, end = endMonth * 100 + endDay
        return start <= end ? (start...end).contains(today) : (today >= start || today <= end)
    }

    /// The season of a date, if any.
    public static func active(on date: Date, calendar: Calendar) -> Season? {
        all.first { $0.contains(date, calendar: calendar) }
    }
}
