import Foundation

/// A walking or running workout read from Health (aggregate values only).
public struct WorkoutSample: Sendable, Equatable {
    public let date: Date
    public let distanceKm: Double
    public let durationMinutes: Double
    public let steps: Int

    public init(date: Date, distanceKm: Double, durationMinutes: Double, steps: Int) {
        self.date = date
        self.distanceKm = distanceKm
        self.durationMinutes = durationMinutes
        self.steps = steps
    }

    /// Average speed in km/h.
    public var speedKmh: Double { durationMinutes > 0 ? distanceKm / (durationMinutes / 60) : 0 }
    /// Average cadence in steps/min.
    public var cadence: Double { durationMinutes > 0 ? Double(steps) / durationMinutes : 0 }
}

/// Source of recent workouts (app: HealthKit; tests: fake).
public protocol WorkoutsProvider: Sendable {
    func workouts(since: Date) async -> [WorkoutSample]
}

/// Result of the automatic calibration.
public struct CalibrationResult: Sendable, Equatable, Codable {
    public struct Point: Sendable, Equatable, Codable {
        public let speed: Double
        public let cadence: Double
        public init(speed: Double, cadence: Double) { self.speed = speed; self.cadence = cadence }
    }
    public var walk: [Point]
    public var run: [Point]
    /// Workouts used (after discarding outliers).
    public var walkWorkouts: Int
    public var runWorkouts: Int

    public static let empty = CalibrationResult(walk: [], run: [], walkWorkouts: 0, runWorkouts: 0)
    public init(walk: [Point], run: [Point], walkWorkouts: Int, runWorkouts: Int) {
        self.walk = walk; self.run = run; self.walkWorkouts = walkWorkouts; self.runWorkouts = runWorkouts
    }

    /// Cadence model: the automatic calibration when available, otherwise the manual points in `Calibration`.
    public var model: CadenceModel {
        CadenceModel(walkCalibration: walk.isEmpty ? Calibration.walk : walkPoints,
                     runCalibration: run.isEmpty ? Calibration.run : runPoints)
    }

    public var walkPoints: [CalibrationPoint] { walk.map { CalibrationPoint(speed: $0.speed, cadence: $0.cadence) } }
    public var runPoints: [CalibrationPoint] { run.map { CalibrationPoint(speed: $0.speed, cadence: $0.cadence) } }
}

/// Automatic calibration: derives cadence points per gait from the workouts of the last 90 days.
///
/// Rules (all tested):
/// - only workouts ≥ 10 min with distance and steps, average speed 3–12 km/h and a plausible cadence count;
/// - the gait follows the average speed (from 7.1 km/h up it is running);
/// - per gait, workouts whose cadence/standard-curve ratio is more than 12% off the median ratio are
///   discarded (pauses, walks with the dog, bad GPS…);
/// - at least 2 good workouts per gait are needed, otherwise no point (manual calibration stays);
/// - with ≥ 2 speed buckets of 1 km/h holding at least 2 workouts each → one point per bucket (max 4);
///   otherwise a single point (medians of speed and cadence).
public enum AutoCalibration {
    public static let windowDays = 90
    public static let minMinutes = 10.0
    public static let outlierTolerance = 0.12

    public static func compute(from samples: [WorkoutSample], now: Date) -> CalibrationResult {
        let cutoff = now.addingTimeInterval(-Double(windowDays) * 86_400)
        let valid = samples.filter {
            $0.date >= cutoff && $0.date <= now
                && $0.durationMinutes >= minMinutes && $0.distanceKm > 0 && $0.steps > 0
                && (CadenceModel.minSpeed...CadenceModel.maxSpeed).contains($0.speedKmh)
                && (60.0...200.0).contains($0.cadence)
        }
        let running = valid.filter { $0.speedKmh >= CadenceModel.runFrom }
        let walking = valid.filter { $0.speedKmh < CadenceModel.runFrom }
        let (runPoints, runCount) = points(for: running)
        let (walkPoints, walkCount) = points(for: walking)
        return CalibrationResult(walk: walkPoints, run: runPoints, walkWorkouts: walkCount, runWorkouts: runCount)
    }

    private static func points(for samples: [WorkoutSample]) -> ([CalibrationResult.Point], Int) {
        guard samples.count >= 2 else { return ([], 0) }
        let ratios = samples.map { $0.cadence / CadenceModel.baseCadence(at: $0.speedKmh) }
        let med = median(ratios)
        let kept = zip(samples, ratios).filter { abs($0.1 - med) / med <= outlierTolerance }.map(\.0)
        guard kept.count >= 2 else { return ([], 0) }

        let buckets = Dictionary(grouping: kept) { Int($0.speedKmh.rounded()) }
            .filter { $0.value.count >= 2 }
        if buckets.count >= 2 {
            let chosen = buckets.sorted { $0.value.count > $1.value.count || ($0.value.count == $1.value.count && $0.key < $1.key) }
                .prefix(4)
            let pts = chosen.map { _, group in
                CalibrationResult.Point(speed: median(group.map(\.speedKmh)), cadence: median(group.map(\.cadence)))
            }.sorted { $0.speed < $1.speed }
            return (pts, kept.count)
        }
        return ([CalibrationResult.Point(speed: median(kept.map(\.speedKmh)), cadence: median(kept.map(\.cadence)))], kept.count)
    }

    static func median(_ values: [Double]) -> Double {
        let s = values.sorted()
        guard !s.isEmpty else { return 0 }
        return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
    }
}
