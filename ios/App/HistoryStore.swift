import Foundation
import Observation
import StepTellerCore

/// Segno di un giorno nel calendario.
enum CalendarMark {
    case reached, saved, todayOpen, missed, future
}

/// Storico giornaliero, streak e Jolly. Tutto è **calcolato** dai dati di Salute (nessun archivio
/// proprio dei passi): si salvano solo l'inizio del conteggio e lo storico degli obiettivi.
@MainActor
@Observable
final class HistoryStore {
    static let initialJolly = 3

    private(set) var records: [DayRecord] = []
    private(set) var goals: GoalHistory
    private(set) var stats: HistoryStats
    private(set) var streak = StreakState()
    private(set) var loaded = false
    /// Primo giorno del conteggio della streak (primo avvio di questa versione).
    let streakStart: Date

    @ObservationIgnored private let provider: (any HistoryProvider)?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar = Calendar.current
    @ObservationIgnored private var lastRefresh: Date?
    /// Passi di oggi letti dall'app (vedi `updateToday`); vale solo per il giorno in corso.
    @ObservationIgnored private var todayLive: (day: Date, steps: Int)?

    private enum Keys {
        static let goals = "stepteller.goalHistory"
        static let start = "stepteller.streak.start"
    }

    init(provider: (any HistoryProvider)?, currentGoal: Int, defaults: UserDefaults = .standard,
         streakStartOverride: Date? = nil) {
        self.provider = provider
        self.defaults = defaults
        let cal = Calendar.current
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
        stats = HistoryStats(records: [], goals: loadedGoals, now: Date(), calendar: cal)
        recompute()
    }

    /// Rilegge lo storico da Salute (al massimo ogni `minInterval` secondi).
    func refresh(minInterval: TimeInterval = 0) async {
        guard let provider else { return }
        if minInterval > 0, let last = lastRefresh, Date().timeIntervalSince(last) < minInterval { return }
        lastRefresh = Date()
        let result = await provider.dailyRecords(until: Date())
        records = result
        loaded = true
        recompute()
    }

    /// Passi di oggi già letti dall'app: la streak scatta appena si supera l'obiettivo, senza
    /// aspettare la rilettura dello storico (che è più lenta e limitata a una ogni 20 s).
    func updateToday(steps: Int) {
        let day = calendar.startOfDay(for: Date())
        if let live = todayLive, live.day == day, live.steps == steps { return }
        todayLive = (day, steps)
        recompute()
    }

    /// Il nuovo obiettivo vale da oggi.
    func recordGoal(_ goal: Int) {
        goals.set(goal, from: calendar.startOfDay(for: Date()))
        if let data = try? JSONEncoder().encode(goals) { defaults.set(data, forKey: Keys.goals) }
        recompute()
    }

    private func recompute() {
        let now = Date()
        stats = HistoryStats(records: records, goals: goals, now: now, calendar: calendar)
        var steps = Dictionary(records.map { (calendar.startOfDay(for: $0.day), $0.steps) }, uniquingKeysWith: { a, _ in a })
        let today = calendar.startOfDay(for: now)
        if let live = todayLive, live.day == today { steps[today] = max(steps[today] ?? 0, live.steps) }
        streak = StreakEngine.compute(start: streakStart, initialJolly: Self.initialJolly, steps: steps,
                                      goals: goals, now: now, calendar: calendar)
        stepsByDay = steps
    }

    @ObservationIgnored private var stepsByDay: [Date: Int] = [:]

    /// Segno del calendario per un giorno. Prima dell'inizio della streak non esistono Jolly:
    /// conta solo se l'obiettivo era raggiunto.
    func mark(for day: Date) -> CalendarMark {
        let d = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())
        if d > today { return .future }
        if let status = streak.statuses[d] {
            switch status {
            case .reached: return .reached
            case .saved: return .saved
            case .missed: return .missed
            case .inProgress: return .todayOpen
            }
        }
        let steps = stepsByDay[d] ?? 0
        let goal = goals.goal(on: d)
        return goal > 0 && steps >= goal ? .reached : .missed
    }
}
