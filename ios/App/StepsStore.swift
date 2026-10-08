import Foundation
import Observation
import StepTellerCore

/// Stato dell'app: obiettivo e velocità (persistiti in UserDefaults) e passi di oggi (mai
/// persistiti: si rileggono da Salute).
@MainActor
@Observable
final class StepsStore {
    var goal: Int { didSet { defaults.set(goal, forKey: Keys.goal) } }
    var speed: Double { didSet { defaults.set(speed, forKey: Keys.speed) } }
    private(set) var state = StepsState()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let controller: StepsController
    @ObservationIgnored private var dayTask: Task<Void, Never>?

    private enum Keys {
        static let goal = "stepteller.goal"
        static let speed = "stepteller.speed"
    }

    init(provider: any StepsProvider, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        controller = StepsController(provider: provider)
        // `integer/double(forKey:)` leggono anche i valori passati come argomenti di avvio (stringhe).
        goal = max(0, defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000)
        let v = defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : 6.0
        speed = min(CadenceModel.maxSpeed, max(CadenceModel.minSpeed, (v * 10).rounded() / 10))
    }

    // MARK: derivati

    var steps: Int { state.steps }
    var plan: Plan { Plan(goal: goal, steps: steps, speed: speed) }
    var origin: StepsOrigin { state.origin }
    var showsNoDataWarning: Bool { state.showsNoDataWarning }
    var hasOverride: Bool { state.override != nil }
    var lastUpdate: Date? { state.lastUpdate }

    // MARK: ciclo di vita

    /// Primo avvio: permesso, lettura, osservazione in tempo reale.
    func start() async {
        await controller.provider.requestAccess()
        await refresh()
        await controller.provider.observe { [weak self] in
            Task { @MainActor in await self?.refresh() }
        }
        startDayWatcher()
    }

    /// App in primo piano (anche ritorno da background).
    func becameActive() async {
        await refresh()
        await controller.provider.observe { [weak self] in
            Task { @MainActor in await self?.refresh() }
        }
        startDayWatcher()
    }

    /// App in background: nessun aggiornamento (niente background delivery nella v1).
    func becameInactive() async {
        await controller.provider.stopObserving()
        dayTask?.cancel()
        dayTask = nil
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
    }

    // MARK: passi manuali

    func setManualSteps(_ value: Int) {
        state.setManual(value, at: Date(), calendar: controller.calendar)
    }

    func useHealth() async {
        state.useHealth()
        await refresh()
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
