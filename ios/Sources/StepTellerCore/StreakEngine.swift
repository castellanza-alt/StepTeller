import Foundation

/// Outcome of one day in the streak computation.
public enum DayStatus: Sendable, Equatable {
    case reached       // goal reached
    case saved         // missed but saved by a Jolly
    case missed        // missed (streak broken, or nothing to save)
    case inProgress    // today, goal not reached yet
}

public struct StreakState: Sendable, Equatable {
    /// Consecutive days at goal (today included once reached).
    public var streak = 0
    /// Longest streak since counting started.
    public var longest = 0
    /// First and last successful day of the longest streak (the most recent one on ties).
    public var longestStart: Date?
    public var longestEnd: Date?
    /// Jollies available.
    public var jolly = 0
    public var jollyEarned = 0
    public var jollyUsed = 0
    /// Consecutive successful days since the last Jolly earned or spent (0…14).
    public var counter = 0
    public var statuses: [Date: DayStatus] = [:]
    public var todayReached = false
    /// Today not reached yet and a streak to save: at midnight a Jolly is spent.
    public var todayWouldUseJolly = false
    /// Today not reached yet, a streak and no Jolly: at midnight it breaks.
    public var todayWouldBreak = false

    public var daysToNextJolly: Int { StreakEngine.jollyEvery - counter }
    public init() {}
}

/// Rules (agreed with Will, 8 October 2026):
/// - a day succeeds if steps ≥ that day's goal; today never breaks the streak;
/// - every 15 consecutive successful days earn 1 Jolly (no cap);
/// - a missed day with streak > 0 spends 1 Jolly, if available: the streak stays, **does not grow**
///   and the count towards the next Jolly restarts from 0;
/// - a missed day without a Jolly resets the streak (and the count); the record stays.
/// No Jolly is spent while the streak is 0: there is nothing to save.
public enum StreakEngine {
    public static let jollyEvery = 15

    /// - Parameters:
    ///   - start: first day of the count (start of day).
    ///   - steps: steps per day (key = start of day); missing days = 0.
    public static func compute(start: Date, initialJolly: Int = 3, steps: [Date: Int],
                               goals: GoalHistory, now: Date, calendar: Calendar) -> StreakState {
        var s = StreakState()
        s.jolly = initialJolly
        var currentStart: Date?
        let first = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        guard first <= today else { return s }

        func apply(reached: Bool, day: Date) {
            if reached {
                if s.streak == 0 { currentStart = day }
                s.streak += 1
                s.counter += 1
                if s.streak >= s.longest {
                    s.longest = s.streak
                    s.longestStart = currentStart
                    s.longestEnd = day
                }
                s.statuses[day] = .reached
                if s.counter == jollyEvery { s.jolly += 1; s.jollyEarned += 1; s.counter = 0 }
            } else if s.streak > 0 && s.jolly > 0 {
                s.jolly -= 1
                s.jollyUsed += 1
                s.counter = 0
                s.statuses[day] = .saved
            } else {
                s.streak = 0
                s.counter = 0
                s.statuses[day] = .missed
            }
        }

        var day = first
        while day < today {
            apply(reached: (steps[day] ?? 0) >= goals.goal(on: day), day: day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        // today: provisional
        if (steps[today] ?? 0) >= goals.goal(on: today) {
            apply(reached: true, day: today)
            s.todayReached = true
        } else {
            s.statuses[today] = .inProgress
            s.todayWouldUseJolly = s.streak > 0 && s.jolly > 0
            s.todayWouldBreak = s.streak > 0 && s.jolly == 0
        }
        return s
    }
}
