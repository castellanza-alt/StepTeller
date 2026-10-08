import Foundation

/// Passi e distanza di un giorno (valori aggregati da Salute).
public struct DayRecord: Sendable, Equatable {
    /// Inizio del giorno (calendario del dispositivo).
    public let day: Date
    public let steps: Int
    public let km: Double
    public init(day: Date, steps: Int, km: Double) {
        self.day = day
        self.steps = steps
        self.km = km
    }
}

/// Fornitore dello storico giornaliero (in app: HealthKit; nei test e negli screenshot: finto).
public protocol HistoryProvider: Sendable {
    /// Tutti i giorni con dati, dal primo disponibile a `now`.
    func dailyRecords(until now: Date) async -> [DayRecord]
}

/// Obiettivo giornaliero nel tempo: cambiare l'obiettivo vale **da oggi**, i giorni passati
/// restano valutati con l'obiettivo che c'era allora.
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

    /// Obiettivo valido nel giorno `day`.
    public func goal(on day: Date) -> Int {
        entries.last(where: { $0.from <= day })?.goal ?? entries.first?.goal ?? 10_000
    }

    /// Imposta un nuovo obiettivo a partire dal giorno `day` (ignora se uguale a quello in vigore).
    public mutating func set(_ newGoal: Int, from day: Date) {
        let value = max(0, newGoal)
        if goal(on: day) == value { return }
        entries.removeAll { $0.from >= day }
        entries.append(Entry(from: day, goal: value))
    }
}
