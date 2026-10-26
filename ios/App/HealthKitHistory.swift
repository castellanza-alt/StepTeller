import Foundation
import HealthKit
import StepTellerCore

/// Daily history (steps and distance) from Health: one `HKStatisticsCollectionQuery` per type,
/// statistical sum (iPhone and Watch deduplicated). Read only.
extension HealthKitStepsProvider: HistoryProvider {
    func dailyRecords(until now: Date) async -> [DayRecord] {
        guard isAvailable, let first = await firstStepDate() else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: first)
        async let steps = dailyTotals(stepType, unit: .count(), from: start, to: now)
        async let km = dailyTotals(distanceType, unit: .meterUnit(with: .kilo), from: start, to: now)
        let (s, k) = await (steps, km)
        return s.keys.sorted().map { day in
            DayRecord(day: day, steps: Int((s[day] ?? 0).rounded()), km: k[day] ?? 0)
        }
    }

    private func firstStepDate() async -> Date? {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: stepType, predicate: nil, limit: 1,
                                      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                continuation.resume(returning: samples?.first?.startDate)
            }
            store.execute(query)
        }
    }

    private func dailyTotals(_ type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async -> [Date: Double] {
        await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            // strictStartDate: a sample counts in the day it starts in, so day totals never overlap
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum, anchorDate: start,
                                                    intervalComponents: DateComponents(day: 1))
            query.initialResultsHandler = { _, results, _ in
                var out: [Date: Double] = [:]
                results?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    if let value = statistics.sumQuantity()?.doubleValue(for: unit) {
                        out[calendar.startOfDay(for: statistics.startDate)] = value
                    }
                }
                continuation.resume(returning: out)
            }
            store.execute(query)
        }
    }
}
