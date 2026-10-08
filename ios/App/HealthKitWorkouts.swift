import Foundation
import HealthKit
import StepTellerCore

/// Allenamenti di camminata e corsa degli ultimi giorni, come valori aggregati.
extension HealthKitStepsProvider: WorkoutsProvider {
    func workouts(since: Date) async -> [WorkoutSample] {
        guard isAvailable else { return [] }
        let period = HKQuery.predicateForSamples(withStart: since, end: Date(), options: .strictStartDate)
        let kinds = NSCompoundPredicate(orPredicateWithSubpredicates: [
            HKQuery.predicateForWorkouts(with: .walking), HKQuery.predicateForWorkouts(with: .running)])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [period, kinds])
        let found: [HKWorkout] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 200,
                                      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
        var result: [WorkoutSample] = []
        for workout in found {
            guard let km = workout.statistics(for: distanceType)?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) else { continue }
            var steps = workout.statistics(for: stepType)?.sumQuantity()?.doubleValue(for: .count()).rounded()
            if steps == nil, let s = await stepsBetween(workout.startDate, workout.endDate) { steps = Double(s) }
            guard let steps else { continue }
            result.append(WorkoutSample(date: workout.startDate, distanceKm: km,
                                        durationMinutes: workout.duration / 60, steps: Int(steps)))
        }
        return result
    }
}
