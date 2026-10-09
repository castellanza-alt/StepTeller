import HealthKit
import SwiftUI
import WidgetKit
import StepTellerCore

/// Widget «Passi di oggi»: piccolo in Home (passi, avanzamento, minuti a piedi) e, sul blocco schermo,
/// tondo (arco con i passi), rettangolare (anello con l'omino e i passi) e in linea sopra l'ora.
struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepsWidget", provider: StepsTimelineProvider()) { entry in
            StepsWidgetEntryView(plan: entry.plan)
        }
        .configurationDisplayName("Passi di oggi")
        .description("Passi e avanzamento verso l'obiettivo, anche sul blocco schermo.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

/// Sceglie la grafica in base al formato.
struct StepsWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let plan: Plan?

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockCircular(plan: plan).containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            LockRectangular(plan: plan).containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Label(plan.map { "\(ItalianFormat.integer($0.steps)) passi" } ?? "Passi —", systemImage: "figure.walk")
                .containerBackground(for: .widget) { Color.clear }
        default:
            StepsWidgetView(plan: plan).containerBackground(for: .widget) { StepsWidgetBackground() }
        }
    }
}

/// Blocco schermo, tondo: arco di 270° (come nell'app) con i passi al centro.
struct LockCircular: View {
    let plan: Plan?
    var body: some View {
        Gauge(value: plan?.progress ?? 0) {
            Image(systemName: "figure.walk")
        } currentValueLabel: {
            Text(plan.map { ItalianFormat.integer($0.steps) } ?? "—")
                .font(.system(size: 15, weight: .medium)).monospacedDigit()
                .minimumScaleFactor(0.5).lineLimit(1)
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
        .accessibilityLabel(plan.map { "\(ItalianFormat.integer($0.steps)) passi su \(ItalianFormat.integer($0.goal))" } ?? "Passi non disponibili")
    }
}

/// Blocco schermo, rettangolare: anello con l'omino e, accanto, i passi grandi e l'obiettivo.
struct LockRectangular: View {
    let plan: Plan?
    var body: some View {
        HStack(spacing: 10) {
            Gauge(value: plan?.progress ?? 0) {
                Image(systemName: "figure.walk")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
            VStack(alignment: .leading, spacing: 0) {
                Text(plan.map { ItalianFormat.integer($0.steps) } ?? "—")
                    .font(.system(size: 30, weight: .medium)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(plan.map { "su \(ItalianFormat.integer($0.goal))" } ?? "apri l'app")
                    .font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plan.map { "\(ItalianFormat.integer($0.steps)) passi su \(ItalianFormat.integer($0.goal))" } ?? "Passi non disponibili")
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
