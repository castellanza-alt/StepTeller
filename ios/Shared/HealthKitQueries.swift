import HealthKit

/// Letture di Salute comuni ad app e widget. **Solo lettura.**
enum HealthKitQueries {
    /// Somma statistica dei passi tra `start` ed `end` (`nil` = nessun dato o errore). `HKStatisticsQuery` con
    /// `.cumulativeSum`: Salute deduplica iPhone e Watch, quindi non si sommano mai i campioni a mano.
    static func stepSum(_ store: HKHealthStore, type: HKQuantityType, from start: Date, to end: Date) async -> Int? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: value.map { Int($0.rounded()) })
            }
            store.execute(query)
        }
    }
}
