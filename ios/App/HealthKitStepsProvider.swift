import Foundation
import HealthKit
import StepTellerCore

/// Adattatore sottile tra HealthKit e `StepsProvider`. **Solo lettura** dei passi.
///
/// - Il totale usa `HKStatisticsQuery` con `.cumulativeSum`: Salute deduplica iPhone e Watch,
///   quindi non si sommano mai i campioni a mano.
/// - iOS non dice se la lettura è stata negata: «nessun dato» e «permesso negato» coincidono
///   e qui diventano entrambi `nil`.
final class HealthKitStepsProvider: StepsProvider, @unchecked Sendable {
    private let store = HKHealthStore()
    private let type = HKQuantityType(.stepCount)
    private let lock = NSLock()
    private var observer: HKObserverQuery?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAccess() async {
        guard isAvailable else { return }
        // Nessuna scrittura: toShare è vuoto. L'esito non dice se il permesso è stato dato.
        try? await store.requestAuthorization(toShare: [], read: [type])
    }

    func steps(from startOfDay: Date, to now: Date) async -> Int? {
        guard isAvailable else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, _ in
                // Errore o nessun campione: statistics è nil → nessun dato.
                let value = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0.rounded()) })
            }
            store.execute(query)
        }
    }

    func observe(_ onChange: @escaping @Sendable () -> Void) async {
        guard isAvailable else { return }
        await stopObserving()
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
            if error == nil { onChange() }
            completion()
        }
        lock.lock(); observer = query; lock.unlock()
        store.execute(query)
    }

    func stopObserving() async {
        lock.lock(); let query = observer; observer = nil; lock.unlock()
        if let query { store.stop(query) }
    }
}
