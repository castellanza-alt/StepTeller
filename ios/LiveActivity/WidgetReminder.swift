import Foundation
import OSLog
import UserNotifications
import StepTellerCore

/// The widget keeps tonight's reminder true. A local notification is text written in advance by the app, and
/// iOS wakes the app in the background at most once an hour: the count in the text can be hours old by the
/// time it fires (10.000 steps walked, «mancano 497» on the lock screen). The widget instead is refreshed by
/// iOS much more often and reads Health itself: with a fresh count it cancels the notification when the goal
/// is reached, or rewrites its numbers. Only the notification the app already scheduled for today is touched:
/// nothing is created here. (An app extension can edit the containing app's pending notifications: verified.)
enum WidgetReminder {
    /// Console (Mac, filter `subsystem:it.castellanza.stepteller`): what the widget did to tonight's reminder.
    private static let log = Logger(subsystem: "it.castellanza.stepteller", category: "reminder")

    static func update(freshSteps: Int, now: Date, calendar: Calendar = .current) async {
        guard SharedStore.reminderOn else { return }
        let id = ReminderPlanner.identifier(for: now, calendar: calendar)
        let center = UNUserNotificationCenter.current()
        guard let pending = await center.pendingNotificationRequests().first(where: { $0.identifier == id }),
              let trigger = pending.trigger else { log.notice("widget: no reminder pending for today"); return }
        let plan = Plan(goal: SharedStore.goal, steps: freshSteps, speed: SharedStore.speed,
                        model: SharedStore.calibration.model)
        guard let message = ReminderPlanner.message(for: plan, warning: SharedStore.reminderWarning) else {
            center.removePendingNotificationRequests(withIdentifiers: [id])     // goal reached: no reminder tonight
            log.notice("widget: goal reached with \(freshSteps) steps, reminder cancelled")
            return
        }
        let text = ReminderText.content(message, unit: Units.current)
        guard text.body != pending.content.body else { log.notice("widget: reminder already up to date"); return }
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        content.sound = .default
        // same identifier and trigger: the request replaces the old one
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        log.notice("widget: reminder rewritten with \(freshSteps) steps")
    }

    /// When the widget should refresh next: the usual 15 minutes, or 10 minutes before the reminder if that
    /// comes first, so the notification gets a fresh count right before it fires.
    static func nextRefresh(now: Date, calendar: Calendar = .current) -> Date {
        let usual = now.addingTimeInterval(15 * 60)
        guard SharedStore.reminderOn,
              let fire = ReminderPlanner.nextFire(now: now, minutesFromMidnight: SharedStore.reminderMinutes, calendar: calendar)
        else { return usual }
        let before = fire.addingTimeInterval(-10 * 60)
        return before > now.addingTimeInterval(60) ? min(usual, before) : usual
    }
}
