import Foundation
import HealthKit
import StepTellerCore

/// Thin adapter between HealthKit and the core protocols. **Read only**.
///
/// - The step total uses `HKStatisticsQuery` with `.cumulativeSum`: Health deduplicates iPhone and
///   Watch, so samples are never summed by hand.
/// - iOS does not say whether reading was denied: «no data» and «permission denied» look the same
///   and both become `nil` here.
/// - Walking/running workouts (distance, duration, steps) are read too, for the calibration.
final class HealthKitStepsProvider: StepsProvider, @unchecked Sendable {
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    let distanceType = HKQuantityType(.distanceWalkingRunning)
    private let lock = NSLock()
    private var observer: HKObserverQuery?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAccess() async {
        guard isAvailable else { return }
        // No writing: toShare is empty. The outcome does not say whether permission was granted.
        try? await store.requestAuthorization(toShare: [], read: [stepType, distanceType, HKObjectType.workoutType()])
    }

    func steps(from startOfDay: Date, to now: Date) async -> Int? {
        guard isAvailable else { return nil }
        return await stepsBetween(startOfDay, now)
    }

    /// Statistical sum of the steps in a range (nil = no data or error).
    func stepsBetween(_ start: Date, _ end: Date) async -> Int? {
        await HealthKitQueries.stepSum(store, type: stepType, from: start, to: end)
    }

    /// Observes new steps. With background delivery (hourly at most) iOS can wake the app even when
    /// closed: that keeps the evening reminder up to date.
    func observe(_ onChange: @escaping @Sendable () async -> Void) async {
        guard isAvailable else { return }
        await stopObserving()
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completion, error in
            guard error == nil else { completion(); return }
            Task {
                await onChange()
                completion()          // iOS is told «done» only after the update
            }
        }
        lock.withLock { observer = query }
        store.execute(query)
        try? await store.enableBackgroundDelivery(for: stepType, frequency: .hourly)
    }

    func stopObserving() async {
        let query = lock.withLock { () -> HKObserverQuery? in let q = observer; observer = nil; return q }
        if let query { store.stop(query) }
    }
}
