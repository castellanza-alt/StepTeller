import Foundation
import StepTellerCore

/// The widget tells «goal reached» (and the Jolly it earns, on the 15th day) as soon as its fresh count passes
/// the goal, often before the app gets a chance: iOS refreshes the widget much more than it wakes the app.
/// Spent Jollies need the history (the widget does not read it): the app tells those (`StepsStore.announceEvents`).
enum WidgetEvents {
    static func update(freshSteps: Int, now: Date, calendar: Calendar = .current) async {
        let goal = SharedStore.goal
        guard goal > 0, freshSteps >= goal else { return }
        let today = DayKey.of(now, calendar: calendar)
        var events = [StreakEvent(kind: .goalReached, day: today, streak: SharedStore.streak, jolly: SharedStore.jolly)]
        if SharedStore.jollyOnReachDay == today {
            // the app saved the streak without today: reaching it adds the day and the Jolly
            events.append(StreakEvent(kind: .jollyEarned, day: today, streak: SharedStore.streak + 1, jolly: SharedStore.jolly + 1))
        }
        let due = StreakEvents.toNotify(events, ledger: EventNotifier.ledger(now: now, calendar: calendar), now: now, calendar: calendar)
        await EventNotifier.notify(due, steps: freshSteps, goal: goal, appActive: false, now: now, calendar: calendar)
    }
}
