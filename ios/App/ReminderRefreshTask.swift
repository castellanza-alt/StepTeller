import BackgroundTasks
import Foundation
import StepTellerCore

/// Asks iOS to wake the app about 25 minutes before the evening reminder, to recompute it with the current
/// count (Health background delivery is hourly at most, and never with the phone locked). iOS decides whether
/// and when: this is one more chance, not a promise; the widget gives the other (`WidgetReminder`).
enum ReminderRefreshTask {
    static let identifier = "it.castellanza.stepteller.reminder"
    private static let lead: TimeInterval = 25 * 60

    /// At launch, before the app finishes launching (iOS requires it): `store()` gives the store once it exists.
    @MainActor
    static func register(store: @escaping @MainActor () -> StepsStore?) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            let work = Task { @MainActor in
                if let store = store() {
                    await store.refresh()                 // today's steps and, with them, tonight's reminder
                    store.scheduleReminderRefresh()       // the next one (tomorrow, or tonight if this ran early)
                }
                task.setTaskCompleted(success: !Task.isCancelled)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    /// Replaces the pending request with one for `fire` minus the lead; none if the reminder is off.
    static func schedule(before fire: Date?) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        guard let fire else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = max(fire.addingTimeInterval(-lead), Date().addingTimeInterval(60))
        try? BGTaskScheduler.shared.submit(request)
    }
}
