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
    func apply(_ requests: [ReminderRequest]) async {
        await removePending()
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

    /// Notification text in the phone's language: one whole sentence from the catalog per case.
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

    func cancelAll() async { await removePending() }

    /// Removes only the reminder notifications (prefix `stepteller.reminder.`), not any other.
    private func removePending() async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) })
    }
}
