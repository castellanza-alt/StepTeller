import Foundation

/// Source of today's steps. HealthKit in the app; fake in tests and screenshots.
public protocol StepsProvider: Sendable {
    /// `false` if the device has no Health: 0 steps, no errors.
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

/// Where the shown number comes from: Health, or nothing (no Health, no data, error: 0 steps).
/// Steps can't be typed by hand (removed in 1.1).
public enum StepsOrigin: Equatable, Sendable {
    case health
    case unavailable
}

/// Pure (testable) state of the steps source.
/// Rules: steps only from Health; no data/error ⇒ 0 steps, origin `.unavailable` and a warning.
public struct StepsState: Equatable, Sendable {
    public private(set) var healthSteps: Int = 0
    public private(set) var lastUpdate: Date?
    /// Health returned no data (empty, denied or error): show the warning.
    public private(set) var noHealthData = false
    public private(set) var healthAvailable = true

    public init() {}

    public var origin: StepsOrigin {
        noHealthData || !healthAvailable ? .unavailable : .health
    }
    public var steps: Int { noHealthData ? 0 : healthSteps }
    /// «No data from Health…» warning only if Health exists and did not answer.
    public var showsNoDataWarning: Bool { healthAvailable && noHealthData }

    public mutating func setHealthAvailable(_ value: Bool) { healthAvailable = value }

    /// Outcome of a Health read (`nil` = no data or error).
    public mutating func applyHealth(_ value: Int?, at date: Date) {
        // 0 counts as «no data»: without samples Health answers nil, not 0, and a denied permission looks
        // the same (documented rule: 0 steps, no origin, warning).
        if let value, value > 0 {
            healthSteps = value
            noHealthData = false
        } else {
            healthSteps = 0
            noHealthData = true
        }
        lastUpdate = date
    }

    /// Last count known from a previous launch (today only), shown until the first Health read so the app
    /// never opens on 0. It does not set `lastUpdate`: the real read replaces it as usual.
    public mutating func seed(cachedSteps value: Int) {
        guard value > 0, lastUpdate == nil else { return }
        healthSteps = value
        noHealthData = false
    }
}
