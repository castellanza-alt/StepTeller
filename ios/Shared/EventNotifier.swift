import Foundation
import OSLog
import UserNotifications
import StepTellerCore

/// Notifications of goal reached, Jolly earned and Jolly spent (D-038), shared by the app and the widget.
/// Who sees an event first tells it: the app (open, Health background delivery, background wake-up before the
/// reminder) or the widget (refreshed often by iOS, reads Health by itself). The `EventLedger` in the App Group
/// says what was already told; the identifier of the notification is the event's, and a request already
/// pending or delivered is never added again: app and widget together cannot double it.
enum EventNotifier {
    /// Console (Mac, filter `subsystem:it.castellanza.stepteller category:events`).
    static let log = Logger(subsystem: "it.castellanza.stepteller", category: "events")

    /// The ledger as saved, started today if it never existed.
    static func ledger(now: Date, calendar: Calendar) -> EventLedger {
        var ledger = SharedStore.eventLedger ?? EventLedger()
        StreakEvents.start(&ledger, now: now, calendar: calendar)
        return ledger
    }

    /// Saves merging with what the other process may have written meanwhile, without the old identifiers.
    static func save(_ ledger: EventLedger, now: Date, calendar: Calendar) {
        var merged = ledger.merged(with: SharedStore.eventLedger ?? EventLedger())
        merged.prune(before: DayKey.of(now, minusDays: StreakEvents.keepDays, calendar: calendar))
        SharedStore.eventLedger = merged
    }

    /// Tells the events not told yet. Every event is marked as told even when no notification goes out:
    /// switched off in Settings, notifications not allowed, app on screen (the celebration and the pop-up tell
    /// it there), goal at night. A Jolly event at night is scheduled for 08:00.
    /// - Parameters: `steps` and `goal`: today's count and goal, for the goal text.
    static func notify(_ candidates: [StreakEvent], steps: Int, goal: Int, appActive: Bool,
                       now: Date = Date(), calendar: Calendar = .current) async {
        // read, mark and save first: the shorter the window between reading and writing, the less app and
        // widget can both pick the same event (and then the identifier check below stops the second one)
        var ledger = ledger(now: now, calendar: calendar)
        let events = candidates.filter { !ledger.notified.contains($0.id) }
        guard !events.isEmpty else { return }
        ledger.notified.formUnion(events.map(\.id))
        save(ledger, now: now, calendar: calendar)

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let allowed = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        guard SharedStore.eventsOn, allowed, !appActive else {
            log.notice("events: \(events.map(\.id)) marked, not sent (on: \(SharedStore.eventsOn), allowed: \(allowed), app open: \(appActive))")
            return
        }
        let pending = Set(await center.pendingNotificationRequests().map(\.identifier))
        let delivered = Set(await center.deliveredNotifications().map(\.request.identifier))
        for event in events {
            let id = StreakEvents.notificationID(event)
            guard !pending.contains(id), !delivered.contains(id) else { continue }
            var trigger: UNNotificationTrigger?
            if event.kind == .goalReached {
                guard !StreakEvents.isNight(now, calendar: calendar) else {
                    log.notice("events: \(event.id) at night, not sent")
                    continue
                }
                // tonight's reminder is not needed any more: never goal and reminder together
                center.removePendingNotificationRequests(withIdentifiers: [ReminderPlanner.identifier(for: now, calendar: calendar)])
            } else if let morning = StreakEvents.morningDelivery(after: now, calendar: calendar) {
                trigger = UNCalendarNotificationTrigger(dateMatching: morning, repeats: false)
            }
            let text = EventText.notification(event, steps: steps, goal: goal)
            let content = UNMutableNotificationContent()
            content.title = text.title
            content.body = text.body
            content.sound = .default
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            log.notice("events: \(event.id) sent\(trigger == nil ? "" : " for 08:00")")
        }
    }

    /// The pop-up of these events was shown: their notification, if still waiting for the morning or still in
    /// Notification Center, is not needed any more.
    static func withdraw(_ events: [StreakEvent]) {
        let ids = events.map(StreakEvents.notificationID)
        guard !ids.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
}

/// Texts of the goal and Jolly notifications in the phone's language («Widget» table: app and widget).
/// Provisional drafts (T-006): the final texts come from the design (T-005).
enum EventText {
    static func notification(_ event: StreakEvent, steps: Int, goal: Int) -> ReminderContent {
        let t = L10n.widget
        switch event.kind {
        case .goalReached:
            return ReminderContent(title: L10n.text("n.goal.title", table: t),
                                   body: L10n.format("n.goal.body", table: t, LocalFormat.integer(steps), LocalFormat.integer(goal)))
        case .jollyEarned:
            return ReminderContent(title: L10n.text("n.earned.title", table: t),
                                   body: L10n.format("n.earned.body", table: t, "\(event.streak)", "\(event.jolly)"))
        case .jollyUsed:
            return ReminderContent(title: L10n.text("n.used.title", table: t),
                                   body: L10n.format("n.used.body", table: t, "\(event.streak)", "\(event.jolly)"))
        }
    }
}
