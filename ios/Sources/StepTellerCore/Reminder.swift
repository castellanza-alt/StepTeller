import Foundation

/// Testo di una notifica.
public struct ReminderContent: Sendable, Equatable {
    public let title: String
    public let body: String
    public init(title: String, body: String) { self.title = title; self.body = body }
}

/// Cosa dice una notifica, senza testo: il caso e i numeri. Il testo nella lingua del telefono lo compone
/// l'app con il catalogo (`ReminderScheduler`); `italian` dà quello italiano, usato dai test.
public enum ReminderMessage: Sendable, Equatable {
    /// Avviso sulla serie aggiunto al testo preciso.
    public enum Warning: Sendable, Equatable {
        /// Se l'obiettivo non si chiude stasera si usa un Jolly; `jollyLeft` = quelli che resterebbero.
        case wouldUseJolly(jollyLeft: Int)
        /// Senza Jolly la serie di `streak` giorni si interrompe.
        case wouldBreak(streak: Int)
    }

    /// Oggi: minuti alla velocità scelta per chiudere l'obiettivo.
    case precise(minutes: Int, speed: Double, goal: Int, remaining: Int, warning: Warning?)
    /// Giorni futuri, quando i passi non si conoscono ancora.
    case generic

    /// Testo italiano (lo stesso dell'app in italiano).
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

/// Una notifica da programmare.
public struct ReminderRequest: Sendable, Equatable {
    public let id: String          // un identificatore per giorno: `stepteller.reminder.2026-10-08`
    public let fire: DateComponents
    public let message: ReminderMessage
    /// Testo italiano.
    public var content: ReminderContent { message.italian }
}

/// Promemoria serale: decide cosa programmare. Nessuna dipendenza da UserNotifications (testabile).
public enum ReminderPlanner {
    /// Messaggio preciso con i minuti di stasera; `nil` se l'obiettivo è già chiuso.
    public static func message(for plan: Plan, streak: StreakState? = nil) -> ReminderMessage? {
        guard !plan.isDone else { return nil }
        var warning: ReminderMessage.Warning?
        if let streak {
            if streak.todayWouldUseJolly { warning = .wouldUseJolly(jollyLeft: streak.jolly - 1) }
            else if streak.todayWouldBreak { warning = .wouldBreak(streak: streak.streak) }
        }
        return .precise(minutes: plan.minutes, speed: plan.speed, goal: plan.goal, remaining: plan.remaining, warning: warning)
    }

    /// Testo italiano preciso; `nil` se l'obiettivo è già chiuso.
    public static func content(for plan: Plan, streak: StreakState? = nil) -> ReminderContent? {
        message(for: plan, streak: streak)?.italian
    }

    /// Testo italiano per i giorni futuri, quando i passi non si conoscono ancora.
    public static func genericContent() -> ReminderContent { ReminderMessage.generic.italian }

    /// Notifiche da programmare per i prossimi `days` giorni (oggi compreso).
    /// - Oggi: messaggio preciso, solo se l'ora è ancora nel futuro e l'obiettivo non è chiuso.
    /// - Giorni successivi: messaggio generico (verrà sostituito dal preciso quando quel giorno sarà «oggi»).
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
            let id = String(format: "stepteller.reminder.%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
            result.append(ReminderRequest(id: id, fire: parts, message: message))
        }
        return result
    }
}
