import Foundation
import HealthKit
import StepTellerCore

/// Health on the watch: today's steps only, **read only** (same statistical sum as the iPhone app, deduplicated
/// between iPhone and Watch). Permissions are shared with the iPhone app: if NEAT may read steps on the phone,
/// the watch may too.
final class WatchHealth: StepsProvider, @unchecked Sendable {
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    private let lock = NSLock()
    private var observer: HKObserverQuery?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAccess() async {
        guard isAvailable else { return }
        // No writing: toShare is empty. The outcome does not say whether permission was granted.
        try? await store.requestAuthorization(toShare: [], read: [stepType])
    }

    func steps(from startOfDay: Date, to now: Date) async -> Int? {
        guard isAvailable else { return nil }
        return await HealthKitQueries.stepSum(store, type: stepType, from: startOfDay, to: now)
    }

    /// New steps while the app is on screen (no background delivery: the complications refresh on their own
    /// timeline and whenever the app is used).
    func observe(_ onChange: @escaping @Sendable () async -> Void) async {
        guard isAvailable else { return }
        await stopObserving()
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completion, error in
            guard error == nil else { completion(); return }
            Task {
                await onChange()
                completion()
            }
        }
        lock.withLock { observer = query }
        store.execute(query)
    }

    func stopObserving() async {
        let query = lock.withLock { () -> HKObserverQuery? in let q = observer; observer = nil; return q }
        if let query { store.stop(query) }
    }
}
