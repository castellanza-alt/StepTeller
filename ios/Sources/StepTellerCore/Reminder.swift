import Foundation

/// Testo di una notifica.
public struct ReminderContent: Sendable, Equatable {
    public let title: String
    public let body: String
}

/// Una notifica da programmare.
public struct ReminderRequest: Sendable, Equatable {
    public let id: String          // un identificatore per giorno: `stepteller.reminder.2026-10-08`
    public let fire: DateComponents
    public let content: ReminderContent
}

/// Promemoria serale: decide cosa programmare. Nessuna dipendenza da UserNotifications (testabile).
public enum ReminderPlanner {
    /// Testo preciso con i minuti di stasera; `nil` se l'obiettivo è già chiuso.
    public static func content(for plan: Plan) -> ReminderContent? {
        guard !plan.isDone else { return nil }
        let body = "Ti servono \(plan.minutes) min a \(ItalianFormat.number(plan.speed, decimals: 1)) km/h "
            + "per chiudere i \(ItalianFormat.integer(plan.goal)) passi (mancano \(ItalianFormat.integer(plan.remaining)))."
        return ReminderContent(title: "Minuti sul tappeto", body: body)
    }

    /// Testo per i giorni futuri, quando i passi non si conoscono ancora.
    public static func genericContent() -> ReminderContent {
        ReminderContent(title: "È ora del tappeto?", body: "Apri Step Teller per vedere quanti minuti ti servono stasera.")
    }

    /// Notifiche da programmare per i prossimi `days` giorni (oggi compreso).
    /// - Oggi: testo preciso, solo se l'ora è ancora nel futuro e l'obiettivo non è chiuso.
    /// - Giorni successivi: testo generico (verrà sostituito dal preciso quando quel giorno sarà «oggi»).
    public static func schedule(now: Date, minutesFromMidnight: Int, plan: Plan,
                                calendar: Calendar, days: Int = 7) -> [ReminderRequest] {
        let hour = minutesFromMidnight / 60, minute = minutesFromMidnight % 60
        var result: [ReminderRequest] = []
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { continue }
            let content = offset == 0 ? Self.content(for: plan) : Self.genericContent()
            guard let content else { continue }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let id = String(format: "stepteller.reminder.%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
            result.append(ReminderRequest(id: id, fire: parts, content: content))
        }
        return result
    }
}
