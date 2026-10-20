import Foundation

/// Source of today's steps. HealthKit in the app; fake in tests and screenshots.
public protocol StepsProvider: Sendable {
    /// `false` if the device has no Health: manual mode, no errors.
    var isAvailable: Bool { get }
    /// Asks for read permission (idempotent).
    func requestAccess() async
    /// Steps from the start of `day` up to `now`. `nil` = no samples or error
    /// (iOS does not tell «no data» from «permission denied»).
    func steps(from startOfDay: Date, to now: Date) async -> Int?
    /// Called whenever Health receives new steps, also with the app in the background
    /// (Health wakes the app at most hourly). The adapter tells iOS the work is done
    /// only after `onChange` has finished.
    func observe(_ onChange: @escaping @Sendable () async -> Void) async
    func stopObserving() async
}

/// Where the shown number comes from.
public enum StepsOrigin: Equatable, Sendable {
    case health
    case manual
}

/// Pure (testable) state of the steps source.
/// Rules: Health → manual → «Use Health»; the override expires when the day changes;
/// no data/error ⇒ 0 steps, «manual» origin and a warning.
public struct StepsState: Equatable, Sendable {
    public private(set) var healthSteps: Int = 0
    public private(set) var override: Int?
    public private(set) var overrideDay: Date?
    public private(set) var lastUpdate: Date?
    /// Health returned no data (empty, denied or error): show the warning.
    public private(set) var noHealthData = false
    public private(set) var healthAvailable = true

    public init() {}

    public var origin: StepsOrigin {
        override != nil || noHealthData || !healthAvailable ? .manual : .health
    }
    public var steps: Int { override ?? (noHealthData ? 0 : healthSteps) }
    /// «No data from Health…» warning only if Health exists and did not answer.
    public var showsNoDataWarning: Bool { healthAvailable && noHealthData }

    public mutating func setHealthAvailable(_ value: Bool) { healthAvailable = value }

    /// Outcome of a Health read (`nil` = no data or error).
    public mutating func applyHealth(_ value: Int?, at date: Date) {
        // 0 counts as «no data»: without samples Health answers nil, not 0, and a denied permission looks
        // the same (documented rule: 0 steps, manual origin, warning).
        if let value, value > 0 {
            healthSteps = value
            noHealthData = false
        } else {
            healthSteps = 0
            noHealthData = true
        }
        lastUpdate = date
    }

    /// Manual override typed by the user, valid for the day of `date`.
    public mutating func setManual(_ value: Int, at date: Date, calendar: Calendar) {
        override = max(0, value)
        overrideDay = calendar.startOfDay(for: date)
        lastUpdate = date
    }

    /// «Use Health»: drops the override.
    public mutating func useHealth() {
        override = nil
        overrideDay = nil
    }

    /// Day change: the override expires and yesterday's steps no longer count.
    /// Returns `true` if something changed.
    @discardableResult
    public mutating func rollDay(now: Date, calendar: Calendar) -> Bool {
        guard let day = overrideDay, day != calendar.startOfDay(for: now) else { return false }
        useHealth()
        return true
    }
}
