import Foundation
import UserNotifications
import StepTellerCore

/// Schedules the local notifications of the evening reminder. Everything stays on the phone.
struct ReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private static let prefix = "stepteller.reminder."

    /// Asks for permission if never asked. Returns `true` if notifications are allowed.
    func requestIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Replaces all reminder notifications with the computed ones.
    func apply(_ requests: [ReminderRequest], unit: DistanceUnit) async {
        await removePending()
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
        for r in requests {
            let text = ReminderText.content(r.message, unit: unit)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: r.fire, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
        }
    }

    func cancelAll() async { await removePending() }

    /// Removes only the reminder notifications (prefix `stepteller.reminder.`), not any other.
    private func removePending() async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
    }
}
