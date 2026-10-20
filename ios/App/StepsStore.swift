import Foundation
import Observation
import WidgetKit
import StepTellerCore

/// Stato dell'app: obiettivo, velocità, promemoria e taratura (persistiti in UserDefaults) e passi
/// di oggi (mai persistiti: si rileggono da Salute).
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
    /// Promemoria serale acceso (default sì) e ora in minuti da mezzanotte (default 20:30).
    var reminderEnabled: Bool { didSet { defaults.set(reminderEnabled, forKey: Keys.reminderOn); Task { await reminderSettingsChanged() } } }
    var reminderMinutes: Int { didSet { defaults.set(reminderMinutes, forKey: Keys.reminderTime); deferSync(reloadWidget: false) } }
    private(set) var state = StepsState()
    /// Storico, streak e Jolly.
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
    /// Lavoro rinviato (ricarico dei widget, riprogrammazione dei promemoria) dopo una raffica di modifiche.
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var pendingWidgetReload = false
    @ObservationIgnored private var pendingReminders = false
    /// Applicazioni dei promemoria in fila, una alla volta.
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
        controller = StepsController(provider: provider)
        // `integer/double(forKey:)` leggono anche i valori passati come argomenti di avvio (stringhe).
        let initialGoal = max(0, defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000)
        goal = initialGoal
        history = HistoryStore(provider: historyProvider, currentGoal: initialGoal, defaults: defaults,
                               streakStartOverride: streakStartOverride)
        // Cursore sulla strada: 3–16 km/h a scatti di 0,5 (un valore vecchio come 8,3 diventa 8,5).
        let v = defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : SpeedTrack.defaultSpeed
        speed = SpeedTrack.snap(v)
        reminderEnabled = defaults.object(forKey: Keys.reminderOn) != nil ? defaults.bool(forKey: Keys.reminderOn) : true
        reminderMinutes = defaults.object(forKey: Keys.reminderTime) != nil ? defaults.integer(forKey: Keys.reminderTime) : 20 * 60 + 30
        #if DEBUG
        // Screenshot sul simulatore: niente richiesta di permesso notifiche sopra l'interfaccia.
        if defaults.object(forKey: "stepteller.debugSteps") != nil { reminderEnabled = false }
        #endif
        // Taratura calcolata in precedenza (solo punti aggregati, non dati di Salute grezzi).
        calibration = (defaults.data(forKey: Keys.calibration)).flatMap { try? JSONDecoder().decode(CalibrationResult.self, from: $0) } ?? .empty
        SharedStore.goal = goal              // il widget legge obiettivo, taratura e velocità dall'App Group
        SharedStore.speed = speed
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

    // MARK: ciclo di vita

    /// Avvio (a introduzione conclusa, una volta sola): permesso Salute (già chiesto dall'introduzione:
    /// iOS non lo ripropone), lettura, osservazione, taratura, promemoria.
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

    /// App in primo piano (anche ritorno da background).
    func becameActive() async {
        await activate()
        await refreshCalibration(force: false)
    }

    /// Storico riletto per intero (la festa aspetta uno storico letto dopo l'attivazione), poi i passi di
    /// oggi: la rilettura limitata a 20 s dentro `refresh()` viene così saltata, una sola lettura per attivazione.
    private func activate() async {
        await history.refresh()
        await refresh()
        startDayWatcher()
    }

    /// App in background: il lavoro rinviato parte subito (chi trascina il cursore e chiude l'app deve trovare
    /// widget e promemoria aggiornati), poi un ricarico dei widget con lo stato finale.
    func becameInactive() async {
        pendingWidgetReload = true
        await flushSync()
        dayTask?.cancel()
        dayTask = nil
    }

    // MARK: aggiornamenti coalizzati

    /// Cursore e campi delle Impostazioni cambiano decine di volte al secondo: widget e promemoria si aggiornano
    /// una volta sola, mezzo secondo dopo l'ultima modifica, con i valori finali (o subito, andando in background).
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
        if let value {
            // copia per il widget a telefono bloccato; il widget si ricarica solo se il numero è cambiato
            if SharedStore.cachedStepsToday(now: now) != value {
                SharedStore.saveSteps(value, now: now)
                WidgetCenter.shared.reloadAllTimelines()
            }
            history.updateToday(steps: value)             // la streak scatta subito, non alla rilettura dello storico
        }
        await history.refresh(minInterval: 20)       // oggi nello storico e nella streak
        await updateReminders()
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

    // MARK: permessi (introduzione)

    /// Richiesta di sistema per Salute (solo lettura). iOS la mostra una volta sola.
    func requestHealthAccess() async {
        await controller.provider.requestAccess()
    }

    /// Richiesta di sistema per le notifiche, solo se mai chiesta.
    func requestReminderPermission() async {
        _ = await scheduler.requestIfNeeded()
    }

    // MARK: promemoria serale

    private func reminderSettingsChanged() async {
        if reminderEnabled { _ = await scheduler.requestIfNeeded() }
        await updateReminders()
    }

    /// Riprogramma le notifiche con i minuti attuali (oggi preciso, giorni successivi generici).
    /// Le scritture nel centro notifiche sono in fila, nell'ordine delle richieste: due aggiornamenti
    /// vicini non si intrecciano e l'ultimo piano calcolato è anche l'ultimo scritto.
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
