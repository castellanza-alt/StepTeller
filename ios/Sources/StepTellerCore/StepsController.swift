import Foundation

/// Coordina provider e stato: la logica di aggiornamento senza dipendere da HealthKit.
///
/// Per non tenere uno `inout` aperto attraverso un `await` (l'interfaccia può modificare lo
/// stato nel frattempo), l'app usa i tre passi separati `begin` → `read` → `applyHealth`;
/// `refresh` li riunisce per i test.
public struct StepsController: Sendable {
    public let provider: any StepsProvider
    public var calendar: Calendar

    public init(provider: any StepsProvider, calendar: Calendar = .current) {
        self.provider = provider
        self.calendar = calendar
    }

    /// Passo 1 (sincrono): disponibilità di Salute e scadenza della sovrascrittura.
    /// Restituisce `false` se non c'è nulla da leggere (Salute assente).
    @discardableResult
    public func begin(_ state: inout StepsState, now: Date) -> Bool {
        state.setHealthAvailable(provider.isAvailable)
        state.rollDay(now: now, calendar: calendar)
        return provider.isAvailable
    }

    /// Passo 2: lettura dei passi di oggi (`nil` = nessun dato o errore).
    public func read(now: Date) async -> Int? {
        await provider.steps(from: calendar.startOfDay(for: now), to: now)
    }

    /// Tutti e tre i passi insieme.
    public func refresh(_ state: inout StepsState, now: Date = Date()) async {
        guard begin(&state, now: now) else { return }
        let value = await read(now: now)
        state.applyHealth(value, at: now)
    }
}
