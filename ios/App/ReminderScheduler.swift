import Foundation
import UserNotifications
import StepTellerCore

/// Programma le notifiche locali del promemoria serale. Tutto resta sul telefono.
struct ReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private static let prefix = "stepteller.reminder."

    /// Chiede il permesso se non è mai stato chiesto. Restituisce `true` se le notifiche sono consentite.
    func requestIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Sostituisce tutte le notifiche del promemoria con quelle calcolate.
    func apply(_ requests: [ReminderRequest]) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        for r in requests {
            let text = Self.text(r.message)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: r.fire, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
        }
    }

    /// Testo della notifica nella lingua del telefono: una frase intera del catalogo per ogni caso.
    static func text(_ message: ReminderMessage) -> ReminderContent {
        switch message {
        case let .precise(minutes, speed, goal, remaining, warning):
            let args: [CVarArg] = ["\(minutes)", LocalFormat.number(speed, decimals: 1),
                                   LocalFormat.integer(goal), LocalFormat.integer(remaining)]
            let body: String
            switch warning {
            case let .wouldUseJolly(left)?:
                body = L10n.format("n.body.jolly", arguments: args + ["\(left)"])
            case let .wouldBreak(streak)?:
                body = L10n.format("n.body.lose", arguments: args + ["\(streak)"])
            case nil:
                body = L10n.format("n.body", arguments: args)
            }
            return ReminderContent(title: L10n.text("n.title"), body: body)
        case .generic:
            return ReminderContent(title: L10n.text("n.generic.title"), body: L10n.text("n.generic.body"))
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
    }
}
