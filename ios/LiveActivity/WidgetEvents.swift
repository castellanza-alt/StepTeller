import Foundation
import UserNotifications
import StepTellerCore

/// The widget tells «goal reached» (and the Jolly it earns, on the 15th day) as soon as its fresh count passes
/// the goal, often before the app gets a chance: iOS refreshes the widget much more than it wakes the app.
/// Spent Jollies need the history (the widget does not read it): the app tells those (`StepsStore.announceEvents`).
enum WidgetEvents {
    static func update(freshSteps: Int, now: Date, calendar: Calendar = .current) async {
        let goal = SharedStore.goal
        guard goal > 0, freshSteps >= goal else { return }
        // goal reached: the roasts still waiting stop here (T-022 §1), only «quando ce la fai» is left
        let center = UNUserNotificationCenter.current()
        let roasts = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(RoastPlan.notificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: roasts)
        let today = DayKey.of(now, calendar: calendar)
        // numbers after reaching the goal, computed by the app for today; without them (app not run today) the
        // streak is unknown (yesterday may have broken it): 0, and the text leaves it out
        let reach = SharedStore.goalReach.flatMap { $0.day == today ? $0 : nil }
        let streak = reach?.streak ?? 0
        let jolly = reach?.jolly ?? SharedStore.jolly
        var events = [StreakEvent(kind: .goalReached, day: today, streak: streak, jolly: jolly)]
        if reach?.earnsJolly == true {
            events.append(StreakEvent(kind: .jollyEarned, day: today, streak: streak, jolly: jolly))
        }
        let due = StreakEvents.toNotify(events, ledger: EventNotifier.ledger(now: now, calendar: calendar), now: now, calendar: calendar)
        await EventNotifier.notify(due, steps: freshSteps, goal: goal, appActive: false, now: now, calendar: calendar)
    }
}
