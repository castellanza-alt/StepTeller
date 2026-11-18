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
    private(set) var goals: GoalHistory
    private(set) var stats: HistoryStats
    /// Personal records of `stats`, computed once per update (the History screen reads them at every body).
    private(set) var personalRecords: PersonalRecords
    private(set) var streak = StreakState()
    /// End of the last reread from Health: the celebration waits for a history read after the app came up.
    private(set) var refreshedAt: Date?
    /// First day of the streak count (first launch of this version, or the one kept in iCloud).
    private(set) var streakStart: Date
    /// The last reread from Health returned days: the streak is real and its events can be announced. With the
    /// phone locked Health answers nothing, and an empty history would look like days missed (Jollies spent).
    private(set) var eventsReady = false
    /// Christmas gifts received (`JollyGift`, D-040): their days enter the Jolly count.
    private(set) var gifts: JollyGift.Ledger

    @ObservationIgnored private let provider: (any HistoryProvider)?
    @ObservationIgnored private let defaults: UserDefaults
    /// Follows the phone's time zone (see `StepsStore`).
    @ObservationIgnored private let calendar = Calendar.autoupdatingCurrent
    @ObservationIgnored private var lastRefresh: Date?
    /// Today's steps as read by the app (see `updateToday`); valid for the current day only.
    @ObservationIgnored private var todayLive: (day: Date, steps: Int)?
    /// Until the first read from Health the streak shown is the one saved by the previous launch: computing
    /// it from an empty history would flash 0 (and push 0 to the widget).
    @ObservationIgnored private var showsCachedStreak = false

    private enum Keys {
        static let goals = "stepteller.goalHistory"
        static let start = "stepteller.streak.start"
        /// `[season: day]`; also in iCloud (`CloudBackup`, merged) and in the App Group.
        static let gifts = "stepteller.jollyGifts"
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
            let today = cal.startOfDay(for: Date())
            streakStart = today
            defaults.set(today, forKey: Keys.start)
        }
        gifts = Self.savedGifts(defaults)
        let empty = HistoryStats(records: [], goals: loadedGoals, now: Date(), calendar: cal, labels: .current)
        stats = empty
        personalRecords = empty.personalRecords()
        if provider != nil, let cached = SharedStore.cachedStreak {
            var seeded = StreakState()
            seeded.streak = cached.streak
            seeded.jolly = cached.jolly
            streak = seeded
            showsCachedStreak = true
        } else {
            recompute()
        }
    }

    /// Rereads the history from Health (at most every `minInterval` seconds).
    func refresh(minInterval: TimeInterval = 0) async {
        guard let provider else { return }
        if minInterval > 0, let last = lastRefresh, Date().timeIntervalSince(last) < minInterval { return }
        lastRefresh = Date()
        let result = await provider.dailyRecords(until: Date())
        records = result
        eventsReady = !result.isEmpty
        showsCachedStreak = false
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

    /// The copies of the gifts on this phone (app and App Group), merged: a season received in either stays.
    private static func savedGifts(_ defaults: UserDefaults) -> JollyGift.Ledger {
        let here = JollyGift.Ledger(days: defaults.dictionary(forKey: Keys.gifts) as? [String: String] ?? [:])
        return here.merged(with: SharedStore.jollyGifts)
    }

    private func saveGifts(_ ledger: JollyGift.Ledger) {
        gifts = ledger
        if (defaults.dictionary(forKey: Keys.gifts) as? [String: String]) != ledger.days {
            defaults.set(ledger.days, forKey: Keys.gifts)
        }
        if SharedStore.jollyGifts != ledger { SharedStore.jollyGifts = ledger }
    }

    /// Opening of the app: the Christmas gift, if due now (25/12–6/1, not received this season). Saved before
    /// it is shown, so it is never given twice. Returns `true` when given.
    func claimGift(now: Date) -> Bool {
        var ledger = Self.savedGifts(defaults).merged(with: gifts)
        let given = JollyGift.claim(&ledger, now: now, calendar: calendar)
        #if DEBUG
        // simulated date (`-stepteller.debugNow`): the fake history is on the real days, so the gift is counted
        // on the real today, otherwise it would be in the future and the pop-up would show the Jollies without it
        if given, UserDefaults.standard.object(forKey: "stepteller.debugNow") != nil,
           let season = JollyGift.season(of: now, calendar: calendar) {
            ledger.days[String(season)] = DayKey.of(Date(), calendar: calendar)
        }
        #endif
        saveGifts(ledger)
        if given { recompute() }
        return given
    }

    /// Goal history and streak start brought back from iCloud after a reinstall (see `CloudBackup`).
    func reloadSaved() {
        if let saved = defaults.data(forKey: Keys.goals).flatMap({ try? JSONDecoder().decode(GoalHistory.self, from: $0) }) {
            goals = saved
        }
        if let saved = defaults.object(forKey: Keys.start) as? Date { streakStart = saved }
        saveGifts(Self.savedGifts(defaults).merged(with: gifts))
        recompute()
    }

    /// Manual backup import: the file's goal history replaces this one, the streak start keeps the earliest.
    func importBackup(goals imported: GoalHistory?, streakStart importedStart: Date?, gifts importedGifts: [String: String]?) {
        if let importedGifts { saveGifts(gifts.merged(with: JollyGift.Ledger(days: importedGifts))) }
        if let imported, let data = try? JSONEncoder().encode(imported) { defaults.set(data, forKey: Keys.goals) }
        if let start = BackupFile.mergedStreakStart(current: streakStart, imported: importedStart) {
            defaults.set(start, forKey: Keys.start)
        }
        reloadSaved()
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
        guard !showsCachedStreak else { return }
        var steps = stats.byDay.mapValues(\.steps)
        let today = calendar.startOfDay(for: now)
        if let live = todayLive, live.day == today { steps[today] = max(steps[today] ?? 0, live.steps) }
        streak = StreakEngine.compute(start: streakStart, initialJolly: Self.initialJolly, steps: steps,
                                      goals: goals, gifts: JollyGift.days(gifts, calendar: calendar), now: now,
                                      calendar: calendar)
        if eventsReady {
            // the widget tells «goal reached» (and the Jolly it earns) with these numbers (see WidgetEvents)
            let reach = StreakEvents.reach(streak, now: now, calendar: calendar)
            if SharedStore.goalReach != reach { SharedStore.goalReach = reach }
        }
        if SharedStore.streak != streak.streak || SharedStore.jolly != streak.jolly {
            SharedStore.streak = streak.streak            // streak and Jollies for the widget
            SharedStore.jolly = streak.jolly
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
