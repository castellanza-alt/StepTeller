import ActivityKit
import Foundation
import StepTellerCore

/// Avvia, aggiorna e chiude la Live Activity del tappeto. Tutto locale: nessuna notifica push.
@MainActor
final class LiveActivityController {
    private var activity: Activity<TreadmillActivityAttributes>?

    init() {
        // Riaggancia un'attività rimasta attiva da un avvio precedente.
        activity = Activity<TreadmillActivityAttributes>.activities.first
    }

    var isRunning: Bool { activity != nil }
    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(plan: Plan) {
        guard isAvailable, activity == nil else { return }
        let attributes = TreadmillActivityAttributes(goal: plan.goal)
        let content = ActivityContent(state: state(for: plan), staleDate: staleDate(for: plan))
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    /// Ricalcola la fine in base ai passi e alla velocità attuali.
    func update(plan: Plan) async {
        guard let activity else { return }
        if plan.isDone {
            await end(plan: plan)
            return
        }
        await activity.update(ActivityContent(state: state(for: plan), staleDate: staleDate(for: plan)))
    }

    /// Chiude l'attività (a obiettivo chiuso resta visibile qualche minuto con «Fatto»).
    func end(plan: Plan?) async {
        guard let activity else { return }
        self.activity = nil
        if let plan, plan.isDone {
            await activity.end(ActivityContent(state: state(for: plan), staleDate: nil),
                               dismissalPolicy: .after(Date().addingTimeInterval(300)))
        } else {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func state(for plan: Plan) -> TreadmillActivityAttributes.ContentState {
        .init(endDate: Date().addingTimeInterval(Double(plan.minutes) * 60), speed: plan.speed,
              remainingSteps: plan.remaining, gait: plan.gait.label, finished: plan.isDone)
    }

    private func staleDate(for plan: Plan) -> Date {
        Date().addingTimeInterval(Double(plan.minutes) * 60 + 600)
    }
}
