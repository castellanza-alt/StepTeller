import Foundation

/// Roast notifications (T-022 §1, §3): between 10:00 and 20:00, at times that change every day, never two less than
/// 90 minutes apart; how many by level and Settings; none once the goal is reached. iOS does not wake the app every
/// hour, so at every opening and Health wake-up the app plans the rest of the day with the lines for the steps of
/// that moment, and plans again when new steps arrive. Pure: same input and seed, same plan.
public enum RoastPlan {
    public static let firstMinute = 10 * 60
    public static let lastMinute = 20 * 60
    public static let minGapMinutes = 90
    /// Identifier prefix: not the reminder's nor the events', so each family is withdrawn on its own.
    public static let notificationPrefix = "stepteller.roast."

    /// One notification to schedule.
    public struct Item: Equatable, Sendable {
        public let date: Date
        public let quote: NastyQuote
        /// `notificationPrefix` + day + time: the same slot keeps its identifier when planned again.
        public let id: String
    }

    /// How many a day: NASTY 4–5 and Piccante 1–2 with «Normali» (T-022 §1); «Poche» and «Tante» one step down
    /// and up. At most 7: 6 gaps of 90 minutes fill the 10:00–20:00 window.
    public static func countRange(_ level: NastyLevel, _ frequency: RoastFrequency) -> ClosedRange<Int> {
        switch (level, frequency) {
        case (.normale, _): 0...0
        case (.piccante, .poche): 1...1
        case (.piccante, .normali): 1...2
        case (.piccante, .tante): 2...3
        case (.nasty, .poche): 2...3
        case (.nasty, .normali): 4...5
        case (.nasty, .tante): 6...7
        }
    }

    /// Minutes from midnight of the day's notifications: how many and when come only from the seed, so planning again
    /// during the day finds the same times. Spread at random with at least `minGapMinutes` between two.
    public static func minutes(level: NastyLevel, frequency: RoastFrequency, seed: UInt64) -> [Int] {
        var rng = SeededRandom(seed: seed)
        let range = countRange(level, frequency)
        guard range.upperBound > 0 else { return [] }
        let count = Int.random(in: range, using: &rng)
        let slack = (lastMinute - firstMinute) - (count - 1) * minGapMinutes
        guard slack >= 0 else { return [] }
        let offsets = (0..<count).map { _ in Int.random(in: 0...slack, using: &rng) }.sorted()
        return offsets.enumerated().map { firstMinute + $0.element + $0.offset * minGapMinutes }
    }

    /// Seed of a day: the same all day long, different every day; `salt` (random, kept on the phone) makes two
    /// phones differ.
    public static func seed(day: String, salt: UInt64) -> UInt64 {
        SeededRandom.seed("roast.\(day)") ^ salt
    }

    /// Notifications still to come today, after `now` and at least `minGapMinutes` after the last one delivered.
    /// Lines of «Notifiche» for the numbers of now, preferably without `{passi}`, different from each other and
    /// from the recent ones: when no such line is left, fewer notifications (never the same one twice). Empty with
    /// Normale, with the goal reached or without a goal. The ones already scheduled are the app's to withdraw when
    /// the goal is reached (`notificationPrefix`).
    public static func plan(now: Date, calendar: Calendar, level: NastyLevel, frequency: RoastFrequency,
                            catalog: NastyCatalog, day: NastyMoment.Day, lastDelivered: Date?, memory: NastyMemory,
                            salt: UInt64, format: (Int) -> String = ItalianFormat.integer) -> [Item] {
        guard level != .normale, day.goal > 0, !day.reached else { return [] }
        let dayKey = DayKey.of(now, calendar: calendar)
        let seed = seed(day: dayKey, salt: salt)
        let start = calendar.startOfDay(for: now)
        let earliest = lastDelivered.map { $0.addingTimeInterval(TimeInterval(minGapMinutes * 60)) }
        var rng = SeededRandom(seed: seed &+ 1)
        var seen = memory
        var out: [Item] = []
        for minute in minutes(level: level, frequency: frequency, seed: seed) {
            // the clock time, also on the days the clock changes (adding minutes to midnight would be an hour off)
            guard let date = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: start), date > now,
                  earliest.map({ date >= $0 }) ?? true else { continue }
            var moment = NastyMoment.of(.notification, day: day)
            moment.minuteOfDay = minute
            guard let quote = NastyPicker.pick(catalog, level: level, moment: moment, memory: seen, avoiding: [.passi],
                                               allowRecent: false, format: format, using: &rng) else { continue }
            seen.record(quote.id, level: level)
            out.append(Item(date: date, quote: quote,
                            id: notificationPrefix + dayKey + String(format: ".%02d%02d", minute / 60, minute % 60)))
        }
        return out
    }
}
