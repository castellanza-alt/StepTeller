import Foundation

/// Coordinates provider and state: the update logic without depending on HealthKit.
///
/// To avoid holding an `inout` across an `await` (the UI may change the state meanwhile), the app uses
/// the three separate steps `begin` → `read` → `applyHealth`; `refresh` chains them for the tests.
public struct StepsController: Sendable {
    public let provider: any StepsProvider
    public var calendar: Calendar

    public init(provider: any StepsProvider, calendar: Calendar = .current) {
        self.provider = provider
        self.calendar = calendar
    }

    /// Step 1 (synchronous): Health availability.
    /// Returns `false` if there is nothing to read (no Health).
    @discardableResult
    public func begin(_ state: inout StepsState, now: Date) -> Bool {
        state.setHealthAvailable(provider.isAvailable)
        return provider.isAvailable
    }

    /// Step 2: reads today's steps (`nil` = no data or error).
    public func read(now: Date) async -> Int? {
        await provider.steps(from: calendar.startOfDay(for: now), to: now)
    }

    /// All three steps together.
    public func refresh(_ state: inout StepsState, now: Date = Date()) async {
        guard begin(&state, now: now) else { return }
        let value = await read(now: now)
        state.applyHealth(value, at: now)
    }
}
