import Foundation
import HealthKit
import StepTellerCore

/// Adattatore sottile tra HealthKit e i protocolli del nucleo. **Solo lettura**.
///
/// - Il totale dei passi usa `HKStatisticsQuery` con `.cumulativeSum`: Salute deduplica iPhone e
///   Watch, quindi non si sommano mai i campioni a mano.
/// - iOS non dice se la lettura è stata negata: «nessun dato» e «permesso negato» coincidono
///   e qui diventano entrambi `nil`.
/// - Letti anche gli allenamenti di camminata/corsa (distanza, durata, passi) per la taratura.
final class HealthKitStepsProvider: StepsProvider, @unchecked Sendable {
    let store = HKHealthStore()
    let stepType = HKQuantityType(.stepCount)
    let distanceType = HKQuantityType(.distanceWalkingRunning)
    private let lock = NSLock()
    private var observer: HKObserverQuery?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAccess() async {
        guard isAvailable else { return }
        // Nessuna scrittura: toShare è vuoto. L'esito non dice se il permesso è stato dato.
        try? await store.requestAuthorization(toShare: [], read: [stepType, distanceType, HKObjectType.workoutType()])
    }

    func steps(from startOfDay: Date, to now: Date) async -> Int? {
        guard isAvailable else { return nil }
        return await stepsBetween(startOfDay, now)
    }

    /// Somma statistica dei passi in un intervallo (nil = nessun dato o errore).
    func stepsBetween(_ start: Date, _ end: Date) async -> Int? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0.rounded()) })
            }
            store.execute(query)
        }
    }

    /// Osserva i nuovi passi. Con la consegna in background (ogni ora al massimo) iOS può risvegliare
    /// l'app anche chiusa: serve ad aggiornare il promemoria serale.
    func observe(_ onChange: @escaping @Sendable () async -> Void) async {
        guard isAvailable else { return }
        await stopObserving()
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completion, error in
            guard error == nil else { completion(); return }
            Task {
                await onChange()
                completion()          // a iOS si dice «finito» solo dopo l'aggiornamento
            }
        }
        lock.lock(); observer = query; lock.unlock()
        store.execute(query)
        try? await store.enableBackgroundDelivery(for: stepType, frequency: .hourly)
    }

    func stopObserving() async {
        lock.lock(); let query = observer; observer = nil; lock.unlock()
        if let query { store.stop(query) }
    }
}
