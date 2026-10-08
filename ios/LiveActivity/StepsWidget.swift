import HealthKit
import SwiftUI
import WidgetKit
import StepTellerCore

/// Widget piccolo «Passi di oggi»: passi, avanzamento e minuti a piedi che mancano.
struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepsWidget", provider: StepsTimelineProvider()) { entry in
            StepsWidgetView(plan: entry.plan)
                .containerBackground(for: .widget) { StepsWidgetBackground() }
        }
        .configurationDisplayName("Passi di oggi")
        .description("Passi, avanzamento e minuti a piedi che mancano all'obiettivo.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct StepsEntry: TimelineEntry {
    let date: Date
    let plan: Plan?
}

struct StepsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), plan: Plan(goal: 10_000, steps: 7_200, speed: Plan.glanceSpeed))
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { completion(await entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let e = await entry()
            // iOS decide quando aggiornare davvero (circa ogni 15–60 minuti): è solo un suggerimento.
            completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }

    /// Passi da Salute; a telefono bloccato Salute non risponde e si usa l'ultimo valore salvato dall'app.
    private func entry() async -> StepsEntry {
        let now = Date()
        var steps = await WidgetHealth.todaySteps(now: now)
        if let s = steps { SharedStore.saveSteps(s, now: now) } else { steps = SharedStore.cachedStepsToday(now: now) }
        guard let steps else { return StepsEntry(date: now, plan: nil) }
        let plan = Plan(goal: SharedStore.goal, steps: steps, speed: Plan.glanceSpeed, model: SharedStore.calibration.model)
        return StepsEntry(date: now, plan: plan)
    }
}

/// Lettura dei passi di oggi (solo lettura, somma statistica come nell'app).
enum WidgetHealth {
    static func todaySteps(now: Date, calendar: Calendar = .current) async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let store = HKHealthStore()
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: calendar.startOfDay(for: now), end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0.rounded()) })
            }
            store.execute(query)
        }
    }
}
