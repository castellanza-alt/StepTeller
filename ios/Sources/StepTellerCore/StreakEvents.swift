import Foundation

/// Day of the device calendar as `yyyy-MM-dd`. Events are named by this key, not by a `Date`: after a change of
/// time zone the start of the same day is another instant, the key stays the same (no event repeated).
/// Always Gregorian numbers in the calendar's time zone: a phone set to the Japanese or Buddhist calendar would
/// otherwise write other years, and changing calendar would make old keys look new.
public enum DayKey {
    public static func of(_ date: Date, calendar: Calendar) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Key of the day `days` before the day of `date` (negative: after).
    public static func of(_ date: Date, minusDays days: Int, calendar: Calendar) -> String {
        of(calendar.date(byAdding: .day, value: -days, to: date) ?? date, calendar: calendar)
    }
}

/// Something worth telling once (D-038): goal reached today, Jolly earned, Jolly spent.
public struct StreakEvent: Hashable, Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case goalReached = "goal"
        case jollyEarned = "earned"
        case jollyUsed = "used"
    }

    public let kind: Kind
    /// Day of the event (`DayKey`): today for the goal, the 15th day for an earned Jolly, the missed day for a
    /// spent one (detected after midnight, so usually yesterday).
    public let day: String
    /// Streak and Jollies available now (after the event), for the text.
    public let streak: Int
    public let jolly: Int

    public init(kind: Kind, day: String, streak: Int, jolly: Int) {
        self.kind = kind; self.day = day; self.streak = streak; self.jolly = jolly
    }

    /// Stable name: one event per kind and day (a day either reaches the goal or is missed, so at most one
    /// Jolly per day changes hands). Also the notification identifier, after `StreakEvents.notificationPrefix`.
    public var id: String { "\(kind.rawValue).\(day)" }
    public var isJolly: Bool { kind != .goalReached }
}

/// What has already been announced. Streak and Jollies are never saved (they are computed from Health): only
/// the identifiers of the events already told are. Saved in the App Group, shared by app and widget.
public struct EventLedger: Codable, Equatable, Sendable {
    /// First day this ledger existed (`DayKey`). Events of earlier days are never announced: after installing,
    /// reinstalling or updating, the past (also the one brought back by iCloud) is not news.
    public var since: String?
    /// Events already notified (or that did not need a notification: app open, night, switched off).
    public var notified: Set<String> = []
    /// Jolly events whose pop-up was already shown.
    public var shown: Set<String> = []

    public init(since: String? = nil) { self.since = since }

    /// Union of two copies written by different processes (app and widget): nothing announced is forgotten.
    public func merged(with other: EventLedger) -> EventLedger {
        var out = self
        if let a = since, let b = other.since { out.since = min(a, b) } else { out.since = since ?? other.since }
        out.notified.formUnion(other.notified)
        out.shown.formUnion(other.shown)
        return out
    }

    /// Drops identifiers of days before `oldest` (older than any window: they can no longer come back).
    public mutating func prune(before oldest: String) {
        func recent(_ id: String) -> Bool { (id.split(separator: ".").last.map(String.init) ?? "") >= oldest }
        notified = notified.filter(recent)
        shown = shown.filter(recent)
    }

    public func encoded() -> Data? { try? JSONEncoder().encode(self) }
    public static func decoded(_ data: Data?) -> EventLedger? {
        data.flatMap { try? JSONDecoder().decode(EventLedger.self, from: $0) }
    }
}

/// Events from the streak and the rules to announce them once (D-038). Pure functions: the app and the widget
/// decide what to send, the tests check every case.
public enum StreakEvents {
    /// Prefix of the notification identifiers (`stepteller.event.goal.2026-11-17`): not `stepteller.reminder.`,
    /// so the evening reminder never removes them.
    public static let notificationPrefix = "stepteller.event."
    /// Notifications: today and yesterday only (a Jolly spent last night is detected this morning).
    public static let notifyDays = 1
    /// Pop-ups: Jolly events of the last week (whoever opens the app after a few days still finds out).
    public static let popupDays = 7
    /// Identifiers kept in the ledger.
    public static let keepDays = 30
    /// Night: from 22:00 to 08:00 no notification sounds. The goal is not told at night; a Jolly event is
    /// moved to 08:00.
    public static let nightStartHour = 22
    public static let nightEndHour = 8

    /// Events in a streak state (all of them, also old: the windows are applied by `toNotify`/`toShow`).
    /// Valid only when the state comes from a real Health read: an empty history would look like missed days.
    public static func events(in state: StreakState, now: Date, calendar: Calendar) -> [StreakEvent] {
        var out: [StreakEvent] = []
        func add(_ kind: StreakEvent.Kind, _ day: Date) {
            out.append(StreakEvent(kind: kind, day: DayKey.of(day, calendar: calendar), streak: state.streak, jolly: state.jolly))
        }
        for day in state.jollyEarnedDays { add(.jollyEarned, day) }
        for (day, status) in state.statuses where status == .saved { add(.jollyUsed, day) }
        if state.todayReached { add(.goalReached, now) }
        return out.sorted { ($0.day, $0.kind.rawValue) < ($1.day, $1.kind.rawValue) }
    }

    /// Starts the ledger on its first day (see `EventLedger.since`).
    public static func start(_ ledger: inout EventLedger, now: Date, calendar: Calendar) {
        if ledger.since == nil { ledger.since = DayKey.of(now, calendar: calendar) }
    }

    /// Events to notify now: not notified yet, not before the ledger started, inside the window. The goal only
    /// for today. Does not mark them: the caller marks what it sent (`ledger.notified`).
    public static func toNotify(_ events: [StreakEvent], ledger: EventLedger, now: Date, calendar: Calendar) -> [StreakEvent] {
        let today = DayKey.of(now, calendar: calendar)
        let oldest = max(DayKey.of(now, minusDays: notifyDays, calendar: calendar), ledger.since ?? today)
        return events.filter { e in
            !ledger.notified.contains(e.id) && e.day >= oldest && (e.kind != .goalReached || e.day == today)
        }
    }

    /// Jolly events whose pop-up was not shown yet (last `popupDays` days, not before the ledger started).
    public static func toShow(_ events: [StreakEvent], ledger: EventLedger, now: Date, calendar: Calendar) -> [StreakEvent] {
        let today = DayKey.of(now, calendar: calendar)
        let oldest = max(DayKey.of(now, minusDays: popupDays, calendar: calendar), ledger.since ?? today)
        return events.filter { $0.isJolly && !ledger.shown.contains($0.id) && $0.day >= oldest }
    }

    public static func isNight(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= nightStartHour || hour < nightEndHour
    }

    /// When a Jolly notification should sound: now (`nil`) by day, at 08:00 if it is night.
    public static func morningDelivery(after now: Date, calendar: Calendar) -> DateComponents? {
        guard isNight(now, calendar: calendar) else { return nil }
        let base = calendar.component(.hour, from: now) >= nightStartHour
            ? calendar.date(byAdding: .day, value: 1, to: now) ?? now : now
        guard let fire = calendar.date(bySettingHour: nightEndHour, minute: 0, second: 0, of: base) else { return nil }
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
    }

    /// Several events found together (the app was closed for days): one pop-up per kind, the latest one with
    /// how many there were. Order of the design (T-005 §1.1): «Jolly used», then «Jolly earned» (the goal
    /// celebration comes after both).
    public static func popups(_ events: [StreakEvent]) -> [(event: StreakEvent, count: Int)] {
        let order: [StreakEvent.Kind] = [.jollyUsed, .jollyEarned]
        return order.compactMap { kind in
            let list = events.filter { $0.kind == kind }
            return list.max { $0.day < $1.day }.map { ($0, list.count) }
        }
    }

    /// Jollies to show on each pop-up of a queue shown in this order (T-018): the last one shows `final` (the
    /// Jollies now), each one before it what there was before the next one changed it. `deltas`: change of each
    /// pop-up (gift +1, earned +N, used −N). Never below 0.
    public static func stepCounts(final: Int, deltas: [Int]) -> [Int] {
        var out = Array(repeating: final, count: deltas.count)
        var after = final
        for i in deltas.indices.reversed() {
            out[i] = max(0, after)
            after -= deltas[i]
        }
        return out
    }

    /// What reaching today's goal means, as the app computes it, for the widget (which does not read the history)
    /// to tell it: streak and Jollies after reaching it, and whether it earns a Jolly (15th day in a row).
    public struct Reach: Equatable, Sendable {
        public let day: String
        public let streak: Int
        public let jolly: Int
        public let earnsJolly: Bool

        public init(day: String, streak: Int, jolly: Int, earnsJolly: Bool) {
            self.day = day; self.streak = streak; self.jolly = jolly; self.earnsJolly = earnsJolly
        }

        /// `2026-11-17|23|3|1`, for the App Group.
        public var encoded: String { "\(day)|\(streak)|\(jolly)|\(earnsJolly ? 1 : 0)" }
        public init?(encoded: String?) {
            let p = (encoded ?? "").split(separator: "|").map(String.init)
            guard p.count == 4, let s = Int(p[1]), let j = Int(p[2]) else { return nil }
            self.init(day: p[0], streak: s, jolly: j, earnsJolly: p[3] == "1")
        }
    }

    public static func reach(_ state: StreakState, now: Date, calendar: Calendar) -> Reach {
        let today = DayKey.of(now, calendar: calendar)
        if state.todayReached {
            let earned = state.jollyEarnedDays.last.map { DayKey.of($0, calendar: calendar) == today } ?? false
            return Reach(day: today, streak: state.streak, jolly: state.jolly, earnsJolly: earned)
        }
        return Reach(day: today, streak: state.streak + 1, jolly: state.jolly + (state.todayWouldEarnJolly ? 1 : 0),
                     earnsJolly: state.todayWouldEarnJolly)
    }

    /// Identifier of the notification of an event.
    public static func notificationID(_ event: StreakEvent) -> String { notificationPrefix + event.id }
}
