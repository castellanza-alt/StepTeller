import HealthKit
import SwiftUI
import WidgetKit
import StepTellerCore

/// Widget «Passi di oggi» nello stile «Dan Dan Dan»: piccolo e medio in Home (tema giorno/notte secondo
/// l'aspetto del sistema) e, sul blocco schermo, tondo, rettangolare e in linea. Un tocco apre la Home.
struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepsWidget", provider: StepsTimelineProvider()) { entry in
            StepsWidgetEntryView(data: entry.data)
                .widgetURL(URL(string: "stepteller://oggi"))
        }
        .configurationDisplayName(L10n.text("w.gallery.name", table: L10n.widget))
        .description(L10n.text("w.gallery.desc", table: L10n.widget))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

/// Sceglie la grafica in base al formato.
struct StepsWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let data: WidgetSnapshot

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockCircular(plan: data.plan).containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            LockRectangular(data: data).containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Label(data.plan.map { L10n.format("w.inline", table: L10n.widget, LocalFormat.integer($0.steps)) }
                  ?? L10n.text("w.inline.none", table: L10n.widget), systemImage: "flame.fill")
                .containerBackground(for: .widget) { Color.clear }
        case .systemMedium:
            WidgetThemed { WidgetMediumView(data: data) }.containerBackground(for: .widget) { WidgetPaper() }
        default:
            WidgetThemed { WidgetSmallView(data: data) }.containerBackground(for: .widget) { WidgetPaper() }
        }
    }
}

struct StepsEntry: TimelineEntry {
    let date: Date
    let data: WidgetSnapshot
}

struct StepsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), data: WidgetSnapshot(plan: Plan(goal: 10_000, steps: 3_465, speed: SpeedTrack.defaultSpeed),
                                                      streak: 14, jolly: 2))
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
        let plan = steps.map {
            // stessa velocità del cursore in Home e stesso modello di cadenza tarato dell'app
            Plan(goal: SharedStore.goal, steps: $0, speed: SharedStore.speed, model: SharedStore.calibration.model)
        }
        return StepsEntry(date: now, data: WidgetSnapshot(plan: plan, streak: SharedStore.streak, jolly: SharedStore.jolly))
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
