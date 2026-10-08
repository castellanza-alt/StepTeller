import Foundation

/// Esito di un giorno nel calcolo della streak.
public enum DayStatus: Sendable, Equatable {
    case reached       // obiettivo raggiunto
    case saved         // mancato ma salvato da un Jolly
    case missed        // mancato (streak interrotta, o niente da salvare)
    case inProgress    // oggi, obiettivo non ancora raggiunto
}

public struct StreakState: Sendable, Equatable {
    /// Giorni consecutivi a obiettivo (oggi incluso se già raggiunto).
    public var streak = 0
    /// Streak più lunga dall'inizio del conteggio.
    public var longest = 0
    /// Jolly disponibili.
    public var jolly = 0
    public var jollyEarned = 0
    public var jollyUsed = 0
    /// Giorni riusciti consecutivi dall'ultimo Jolly maturato o speso (0…14).
    public var counter = 0
    public var statuses: [Date: DayStatus] = [:]
    public var todayReached = false
    /// Oggi non ancora riuscito e c'è una streak da salvare: a mezzanotte parte un Jolly.
    public var todayWouldUseJolly = false
    /// Oggi non ancora riuscito, c'è una streak e nessun Jolly: a mezzanotte si interrompe.
    public var todayWouldBreak = false

    public var daysToNextJolly: Int { StreakEngine.jollyEvery - counter }
    public init() {}
}

/// Regole (decise con Will, 8 ottobre 2026):
/// - un giorno è riuscito se i passi ≥ obiettivo di quel giorno; oggi non rompe mai la streak;
/// - ogni 15 giorni riusciti consecutivi matura 1 Jolly (nessun tetto);
/// - un giorno mancato con streak > 0 consuma 1 Jolly, se disponibile: la streak resta, **non cresce**
///   e il conto verso il prossimo Jolly riparte da 0;
/// - un giorno mancato senza Jolly azzera la streak (e il conto); il record resta.
/// Nessun Jolly viene speso quando la streak è 0: non c'è nulla da salvare.
public enum StreakEngine {
    public static let jollyEvery = 15

    /// - Parameters:
    ///   - start: primo giorno del conteggio (inizio del giorno).
    ///   - steps: passi per giorno (chiave = inizio del giorno); giorni assenti = 0.
    public static func compute(start: Date, initialJolly: Int = 3, steps: [Date: Int],
                               goals: GoalHistory, now: Date, calendar: Calendar) -> StreakState {
        var s = StreakState()
        s.jolly = initialJolly
        let first = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        guard first <= today else { return s }

        func apply(reached: Bool, day: Date) {
            if reached {
                s.streak += 1
                s.counter += 1
                s.longest = max(s.longest, s.streak)
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
        // oggi: provvisorio
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
