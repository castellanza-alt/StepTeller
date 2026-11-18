import Foundation

/// Christmas Jolly gift (D-040, `docs/design/T-015-natale.md` §4): +1 Jolly at the first opening of the app from
/// 25 December 00:00 (local time) to 6 January included, once per season, every year. A gift, not a decoration:
/// it does not depend on the «Seasonal themes» switch.
///
/// What is saved is only the fact «gift of season YYYY received on day D» (`Ledger`), in the App Group, in iCloud and
/// in the Backup. The Jolly itself is never saved: like every Jolly it is counted by `StreakEngine`, which receives
/// the days of the gifts and adds one Jolly at the start of each of those days.
public enum JollyGift {
    /// Gift window: 25/12 – 6/1, whole days in the phone's calendar.
    public static let start = (month: 12, day: 25)
    public static let end = (month: 1, day: 6)

    /// Season of the gift a date belongs to: the year of its December (6/1/2027 → 2026), `nil` outside the window.
    /// Gregorian numbers in the calendar's time zone, like `DayKey`.
    public static func season(of date: Date, calendar: Calendar) -> Int? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else { return nil }
        if month == start.month, day >= start.day { return year }
        if month == end.month, day <= end.day { return year - 1 }
        return nil
    }

    /// Gifts received: season (the December's year, as text) → day received (`DayKey`). A plain dictionary of
    /// strings, so it goes as it is into UserDefaults, the App Group and the iCloud key-value store.
    public struct Ledger: Codable, Equatable, Sendable {
        public var days: [String: String]

        public init(days: [String: String] = [:]) { self.days = days }

        public func received(season: Int) -> Bool { days[String(season)] != nil }

        /// Union of two copies (this phone, iCloud, a Backup): a season received anywhere stays received; if both
        /// have it, the earlier day wins (one gift per season, never two).
        public func merged(with other: Ledger) -> Ledger {
            Ledger(days: days.merging(other.days) { min($0, $1) })
        }
    }

    /// The opening at `now` claims the gift if it is due: inside the window and not received this season.
    /// Returns `true` and marks it in `ledger` when given.
    @discardableResult
    public static func claim(_ ledger: inout Ledger, now: Date, calendar: Calendar) -> Bool {
        guard let season = season(of: now, calendar: calendar), !ledger.received(season: season) else { return false }
        ledger.days[String(season)] = DayKey.of(now, calendar: calendar)
        return true
    }

    /// Start of the days of the gifts in `calendar`, for `StreakEngine.compute(gifts:)`. Unreadable keys are skipped.
    public static func days(_ ledger: Ledger, calendar: Calendar) -> [Date] {
        ledger.days.values.compactMap { DayKey.date($0, calendar: calendar) }.sorted()
    }
}

extension DayKey {
    /// Start of the day of a key (`yyyy-MM-dd`, Gregorian) in the calendar's time zone; `nil` if unreadable.
    public static func date(_ key: String, calendar: Calendar) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        guard let date = gregorian.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) else { return nil }
        return calendar.startOfDay(for: date)
    }
}
