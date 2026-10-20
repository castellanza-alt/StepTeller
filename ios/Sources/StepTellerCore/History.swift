import Foundation

/// Steps and distance of one day (aggregate values from Health).
public struct DayRecord: Sendable, Equatable {
    /// Start of the day (device calendar).
    public let day: Date
    public let steps: Int
    public let km: Double
    public init(day: Date, steps: Int, km: Double) {
        self.day = day
        self.steps = steps
        self.km = km
    }
}

/// Source of the daily history (app: HealthKit; tests and screenshots: fake).
public protocol HistoryProvider: Sendable {
    /// Every day with data, from the first available to `now`.
    func dailyRecords(until now: Date) async -> [DayRecord]
}

/// Daily goal over time: changing the goal applies **from today**; past days
/// stay judged against the goal in force back then.
public struct GoalHistory: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public var from: Date
        public var goal: Int
        public init(from: Date, goal: Int) { self.from = from; self.goal = goal }
    }

    public private(set) var entries: [Entry]

    public init(initialGoal: Int = 10_000) {
        entries = [Entry(from: .distantPast, goal: max(0, initialGoal))]
    }

    /// Goal in force on `day`.
    public func goal(on day: Date) -> Int {
        entries.last(where: { $0.from <= day })?.goal ?? entries.first?.goal ?? 10_000
    }

    /// Sets a new goal starting on `day` (ignored if equal to the one in force).
    public mutating func set(_ newGoal: Int, from day: Date) {
        let value = max(0, newGoal)
        if goal(on: day) == value { return }
        entries.removeAll { $0.from >= day }
        entries.append(Entry(from: day, goal: value))
    }
}
