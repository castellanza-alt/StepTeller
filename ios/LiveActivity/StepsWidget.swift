import HealthKit
import SwiftUI
import WidgetKit
import StepTellerCore

/// «Today's steps» widget in the «Dan Dan Dan» style: small and medium on the Home Screen (day/night theme
/// following the system appearance) and, on the lock screen, circular, rectangular and inline. A tap opens Home.
/// On the Apple Watch the same code is the complications: circular, rectangular, inline and corner.
struct StepsWidget: Widget {
    #if os(watchOS)
    static let families: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
    static let galleryDescription = "w.watch.gallery.desc"
    #else
    static let families: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline]
    static let galleryDescription = "w.gallery.desc"
    #endif

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepsWidget", provider: StepsTimelineProvider()) { entry in
            StepsWidgetEntryView(data: entry.data)
                .widgetURL(URL(string: "stepteller://oggi"))
        }
        .configurationDisplayName(L10n.text("w.gallery.name", table: L10n.widget))
        .description(L10n.text(Self.galleryDescription, table: L10n.widget))
        .supportedFamilies(Self.families)
        .contentMarginsDisabled()
    }
}

/// Picks the drawing for the widget family.
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
        #if os(watchOS)
        case .accessoryCorner:
            WatchCorner(plan: data.plan).containerBackground(for: .widget) { Color.clear }
        default:
            LockCircular(plan: data.plan).containerBackground(for: .widget) { Color.clear }
        #else
        case .systemMedium:
            WidgetThemed { WidgetMediumView(data: data) }.containerBackground(for: .widget) { WidgetPaper() }
        default:
            WidgetThemed { WidgetSmallView(data: data) }.containerBackground(for: .widget) { WidgetPaper() }
        #endif
        }
    }
}

#if os(watchOS)
/// Watch face corner: compact steps in Anton, the progress as the curved gauge along the edge.
struct WatchCorner: View {
    let plan: Plan?
    var body: some View {
        AntonText(WidgetText.compactSteps(plan), 20, tracking: -0.02, color: .white, minScale: 0.6)
            .widgetLabel { Gauge(value: min(1, max(0, plan?.progress ?? 0))) { Text("") } }
            .widgetAccentable()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(plan.map { L10n.format("w.vo.steps", table: L10n.widget, LocalFormat.integer($0.steps), LocalFormat.integer($0.goal)) }
                                ?? L10n.text("w.vo.none.short", table: L10n.widget))
    }
}
#endif

struct StepsEntry: TimelineEntry {
    let date: Date
    let data: WidgetSnapshot
}

struct StepsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), data: WidgetSnapshot(plan: Plan(goal: 10_000, steps: 3_465, speed: SpeedTrack.defaultSpeed),
                                                      streak: 14, jolly: 2, unit: Units.current))
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { completion(await entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        Task {
            let e = await entry()
            // iOS decides when to really refresh (about every 15–60 minutes): this is only a hint.
            completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(15 * 60))))
        }
    }

    /// Steps from Health; with the phone locked Health does not answer and the last value saved by the app is used.
    private func entry() async -> StepsEntry {
        let now = Date()
        var steps = await WidgetHealth.todaySteps(now: now)
        if let s = steps { SharedStore.saveSteps(s, now: now) } else { steps = SharedStore.cachedStepsToday(now: now) }
        let plan = steps.map {
            // same speed as the Home slider and the same calibrated cadence model as the app
            Plan(goal: SharedStore.goal, steps: $0, speed: SharedStore.speed, model: SharedStore.calibration.model)
        }
        return StepsEntry(date: now, data: WidgetSnapshot(plan: plan, streak: SharedStore.streak, jolly: SharedStore.jolly,
                                                          unit: Units.current))
    }
}

/// Today's steps (read only, same statistical sum as the app).
enum WidgetHealth {
    static func todaySteps(now: Date, calendar: Calendar = .current) async -> Int? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        return await HealthKitQueries.stepSum(HKHealthStore(), type: HKQuantityType(.stepCount),
                                              from: calendar.startOfDay(for: now), to: now)
    }
}
