import Foundation
import Observation
import WidgetKit
import StepTellerCore

/// State of the watch app: today's steps from Health on the watch (never persisted) and the settings received
/// from the iPhone (`WatchPayload`, kept in the App Group so the complications read them too).
@MainActor
@Observable
final class WatchStore {
    private(set) var state = StepsState()
    private(set) var goal = SharedStore.goal
    private(set) var speed = SharedStore.speed
    private(set) var unitPreference = SharedStore.unitPreference
    private(set) var streak = SharedStore.streak
    private(set) var jolly = SharedStore.jolly
    private(set) var calibration = SharedStore.calibration

    @ObservationIgnored private let health: WatchHealth
    @ObservationIgnored private let controller: StepsController
    @ObservationIgnored private var started = false
    /// Debug only: fake steps, the iPhone link is not started and the settings are not reloaded.
    @ObservationIgnored private var debugging = false

    init() {
        let health = WatchHealth()
        self.health = health
        var provider: any StepsProvider = health
        #if DEBUG
        // Simulator screenshots (the watch simulator has no Health data): `-stepteller.debugSteps 7200`, with
        // `-stepteller.debugStreak 14 -stepteller.debugJolly 2 -stepteller.debugGoal 10000` for the rest.
        let d = UserDefaults.standard
        if d.object(forKey: "stepteller.debugSteps") != nil {
            let raw = d.integer(forKey: "stepteller.debugSteps")
            provider = DebugStepsProvider(value: raw < 0 ? nil : raw)
            streak = d.integer(forKey: "stepteller.debugStreak")
            jolly = d.integer(forKey: "stepteller.debugJolly")
            if d.object(forKey: "stepteller.debugGoal") != nil { goal = max(0, d.integer(forKey: "stepteller.debugGoal")) }
            debugging = true
        }
        #endif
        // Calendar that follows the watch's time zone.
        controller = StepsController(provider: provider, calendar: .autoupdatingCurrent)
        // Last count read today (saved for the complications): the screen opens on it, not on «—».
        if let cached = SharedStore.cachedStepsToday(now: Date(), calendar: controller.calendar) {
            state.seed(cachedSteps: cached)
        }
    }

    // MARK: derived

    var unit: DistanceUnit { unitPreference.resolved(regionUsesMiles: Units.regionUsesMiles) }
    var plan: Plan { Plan(goal: goal, steps: state.steps, speed: speed, model: calibration.model) }
    /// What the screen shows: the plan, or nothing when Health gave no steps (same rule as the widget).
    var snapshot: WidgetSnapshot {
        WidgetSnapshot(plan: state.origin == .health ? plan : nil, streak: streak, jolly: jolly, unit: unit)
    }

    // MARK: lifecycle

    /// First appearance: iPhone link, Health permission, read, observation.
    func start() async {
        guard !started else { return }
        started = true
        if !debugging {
            WatchSync.shared.start { [weak self] in
                Task { @MainActor in self?.loadShared() }
            }
        }
        await controller.provider.requestAccess()
        await refresh()
        await controller.provider.observe { [weak self] in
            await self?.refresh()
        }
    }

    /// Back on screen: settings received meanwhile and today's steps.
    func becameActive() async {
        if !debugging { loadShared() }
        await refresh()
    }

    /// Rereads Health. Three separate steps: no state stays «taken» while waiting.
    func refresh() async {
        let now = Date()
        var s = state
        let canRead = controller.begin(&s, now: now)
        state = s
        guard canRead else { return }
        let value = await controller.read(now: now)
        state.applyHealth(value, at: Date())
        if let value, !debugging, SharedStore.cachedStepsToday(now: now, calendar: controller.calendar) != value {
            SharedStore.saveSteps(value, now: now, calendar: controller.calendar)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Settings as last received from the iPhone.
    func loadShared() {
        goal = SharedStore.goal
        speed = SharedStore.speed
        unitPreference = SharedStore.unitPreference
        streak = SharedStore.streak
        jolly = SharedStore.jolly
        calibration = SharedStore.calibration
    }
}
