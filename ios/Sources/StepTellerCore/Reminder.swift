import Foundation

/// Text of a notification.
public struct ReminderContent: Sendable, Equatable {
    public let title: String
    public let body: String
    public init(title: String, body: String) { self.title = title; self.body = body }
}

/// What a notification says, without text: the case and the numbers. The app composes the text in the phone's
/// language from the catalog (`ReminderScheduler`); `italian` gives the Italian one, used by the tests.
public enum ReminderMessage: Sendable, Equatable {
    /// Streak warning appended to the precise text.
    public enum Warning: Sendable, Equatable {
        /// If the goal is not reached tonight a Jolly is spent; `jollyLeft` = how many would remain.
        case wouldUseJolly(jollyLeft: Int)
        /// Without a Jolly the `streak`-day streak breaks.
        case wouldBreak(streak: Int)
    }

    /// Today: minutes at the chosen speed to reach the goal.
    case precise(minutes: Int, speed: Double, goal: Int, remaining: Int, warning: Warning?)
    /// Future days, when the steps are not known yet.
    case generic

    /// Italian text (the same the app shows in Italian).
    public var italian: ReminderContent {
        switch self {
        case let .precise(minutes, speed, goal, remaining, warning):
            var body = "Ti servono \(minutes) min a \(ItalianFormat.number(speed, decimals: 1)) km/h "
                + "per chiudere i \(ItalianFormat.integer(goal)) passi (mancano \(ItalianFormat.integer(remaining)))."
            switch warning {
            case let .wouldUseJolly(left)?: body += " Se non chiudi, stasera usi un Jolly (ne restano \(left))."
            case let .wouldBreak(streak)?: body += " Senza Jolly, la streak di \(streak) giorni si interrompe."
            case nil: break
            }
            return ReminderContent(title: "Minuti sul tappeto", body: body)
        case .generic:
            return ReminderContent(title: "È ora del tappeto?", body: "Apri NEAT per vedere quanti minuti ti servono stasera.")
        }
    }
}

/// A notification to schedule.
public struct ReminderRequest: Sendable, Equatable {
    public let id: String          // one identifier per day: `stepteller.reminder.2026-10-08`
    public let fire: DateComponents
    public let message: ReminderMessage
    /// Italian text.
    public var content: ReminderContent { message.italian }
}

/// Evening reminder: decides what to schedule. No dependency on UserNotifications (testable).
public enum ReminderPlanner {
    /// Precise message with tonight's minutes; `nil` if the goal is already reached.
    public static func message(for plan: Plan, streak: StreakState? = nil) -> ReminderMessage? {
        message(for: plan, warning: streak.flatMap(warning(for:)))
    }

    /// Same, with the streak warning already decided (the widget keeps the one the app saved: it depends on
    /// the past days, not on today's count).
    public static func message(for plan: Plan, warning: ReminderMessage.Warning?) -> ReminderMessage? {
        guard !plan.isDone else { return nil }
        return .precise(minutes: plan.minutes, speed: plan.speed, goal: plan.goal, remaining: plan.remaining, warning: warning)
    }

    /// Streak warning for tonight, if any.
    public static func warning(for streak: StreakState) -> ReminderMessage.Warning? {
        if streak.todayWouldUseJolly { return .wouldUseJolly(jollyLeft: streak.jolly - 1) }
        if streak.todayWouldBreak { return .wouldBreak(streak: streak.streak) }
        return nil
    }

    /// Identifier of the notification of a day: `stepteller.reminder.2026-10-08` (app and widget use the same).
    public static func identifier(for day: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "stepteller.reminder.%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Next time the reminder fires: today if still ahead, otherwise tomorrow.
    public static func nextFire(now: Date, minutesFromMidnight: Int, calendar: Calendar) -> Date? {
        let hour = minutesFromMidnight / 60, minute = minutesFromMidnight % 60
        for offset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            if fire > now { return fire }
        }
        return nil
    }

    /// Precise Italian text; `nil` if the goal is already reached.
    public static func content(for plan: Plan, streak: StreakState? = nil) -> ReminderContent? {
        message(for: plan, streak: streak)?.italian
    }

    /// Italian text for future days, when the steps are not known yet.
    public static func genericContent() -> ReminderContent { ReminderMessage.generic.italian }

    /// Notifications to schedule for the next `days` days (today included).
    /// - Today: precise message, only if the time is still ahead and the goal is not reached.
    /// - Following days: generic message (replaced by the precise one when that day becomes «today»).
    public static func schedule(now: Date, minutesFromMidnight: Int, plan: Plan, streak: StreakState? = nil,
                                calendar: Calendar, days: Int = 7) -> [ReminderRequest] {
        let hour = minutesFromMidnight / 60, minute = minutesFromMidnight % 60
        var result: [ReminderRequest] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { continue }
            let message = offset == 0 ? Self.message(for: plan, streak: streak) : .generic
            guard let message else { continue }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            result.append(ReminderRequest(id: identifier(for: fire, calendar: calendar), fire: parts, message: message))
        }
        return result
    }
}
