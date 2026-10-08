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
            let content = UNMutableNotificationContent()
            content.title = r.content.title
            content.body = r.content.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: r.fire, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
    }
}
