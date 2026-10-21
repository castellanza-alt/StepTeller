import HealthKit

/// Health reads shared by app and widget. **Read only.**
enum HealthKitQueries {
    /// Statistical sum of the steps between `start` and `end` (`nil` = no data or error). `HKStatisticsQuery` with
    /// `.cumulativeSum`: Health deduplicates iPhone and Watch, so samples are never summed by hand.
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
