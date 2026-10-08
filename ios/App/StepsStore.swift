import Foundation
import Observation
import WidgetKit
import StepTellerCore

/// Stato dell'app: obiettivo, velocità, promemoria e taratura (persistiti in UserDefaults) e passi
/// di oggi (mai persistiti: si rileggono da Salute).
@MainActor
@Observable
final class StepsStore {
    var goal: Int { didSet { defaults.set(goal, forKey: Keys.goal); SharedStore.goal = goal; history.recordGoal(goal); WidgetCenter.shared.reloadAllTimelines(); Task { await updateReminders() } } }
    var speed: Double { didSet { defaults.set(speed, forKey: Keys.speed); Task { await updateReminders(); await syncActivity() } } }
    /// Promemoria serale acceso (default sì) e ora in minuti da mezzanotte (default 20:30).
    var reminderEnabled: Bool { didSet { defaults.set(reminderEnabled, forKey: Keys.reminderOn); Task { await reminderSettingsChanged() } } }
    var reminderMinutes: Int { didSet { defaults.set(reminderMinutes, forKey: Keys.reminderTime); Task { await updateReminders() } } }
    private(set) var state = StepsState()
    /// Storico, streak e Jolly.
    let history: HistoryStore
    private(set) var calibration: CalibrationResult
    /// Live Activity del tappeto in corso.
    private(set) var treadmillActive = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let controller: StepsController
    @ObservationIgnored private let workouts: (any WorkoutsProvider)?
    @ObservationIgnored private let scheduler = ReminderScheduler()
    @ObservationIgnored private let liveActivity = LiveActivityController()
    @ObservationIgnored private var dayTask: Task<Void, Never>?
    @ObservationIgnored private var lastCalibration: Date?
    @ObservationIgnored private var observing = false

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
        controller = StepsController(provider: provider)
        // `integer/double(forKey:)` leggono anche i valori passati come argomenti di avvio (stringhe).
        let initialGoal = max(0, defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000)
        goal = initialGoal
        history = HistoryStore(provider: historyProvider, currentGoal: initialGoal, defaults: defaults,
                               streakStartOverride: streakStartOverride)
        let v = defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : 6.0
        speed = min(CadenceModel.maxSpeed, max(CadenceModel.minSpeed, (v * 10).rounded() / 10))
        reminderEnabled = defaults.object(forKey: Keys.reminderOn) != nil ? defaults.bool(forKey: Keys.reminderOn) : true
        reminderMinutes = defaults.object(forKey: Keys.reminderTime) != nil ? defaults.integer(forKey: Keys.reminderTime) : 20 * 60 + 30
        #if DEBUG
        // Screenshot sul simulatore: niente richiesta di permesso notifiche sopra l'interfaccia.
        if defaults.object(forKey: "stepteller.debugSteps") != nil { reminderEnabled = false }
        #endif
        treadmillActive = liveActivity.isRunning
        // Taratura calcolata in precedenza (solo punti aggregati, non dati di Salute grezzi).
        calibration = (defaults.data(forKey: Keys.calibration)).flatMap { try? JSONDecoder().decode(CalibrationResult.self, from: $0) } ?? .empty
        SharedStore.goal = goal              // il widget legge obiettivo e taratura dall'App Group
        SharedStore.calibration = calibration
    }

    // MARK: derivati

    /// Modello di cadenza: taratura automatica se disponibile, altrimenti quella manuale di `Calibration`.
    var model: CadenceModel { calibration.model }
    var steps: Int { state.steps }
    var plan: Plan { Plan(goal: goal, steps: steps, speed: speed, model: model) }
    var origin: StepsOrigin { state.origin }
    var showsNoDataWarning: Bool { state.showsNoDataWarning }
    var hasOverride: Bool { state.override != nil }
    var lastUpdate: Date? { state.lastUpdate }

    /// Riga finale: da dove viene la curva usata per l'andatura corrente.
    var calibrationNote: String {
        if plan.gait == .run {
            if calibration.runWorkouts > 0 { return "corsa tarata su \(calibration.runWorkouts) tue uscite · ultimi 90 giorni" }
            return Calibration.run.isEmpty ? "corsa · curva standard" : "corsa tarata sulle tue corse · set 2026"
        }
        if calibration.walkWorkouts > 0 { return "cammino tarato su \(calibration.walkWorkouts) tue uscite · ultimi 90 giorni" }
        return Calibration.walk.isEmpty ? "cammino · curva standard" : "cammino tarato sulle tue camminate"
    }

    // MARK: ciclo di vita

    /// Primo avvio: permesso Salute, lettura, osservazione, taratura, promemoria.
    func start() async {
        await controller.provider.requestAccess()
        await refresh()
        await startObserving()
        startDayWatcher()
        await refreshCalibration(force: true)
        await history.refresh()
        await updateReminders()
        if reminderEnabled { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// App in primo piano (anche ritorno da background).
    func becameActive() async {
        await refresh()
        startDayWatcher()
        await refreshCalibration(force: false)
        await history.refresh()
    }

    func becameInactive() {
        dayTask?.cancel()
        dayTask = nil
    }

    /// Un solo osservatore per tutta la vita dell'app: in primo piano aggiorna il numero, in
    /// background (consegna oraria di Salute) ricalcola il promemoria.
    private func startObserving() async {
        guard !observing else { return }
        observing = true
        await controller.provider.observe { [weak self] in
            await self?.refresh()
        }
    }

    /// Rilegge Salute. Tre passi separati: nessuno stato resta «preso» durante l'attesa.
    func refresh() async {
        let now = Date()
        var s = state
        let canRead = controller.begin(&s, now: now)
        state = s
        guard canRead else { return }
        let value = await controller.read(now: now)
        state.applyHealth(value, at: Date())
        if let value { SharedStore.saveSteps(value) }      // copia per il widget a telefono bloccato
        WidgetCenter.shared.reloadAllTimelines()
        await history.refresh(minInterval: 20)       // oggi nello storico e nella streak
        await updateReminders()
        await syncActivity()
    }

    // MARK: passi manuali

    func setManualSteps(_ value: Int) {
        state.setManual(value, at: Date(), calendar: controller.calendar)
        Task { await updateReminders() }
    }

    func useHealth() async {
        state.useHealth()
        await refresh()
    }

    // MARK: taratura automatica

    /// Ricalcola i punti dagli allenamenti degli ultimi 90 giorni (al massimo una volta all'ora).
    func refreshCalibration(force: Bool) async {
        guard let workouts else { return }
        if !force, let last = lastCalibration, Date().timeIntervalSince(last) < 3600 { return }
        lastCalibration = Date()
        let since = Date().addingTimeInterval(-Double(AutoCalibration.windowDays) * 86_400)
        let samples = await workouts.workouts(since: since)
        // Nessun allenamento letto (permesso negato o vuoto): si tiene la taratura precedente.
        guard !samples.isEmpty else { return }
        let result = AutoCalibration.compute(from: samples, now: Date())
        calibration = result
        SharedStore.calibration = result
        WidgetCenter.shared.reloadAllTimelines()
        if let data = try? JSONEncoder().encode(result) { defaults.set(data, forKey: Keys.calibration) }
        await updateReminders()
    }

    // MARK: Live Activity

    var liveActivityAvailable: Bool { liveActivity.isAvailable }

    /// «Avvia» / «Ferma» sul Blocco schermo.
    func toggleTreadmill() async {
        if liveActivity.isRunning {
            await liveActivity.end(plan: nil)
        } else {
            liveActivity.start(plan: plan)
        }
        treadmillActive = liveActivity.isRunning
    }

    /// Tiene la Live Activity allineata a passi e velocità; la chiude a obiettivo chiuso.
    private func syncActivity() async {
        guard liveActivity.isRunning else { treadmillActive = false; return }
        await liveActivity.update(plan: plan)
        treadmillActive = liveActivity.isRunning
    }

    // MARK: promemoria serale

    private func reminderSettingsChanged() async {
        if reminderEnabled { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// Riprogramma le notifiche con i minuti attuali (oggi preciso, giorni successivi generici).
    func updateReminders() async {
        guard reminderEnabled else { await scheduler.cancelAll(); return }
        let requests = ReminderPlanner.schedule(now: Date(), minutesFromMidnight: reminderMinutes,
                                                plan: plan, streak: history.streak, calendar: controller.calendar)
        await scheduler.apply(requests)
    }

    // MARK: cambio di giorno

    /// Con l'app aperta oltre mezzanotte: rilegge subito dopo la mezzanotte.
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
