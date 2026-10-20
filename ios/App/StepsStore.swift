import Foundation
import Observation
import WidgetKit
import StepTellerCore

/// App state: goal, speed, reminder and calibration (persisted in UserDefaults) and today's steps
/// (never persisted: reread from Health).
@MainActor
@Observable
final class StepsStore {
    var goal: Int {
        didSet {
            defaults.set(goal, forKey: Keys.goal)
            SharedStore.goal = goal
            history.recordGoal(goal)
            deferSync(reloadWidget: true)
        }
    }
    var speed: Double {
        didSet {
            defaults.set(speed, forKey: Keys.speed)
            SharedStore.speed = speed
            deferSync(reloadWidget: true)
        }
    }
    /// Evening reminder on (default yes) and time in minutes from midnight (default 20:30).
    var reminderEnabled: Bool { didSet { defaults.set(reminderEnabled, forKey: Keys.reminderOn); Task { await reminderSettingsChanged() } } }
    var reminderMinutes: Int { didSet { defaults.set(reminderMinutes, forKey: Keys.reminderTime); deferSync(reloadWidget: false) } }
    private(set) var state = StepsState()
    /// History, streak and Jollies.
    let history: HistoryStore
    private(set) var calibration: CalibrationResult

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let controller: StepsController
    @ObservationIgnored private let workouts: (any WorkoutsProvider)?
    @ObservationIgnored private let scheduler = ReminderScheduler()
    @ObservationIgnored private var dayTask: Task<Void, Never>?
    @ObservationIgnored private var lastCalibration: Date?
    @ObservationIgnored private var observing = false
    @ObservationIgnored private var started = false
    /// Deferred work (widget reload, reminder rescheduling) after a burst of changes.
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var pendingWidgetReload = false
    @ObservationIgnored private var pendingReminders = false
    /// Reminder applications queued, one at a time.
    @ObservationIgnored private var reminderQueue: Task<Void, Never>?

    private enum Keys {
        static let goal = "stepteller.goal"
        static let speed = "stepteller.speed"
        static let reminderOn = "stepteller.reminder.on"
        static let reminderTime = "stepteller.reminder.minutes"
        static let calibration = "stepteller.calibration.v1"
    }

    init(provider: any StepsProvider, workouts: (any WorkoutsProvider)? = nil,
         historyProvider: (any HistoryProvider)? = nil, streakStartOverride: Date? = nil,
         defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.workouts = workouts
        // Calendar that follows the phone's time zone: after a trip «today» stays right without relaunching.
        controller = StepsController(provider: provider, calendar: .autoupdatingCurrent)
        // `integer/double(forKey:)` also read values passed as launch arguments (strings).
        let initialGoal = max(0, defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000)
        goal = initialGoal
        history = HistoryStore(provider: historyProvider, currentGoal: initialGoal, defaults: defaults,
                               streakStartOverride: streakStartOverride)
        // Slider on the road: 3–16 km/h in 0.5 steps (an old value like 8.3 becomes 8.5).
        let v = defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : SpeedTrack.defaultSpeed
        speed = SpeedTrack.snap(v)
        reminderEnabled = defaults.object(forKey: Keys.reminderOn) != nil ? defaults.bool(forKey: Keys.reminderOn) : true
        reminderMinutes = defaults.object(forKey: Keys.reminderTime) != nil ? defaults.integer(forKey: Keys.reminderTime) : 20 * 60 + 30
        #if DEBUG
        // Simulator screenshots: no notification permission prompt over the UI.
        if defaults.object(forKey: "stepteller.debugSteps") != nil { reminderEnabled = false }
        #endif
        // Calibration computed earlier (aggregate points only, no raw Health data).
        calibration = (defaults.data(forKey: Keys.calibration)).flatMap { try? JSONDecoder().decode(CalibrationResult.self, from: $0) } ?? .empty
        // Today's last known count (saved for the widget): the Home opens on it, not on 0, while Health is read.
        var seedSteps = true
        #if DEBUG
        if defaults.object(forKey: "stepteller.debugSteps") != nil { seedSteps = false }   // deterministic screenshots
        #endif
        if seedSteps, let cached = SharedStore.cachedStepsToday(now: Date(), calendar: controller.calendar) {
            state.seed(cachedSteps: cached)
        }
        SharedStore.goal = goal              // the widget reads goal, calibration and speed from the App Group
        SharedStore.speed = speed
        SharedStore.calibration = calibration
    }

    // MARK: derived

    /// Cadence model: the automatic calibration when available, otherwise the manual points in `Calibration`.
    var model: CadenceModel { calibration.model }
    var steps: Int { state.steps }
    var plan: Plan { Plan(goal: goal, steps: steps, speed: speed, model: model) }
    var origin: StepsOrigin { state.origin }
    var showsNoDataWarning: Bool { state.showsNoDataWarning }
    var hasOverride: Bool { state.override != nil }
    var lastUpdate: Date? { state.lastUpdate }

    // MARK: lifecycle

    /// Start (once the introduction is done, once only): Health permission (already asked by the introduction:
    /// iOS does not show it again), read, observation, calibration, reminders.
    func start() async {
        guard !started else { return }
        started = true
        await controller.provider.requestAccess()
        await activate()
        await startObserving()
        await refreshCalibration(force: true)
        if reminderEnabled { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// App in the foreground (also back from the background).
    func becameActive() async {
        await activate()
        await refreshCalibration(force: false)
    }

    /// Whole history reread first (the celebration waits for a history read after activation), then
    /// today's steps: the 20 s-limited reread inside `refresh()` is skipped, one read per activation.
    private func activate() async {
        await history.refresh()
        await refresh()
        startDayWatcher()
    }

    /// App in the background: the deferred work runs now (whoever drags the slider and closes the app must
    /// find widget and reminders up to date), then one widget reload with the final state.
    func becameInactive() async {
        pendingWidgetReload = true
        await flushSync()
        dayTask?.cancel()
        dayTask = nil
    }

    // MARK: coalesced updates

    /// The slider and the Settings fields change dozens of times per second: widget and reminders update
    /// once, half a second after the last change, with the final values (or right away when going to the background).
    private func deferSync(reloadWidget: Bool) {
        pendingWidgetReload = pendingWidgetReload || reloadWidget
        pendingReminders = true
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            await self.flushSync()
        }
    }

    private func flushSync() async {
        syncTask?.cancel()
        syncTask = nil
        if pendingWidgetReload {
            pendingWidgetReload = false
            WidgetCenter.shared.reloadAllTimelines()
        }
        if pendingReminders {
            pendingReminders = false
            await updateReminders()
        }
    }

    /// One observer for the whole life of the app: in the foreground it updates the number, in the
    /// background (hourly Health delivery) it recomputes the reminder.
    private func startObserving() async {
        guard !observing else { return }
        observing = true
        await controller.provider.observe { [weak self] in
            await self?.refresh()
        }
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
        if let value {
            // copy for the widget with the phone locked; the widget reloads only if the number changed
            if SharedStore.cachedStepsToday(now: now) != value {
                SharedStore.saveSteps(value, now: now)
                WidgetCenter.shared.reloadAllTimelines()
            }
            history.updateToday(steps: value)             // the streak updates now, not at the history reread
        }
        await history.refresh(minInterval: 20)       // today in the history and in the streak
        await updateReminders()
    }

    // MARK: manual steps

    func setManualSteps(_ value: Int) {
        state.setManual(value, at: Date(), calendar: controller.calendar)
        Task { await updateReminders() }
    }

    func useHealth() async {
        state.useHealth()
        await refresh()
    }

    // MARK: automatic calibration

    /// Recomputes the points from the workouts of the last 90 days (at most once an hour).
    func refreshCalibration(force: Bool) async {
        guard let workouts else { return }
        if !force, let last = lastCalibration, Date().timeIntervalSince(last) < 3600 { return }
        lastCalibration = Date()
        let since = Date().addingTimeInterval(-Double(AutoCalibration.windowDays) * 86_400)
        let samples = await workouts.workouts(since: since)
        // No workouts read (permission denied or none): the previous calibration stays.
        guard !samples.isEmpty else { return }
        let result = AutoCalibration.compute(from: samples, now: Date())
        calibration = result
        SharedStore.calibration = result
        WidgetCenter.shared.reloadAllTimelines()
        if let data = try? JSONEncoder().encode(result) { defaults.set(data, forKey: Keys.calibration) }
        await updateReminders()
    }

    // MARK: permissions (introduction)

    /// System prompt for Health (read only). iOS shows it once.
    func requestHealthAccess() async {
        await controller.provider.requestAccess()
    }

    /// System prompt for notifications, only if never asked.
    func requestReminderPermission() async {
        _ = await scheduler.requestIfNeeded()
    }

    // MARK: evening reminder

    private func reminderSettingsChanged() async {
        if reminderEnabled { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// Reschedules the notifications with the current minutes (today precise, following days generic).
    /// Writes to the notification center are queued in request order: two close updates do not
    /// interleave and the last plan computed is also the last one written.
    func updateReminders() async {
        let enabled = reminderEnabled
        let requests = enabled
            ? ReminderPlanner.schedule(now: Date(), minutesFromMidnight: reminderMinutes,
                                       plan: plan, streak: history.streak, calendar: controller.calendar)
            : []
        let previous = reminderQueue
        let scheduler = scheduler
        let task = Task {
            await previous?.value
            if enabled { await scheduler.apply(requests) } else { await scheduler.cancelAll() }
        }
        reminderQueue = task
        await task.value
    }

    // MARK: day change

    /// With the app open past midnight: rereads right after midnight.
    private func startDayWatcher() {
        dayTask?.cancel()
        dayTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let now = Date()
                let cal = self.controller.calendar
                guard let next = cal.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 1),
                                              matchingPolicy: .nextTime) else { return }
                try? await Task.sleep(for: .seconds(max(1, next.timeIntervalSince(now))))
                if Task.isCancelled { return }
                await self.refresh()
            }
        }
    }
}
