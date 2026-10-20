import Foundation
import Observation
import WidgetKit
import StepTellerCore

/// Daily history, streak and Jollies. Everything is **computed** from Health data (no step archive of its
/// own): only the start of the count and the goal history are saved.
@MainActor
@Observable
final class HistoryStore {
    static let initialJolly = 3

    private var records: [DayRecord] = []
    private var goals: GoalHistory
    private(set) var stats: HistoryStats
    /// Personal records of `stats`, computed once per update (the History screen reads them at every body).
    private(set) var personalRecords: PersonalRecords
    private(set) var streak = StreakState()
    /// End of the last reread from Health: the celebration waits for a history read after the app came up.
    private(set) var refreshedAt: Date?
    /// First day of the streak count (first launch of this version).
    let streakStart: Date

    @ObservationIgnored private let provider: (any HistoryProvider)?
    @ObservationIgnored private let defaults: UserDefaults
    /// Follows the phone's time zone (see `StepsStore`).
    @ObservationIgnored private let calendar = Calendar.autoupdatingCurrent
    @ObservationIgnored private var lastRefresh: Date?
    /// Today's steps as read by the app (see `updateToday`); valid for the current day only.
    @ObservationIgnored private var todayLive: (day: Date, steps: Int)?

    private enum Keys {
        static let goals = "stepteller.goalHistory"
        static let start = "stepteller.streak.start"
    }

    init(provider: (any HistoryProvider)?, currentGoal: Int, defaults: UserDefaults = .standard,
         streakStartOverride: Date? = nil) {
        self.provider = provider
        self.defaults = defaults
        let cal = Calendar.autoupdatingCurrent
        let loadedGoals = defaults.data(forKey: Keys.goals).flatMap { try? JSONDecoder().decode(GoalHistory.self, from: $0) }
            ?? GoalHistory(initialGoal: currentGoal)
        goals = loadedGoals
        if let override = streakStartOverride {
            streakStart = cal.startOfDay(for: override)
        } else if let saved = defaults.object(forKey: Keys.start) as? Date {
            streakStart = saved
        } else {
            streakStart = cal.startOfDay(for: Date())
            defaults.set(streakStart, forKey: Keys.start)
        }
        let empty = HistoryStats(records: [], goals: loadedGoals, now: Date(), calendar: cal, labels: .current)
        stats = empty
        personalRecords = empty.personalRecords()
        recompute()
    }

    /// Rereads the history from Health (at most every `minInterval` seconds).
    func refresh(minInterval: TimeInterval = 0) async {
        guard let provider else { return }
        if minInterval > 0, let last = lastRefresh, Date().timeIntervalSince(last) < minInterval { return }
        lastRefresh = Date()
        let result = await provider.dailyRecords(until: Date())
        records = result
        recompute()
        refreshedAt = Date()
    }

    /// Today's steps already read by the app: the streak updates as soon as the goal is passed, without
    /// waiting for the history reread (slower and limited to one every 20 s).
    func updateToday(steps: Int) {
        let day = calendar.startOfDay(for: Date())
        if let live = todayLive, live.day == day, live.steps == steps { return }
        todayLive = (day, steps)
        recompute()
    }

    /// The new goal applies from today.
    func recordGoal(_ goal: Int) {
        goals.set(goal, from: calendar.startOfDay(for: Date()))
        if let data = try? JSONEncoder().encode(goals) { defaults.set(data, forKey: Keys.goals) }
        recompute()
    }

    private func recompute() {
        let now = Date()
        stats = HistoryStats(records: records, goals: goals, now: now, calendar: calendar, labels: .current)
        personalRecords = stats.personalRecords()
        var steps = stats.byDay.mapValues(\.steps)
        let today = calendar.startOfDay(for: now)
        if let live = todayLive, live.day == today { steps[today] = max(steps[today] ?? 0, live.steps) }
        streak = StreakEngine.compute(start: streakStart, initialJolly: Self.initialJolly, steps: steps,
                                      goals: goals, now: now, calendar: calendar)
        if SharedStore.streak != streak.streak || SharedStore.jolly != streak.jolly {
            SharedStore.streak = streak.streak            // streak and Jollies for the widget
            SharedStore.jolly = streak.jolly
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
