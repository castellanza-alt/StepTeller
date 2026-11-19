import Foundation
import Observation
import UIKit
import WidgetKit
import StepTellerCore

/// App state: goal, speed, units, reminder and calibration (persisted in UserDefaults) and today's steps
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
    /// Units chosen in Settings. Changing them moves the speed to the nearest step of the new unit
    /// (4 km/h → 2.5 mph): the speed itself stays in km/h.
    var unitPreference: UnitPreference {
        didSet {
            defaults.set(unitPreference.rawValue, forKey: Keys.units)
            SharedStore.unitPreference = unitPreference
            speed = unit.snapKmh(speed)
            deferSync(reloadWidget: true)
        }
    }
    /// Evening reminder on (default yes) and time in minutes from midnight (default 20:30).
    var reminderEnabled: Bool {
        didSet {
            defaults.set(reminderEnabled, forKey: Keys.reminderOn)
            SharedStore.reminderOn = reminderEnabled
            Task { await reminderSettingsChanged() }
        }
    }
    /// Notifications of goal reached and Jollies earned or spent (default yes, D-038).
    var eventNotificationsOn: Bool {
        didSet {
            defaults.set(eventNotificationsOn, forKey: Keys.eventsOn)
            SharedStore.eventsOn = eventNotificationsOn
            if eventNotificationsOn { Task { _ = await scheduler.requestIfNeeded() } }
            else { Task { await EventNotifier.withdrawAllPending() } }
        }
    }
    /// Seasonal themes (Christmas: Home with the boot, the snow and the sleigh, icon), default yes (D-037, D-040).
    var seasonalThemesOn: Bool {
        didSet {
            // iCloud and Backup reassign it at every restore: only a real change touches widget and icon
            guard seasonalThemesOn != oldValue else { return }
            defaults.set(seasonalThemesOn, forKey: Keys.seasonal)
            SharedStore.seasonalOn = seasonalThemesOn
            WidgetCenter.shared.reloadAllTimelines()
            SeasonIcon.update()                  // switched off: the normal icon right away (iOS shows its alert)
        }
    }
    /// NEAT's voice (D-044, D-047): Normale, Piccante, Senza pietà (`nasty`, the default for everybody). Saved also in
    /// iCloud and the Backup; the widget reads its App Group copy. `voice` is the one the language allows.
    var voiceLevel: NastyLevel {
        didSet {
            defaults.set(voiceLevel.rawValue, forKey: Keys.voiceLevel)
            SharedStore.voiceLevel = voiceLevel
            // iCloud and Backup reassign it at every restore: only a real change touches notifications and catalog
            guard voiceLevel != oldValue else { return }
            deferSync(reloadWidget: false)
            if voiceLevel != .normale { Task { await refreshCatalog() } }
        }
    }
    /// Roast notifications a day (Poche · Normali · Tante), default Normali; saved like the voice.
    var roastFrequency: RoastFrequency {
        didSet {
            defaults.set(roastFrequency.rawValue, forKey: Keys.roastFrequency)
            if roastFrequency != oldValue { deferSync(reloadWidget: false) }
        }
    }
    /// The line in the Home bubble now (nil: no bubble), set by `updateHomeLine` and `tapHeart`.
    var homeQuote: NastyQuote?
    /// The first line after the update from 1.2 is in the bubble (T-023 §4).
    var showsFirstLine = false
    /// Grows when a downloaded catalog replaces the one in use.
    var catalogEdition = 0
    /// The heart's clock: speaking, taps, anger (T-023 §3).
    @ObservationIgnored let heart = HeartMotion()
    /// End of the last check of the events (`announceEvents`): the goal celebration waits for it, so the Jolly
    /// pop-ups of the same reading come first (T-005 §1.1).
    private(set) var eventsCheckedAt: Date?
    /// A notification was tapped: the Home opens (see `NotificationRouter`).
    var homeRequests = 0
    /// The seasonal icon should be checked (splash ended, back in the foreground): `RootView` does it when the
    /// screen is free of celebrations and pop-ups, after the events checked since `iconCheckAfter`.
    private(set) var iconRequests = 0
    @ObservationIgnored private(set) var iconCheckAfter = Date()
    @ObservationIgnored let launchedAt = Date()

    /// `since`: the activation the request belongs to (the launch, for the end of the splash).
    func requestIcon(since: Date) {
        iconCheckAfter = since
        iconRequests += 1
    }
    /// Jolly pop-ups waiting to be shown (first opening after the event, never repeated), oldest first.
    private(set) var popups: [JollyPopupItem] = []
    var reminderMinutes: Int {
        didSet {
            defaults.set(reminderMinutes, forKey: Keys.reminderTime)
            SharedStore.reminderMinutes = reminderMinutes
            deferSync(reloadWidget: false)
        }
    }
    private(set) var state = StepsState()
    /// History, streak and Jollies.
    let history: HistoryStore
    private(set) var calibration: CalibrationResult

    @ObservationIgnored let defaults: UserDefaults
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

    enum Keys {
        static let goal = "stepteller.goal"
        static let speed = "stepteller.speed"
        static let units = "stepteller.units"
        static let reminderOn = "stepteller.reminder.on"
        static let reminderTime = "stepteller.reminder.minutes"
        static let calibration = "stepteller.calibration.v1"
        static let eventsOn = "stepteller.events.on"
        static let seasonal = "stepteller.seasonal"
        static let voiceLevel = "stepteller.voice.level"
        static let roastFrequency = "stepteller.roast.frequency"
        /// Phone only (not iCloud nor Backup): the bubble, the first line, the last download, the roast seed.
        static let bubble = "stepteller.voice.bubble"
        static let firstLine = "stepteller.voice.firstLine"
        static let catalogCheck = "stepteller.voice.catalogCheck"
        static let roastSalt = "stepteller.roast.salt"
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
        // Launch argument `-stepteller.units miles` too (screenshots).
        let preference = defaults.string(forKey: Keys.units).flatMap(UnitPreference.init(rawValue:)) ?? .automatic
        unitPreference = preference
        // Slider on the road: 3–10 km/h or 2–6 mph in 0.5 steps (an old value like 8.3 becomes 8.5; a speed saved
        // before D-042, up to 16 km/h or 10 mph, comes down to 10 km/h or 6 mph and is saved so, iCloud too).
        let v = defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : SpeedTrack.defaultSpeed
        let startUnit = preference.resolved(regionUsesMiles: Units.regionUsesMiles)
        let startSpeed = startUnit.snapKmh(v)
        speed = startSpeed
        if let saved = Self.persistentSpeed(defaults), saved > startUnit.km(fromValue: startUnit.maxSpeed) + 1e-9 {
            // the saved value, lowered (not a `-stepteller.speed` launch argument, which `v` may be)
            defaults.set(startUnit.snapKmh(saved), forKey: Keys.speed)
        }
        reminderEnabled = defaults.object(forKey: Keys.reminderOn) != nil ? defaults.bool(forKey: Keys.reminderOn) : true
        reminderMinutes = defaults.object(forKey: Keys.reminderTime) != nil ? defaults.integer(forKey: Keys.reminderTime) : 20 * 60 + 30
        eventNotificationsOn = defaults.object(forKey: Keys.eventsOn) != nil ? defaults.bool(forKey: Keys.eventsOn) : true
        seasonalThemesOn = defaults.object(forKey: Keys.seasonal) != nil ? defaults.bool(forKey: Keys.seasonal) : true
        // D-047: whoever has none saved (new install, update from 1.2) starts at Senza pietà
        voiceLevel = NastyLevel.saved(defaults.string(forKey: Keys.voiceLevel)) ?? .standard
        roastFrequency = RoastFrequency.saved(defaults.string(forKey: Keys.roastFrequency)) ?? .normali
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
        SharedStore.goal = goal              // the widget reads goal, calibration, speed and units from the App Group
        SharedStore.speed = speed
        SharedStore.unitPreference = unitPreference
        SharedStore.calibration = calibration
        SharedStore.reminderOn = reminderEnabled      // the widget refreshes tonight's reminder (WidgetReminder)
        SharedStore.reminderMinutes = reminderMinutes
        SharedStore.eventsOn = eventNotificationsOn
        SharedStore.seasonalOn = seasonalThemesOn
        SharedStore.voiceLevel = voiceLevel
        #if DEBUG
        // `-stepteller.season christmas` / `none`: forces the seasonal theme (screenshots, QA), widget included.
        SharedStore.forcedSeason = defaults.string(forKey: "stepteller.season")
        // Simulator checks of the pop-ups: `-stepteller.debugEventsSince 7` starts the ledger 7 days ago and
        // forgets what was told, so the Jolly events of the fake history (`-stepteller.debugMissedDay`) show.
        if defaults.object(forKey: "stepteller.debugEventsSince") != nil {
            let back = defaults.integer(forKey: "stepteller.debugEventsSince")
            SharedStore.eventLedger = EventLedger(since: DayKey.of(Date(), minusDays: back, calendar: controller.calendar))
        }
        #endif
    }

    /// The speed saved on this phone, not a launch argument (`-stepteller.speed` in the screenshots).
    private static func persistentSpeed(_ defaults: UserDefaults) -> Double? {
        guard let id = Bundle.main.bundleIdentifier else { return nil }
        return defaults.persistentDomain(forName: id)?[Keys.speed] as? Double
    }

    // MARK: derived

    /// Cadence model: the automatic calibration when available, otherwise the manual points in `Calibration`.
    var model: CadenceModel { calibration.model }
    /// Unit shown: the choice in Settings, «automatic» from the phone's region.
    var unit: DistanceUnit { unitPreference.resolved(regionUsesMiles: Units.regionUsesMiles) }
    var steps: Int { state.steps }
    var plan: Plan { Plan(goal: goal, steps: steps, speed: speed, model: model) }
    var origin: StepsOrigin { state.origin }
    var showsNoDataWarning: Bool { state.showsNoDataWarning }
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
        var askNotifications = reminderEnabled || eventNotificationsOn || voice != .normale
        #if DEBUG
        // Simulator screenshots: no notification permission prompt over the UI.
        if defaults.object(forKey: "stepteller.debugSteps") != nil { askNotifications = false }
        #endif
        if askNotifications { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// App in the foreground (also back from the background).
    func becameActive() async {
        await activate()
        await refreshCalibration(force: false)
        await refreshCatalog()
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
        // goal changed with the app open (lowered below today's steps): the celebration tells it here, so it is
        // marked before the widget reload could notify it
        if UIApplication.shared.applicationState == .active { await announceEvents() }
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
        // Phone locked (background delivery): Health is encrypted and the read fails. That is not «0 steps»:
        // nothing changes, otherwise tonight's reminder would come back with the whole goal still to walk.
        if value == nil, !UIApplication.shared.isProtectedDataAvailable { return }
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
        await announceEvents()
        await updateReminders()
    }

    // MARK: goal and Jolly events (D-038)

    /// Tells the events of the streak not told yet: notifications with the app in the background (Health
    /// delivery, wake-up before the reminder), pop-ups with the app on screen. Only after a real Health read.
    func announceEvents() async {
        defer { eventsCheckedAt = Date() }
        guard history.eventsReady else { return }
        let now = Date()
        let calendar = controller.calendar
        let events = StreakEvents.events(in: history.streak, now: now, calendar: calendar)
        await EventNotifier.withdrawStale(keeping: Set(events.map(\.id)))
        let active = UIApplication.shared.applicationState == .active
        let due = StreakEvents.toNotify(events, ledger: EventNotifier.ledger(now: now, calendar: calendar), now: now, calendar: calendar)
        await EventNotifier.notify(due, steps: steps, goal: goal, appActive: active, now: now, calendar: calendar)
        guard active else { return }
        // after a real Health read, with the app on screen, together with the Jolly events of this same check (one
        // reading of «active»: the gift is never left for a later check while the events go in the queue now)
        let gift = started ? claimGift() : nil
        var ledger = EventNotifier.ledger(now: now, calendar: calendar)
        let show = StreakEvents.toShow(events, ledger: ledger, now: now, calendar: calendar)
        var batch = StreakEvents.popups(show).map { JollyPopupItem(event: $0.event, count: $0.count) }
        if !show.isEmpty {
            // marked before being seen: never shown twice, also if the app closes meanwhile
            ledger.shown.formUnion(show.map(\.id))
            EventNotifier.save(ledger, now: now, calendar: calendar)
            EventNotifier.withdraw(show)
        }
        guard gift != nil || !batch.isEmpty else { return }
        let onScreen = !popups.isEmpty                     // the first one may already be shown: it stays as it is
        if let gift { popups.insert(gift, at: onScreen ? 1 : 0) }   // first of the queue, after one on screen
        popups += batch
        // each pop-up still waiting shows the Jollies at its point of the queue, the last one those of now (T-018)
        let from = onScreen ? 1 : 0
        let counts = StreakEvents.stepCounts(final: history.streak.jolly, deltas: popups[from...].map(\.delta))
        for (k, i) in popups.indices.dropFirst(from).enumerated() { popups[i].jolly = counts[k] }
    }

    /// Christmas gift (D-040): at the first opening from 25/12 to 6/1, one Jolly more, with its pop-up first in
    /// the queue (gift → used → earned → celebration, T-015 §4.1). Does not depend on the seasonal switch.
    /// After a reinstall it waits for iCloud (`CloudBackup.settled`), which may already know this season's gift.
    /// Returns its pop-up, which `announceEvents` puts in the queue with the events of the same check.
    private func claimGift() -> JollyPopupItem? {
        guard CloudBackup.settled, history.claimGift(now: AppClock.now()) else { return nil }
        return .gift(streak: history.streak.streak, jolly: history.streak.jolly)
    }

    /// The pop-up on screen was closed: the next one, if any.
    func dismissPopup() {
        if !popups.isEmpty { popups.removeFirst() }
    }

    /// Settings brought back from iCloud after a reinstall (see `CloudBackup`): history first, so the goal
    /// set afterwards matches its last entry and adds nothing.
    func reloadSaved() {
        history.reloadSaved()
        if defaults.object(forKey: Keys.goal) != nil { goal = max(0, defaults.integer(forKey: Keys.goal)) }
        if let raw = defaults.string(forKey: Keys.units), let units = UnitPreference(rawValue: raw) { unitPreference = units }
        if defaults.object(forKey: Keys.speed) != nil { speed = unit.snapKmh(defaults.double(forKey: Keys.speed)) }
        if defaults.object(forKey: Keys.reminderOn) != nil { reminderEnabled = defaults.bool(forKey: Keys.reminderOn) }
        if defaults.object(forKey: Keys.reminderTime) != nil { reminderMinutes = defaults.integer(forKey: Keys.reminderTime) }
        if defaults.object(forKey: Keys.eventsOn) != nil { eventNotificationsOn = defaults.bool(forKey: Keys.eventsOn) }
        if defaults.object(forKey: Keys.seasonal) != nil { seasonalThemesOn = defaults.bool(forKey: Keys.seasonal) }
        if let value = NastyLevel.saved(defaults.string(forKey: Keys.voiceLevel)) { voiceLevel = value }
        if let value = RoastFrequency.saved(defaults.string(forKey: Keys.roastFrequency)) { roastFrequency = value }
        if let saved = defaults.data(forKey: Keys.calibration).flatMap({ try? JSONDecoder().decode(CalibrationResult.self, from: $0) }) {
            calibration = saved
            SharedStore.calibration = saved
        }
        deferSync(reloadWidget: true)
    }

    // MARK: manual backup

    /// Settings → Backup → Export: everything the app keeps besides Health.
    func makeBackup(now: Date = Date()) -> BackupFile {
        var file = BackupFile(exportedAt: now)
        file.goal = goal
        file.speed = speed
        file.units = unitPreference.rawValue
        file.reminderOn = reminderEnabled
        file.reminderMinutes = reminderMinutes
        file.eventNotificationsOn = eventNotificationsOn
        file.seasonalThemes = seasonalThemesOn
        file.voiceLevel = voiceLevel.rawValue
        file.roastFrequency = roastFrequency.rawValue
        file.theme = defaults.string(forKey: ThemeMode.storageKey)
        file.streakStart = history.streakStart
        file.goalHistory = history.goals
        if !history.gifts.days.isEmpty { file.jollyGifts = history.gifts.days }
        if calibration != .empty { file.calibration = calibration }
        return file
    }

    /// Settings → Backup → Import: values in the file replace these, missing ones stay. History first, so the
    /// goal set afterwards matches its last entry and adds nothing.
    func importBackup(_ file: BackupFile) {
        history.importBackup(goals: file.goalHistory, streakStart: file.streakStart, gifts: file.jollyGifts)
        if let value = file.goal { goal = max(0, value) }
        if let raw = file.units, let units = UnitPreference(rawValue: raw) { unitPreference = units }
        if let value = file.speed { speed = unit.snapKmh(value) }
        if let value = file.reminderOn { reminderEnabled = value }
        if let value = file.reminderMinutes, (0..<24 * 60).contains(value) { reminderMinutes = value }
        if let value = file.eventNotificationsOn { eventNotificationsOn = value }
        if let value = file.seasonalThemes { seasonalThemesOn = value }
        if let value = NastyLevel.saved(file.voiceLevel) { voiceLevel = value }
        if let value = RoastFrequency.saved(file.roastFrequency) { roastFrequency = value }
        if let raw = file.theme, ThemeMode(rawValue: raw) != nil { defaults.set(raw, forKey: ThemeMode.storageKey) }
        if let saved = file.calibration {
            calibration = saved
            SharedStore.calibration = saved
            if let data = try? JSONEncoder().encode(saved) { defaults.set(data, forKey: Keys.calibration) }
        }
        deferSync(reloadWidget: true)
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
        // Steps from Health only grow during the day: the reminder never uses fewer than the last count read
        // today, so a failed read cannot bring back a reminder already cancelled because the goal was reached.
        var reminderPlan = plan
        if origin == .health, let cached = SharedStore.cachedStepsToday(now: Date(), calendar: controller.calendar),
           cached > steps {
            reminderPlan = Plan(goal: goal, steps: cached, speed: speed, model: model)
        }
        let requests = enabled
            ? ReminderPlanner.schedule(now: Date(), minutesFromMidnight: reminderMinutes,
                                       plan: reminderPlan, streak: history.streak, calendar: controller.calendar)
            : []
        // tonight's streak warning for the widget, which rewrites the numbers but not this
        SharedStore.reminderWarning = ReminderPlanner.warning(for: history.streak)
        scheduleReminderRefresh()
        let previous = reminderQueue
        let scheduler = scheduler
        let unit = unit
        let roast = roastInput(steps: reminderPlan.steps)
        let task = Task {
            await previous?.value
            if enabled { await scheduler.apply(requests, unit: unit) } else { await scheduler.cancelAll() }
            await RoastScheduler.update(roast)
        }
        reminderQueue = task
        await task.value
    }

    /// Background wake-up before the next reminder (see `ReminderRefreshTask`); none if the reminder is off.
    func scheduleReminderRefresh() {
        #if DEBUG
        if defaults.object(forKey: "stepteller.debugSteps") != nil { return }
        #endif
        let fire = reminderEnabled
            ? ReminderPlanner.nextFire(now: Date(), minutesFromMidnight: reminderMinutes, calendar: controller.calendar)
            : nil
        ReminderRefreshTask.schedule(before: fire)
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
