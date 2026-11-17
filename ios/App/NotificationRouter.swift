import UserNotifications

/// A tap on a NEAT notification opens the Home (T-005 §2), where the pop-up of the event shows if not seen yet.
/// Only the tap is handled: with the app on screen notifications stay silent, as before (the celebration and the
/// pop-ups tell the events there).
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationRouter()
    @MainActor var onOpen: (() -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { onOpen?() }
    }
}
