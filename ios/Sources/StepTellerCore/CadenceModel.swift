import Foundation

/// Gait: below `CadenceModel.runFrom` you walk, from there you run.
public enum Gait: String, Sendable {
    case walk
    case run
}

/// Calibration point: speed (km/h) and measured cadence (steps/min).
public struct CalibrationPoint: Sendable, Equatable {
    public let speed: Double
    public let cadence: Double
    public init(speed: Double, cadence: Double) {
        self.speed = speed
        self.cadence = cadence
    }
}

/// Personal calibration points. **The only place to add them.**
/// When a walking export arrives, add a point to `walk` here
/// (e.g. `CalibrationPoint(speed: 5.0, cadence: 112.0)`).
public enum Calibration {
    /// Walking: no points, ratio 1 (standard curve).
    public static let walk: [CalibrationPoint] = []
    /// Running: average of two HealthFit runs (13 Sep 2026: 8.28 km/h · 154.8 spm;
    /// 15 Sep 2026: 8.31 km/h · 152.2 spm).
    public static let run: [CalibrationPoint] = [CalibrationPoint(speed: 8.3, cadence: 153.5)]
}

/// Cadence model: `steps = cadence(v) × minutes`.
public struct CadenceModel: Sendable {
    public typealias Curve = [(Double, Double)]

    /// From this speed (inclusive) you run.
    public static let runFrom = 7.1
    /// Speeds accepted by the automatic calibration (workouts outside are ignored).
    /// The app's slider goes further (up to `SpeedTrack.maxSpeed`): the curve is extrapolated.
    public static let minSpeed = 3.0
    public static let maxSpeed = 12.0

    /// Walking: literature, man ~178 cm (inferred).
    static let defaultWalk: Curve = [(2, 75), (3, 90), (4, 101), (5, 110), (6, 119), (7, 129), (8, 138)]
    /// Running: literature.
    static let defaultRun: Curve = [(6, 152), (7, 156), (8, 159), (9, 162), (10, 165), (12, 170), (14, 176)]

    private let walkPoints: [CalibrationPoint]
    private let runPoints: [CalibrationPoint]

    public init(walkCalibration: [CalibrationPoint] = Calibration.walk,
                runCalibration: [CalibrationPoint] = Calibration.run) {
        walkPoints = walkCalibration
        runPoints = runCalibration
    }

    /// Model with Will's real calibration.
    public static let standard = CadenceModel()

    public func gait(at speed: Double) -> Gait { speed >= Self.runFrom ? .run : .walk }

    /// Cadence of the standard curve (no calibration) at `speed`.
    static func baseCadence(at speed: Double) -> Double {
        Self.interp(speed >= runFrom ? defaultRun : defaultWalk, speed)
    }

    /// Cadence in steps/min at `speed` (km/h).
    public func cadence(at speed: Double) -> Double {
        let g = gait(at: speed)
        let curve = g == .run ? Self.defaultRun : Self.defaultWalk
        return Self.interp(curve, speed) * ratio(gait: g, speed: speed)
    }

    /// Piecewise linear interpolation; outside the points it extrapolates on the first/last segment.
    static func interp(_ p: Curve, _ v: Double) -> Double {
        var i = 0
        while i < p.count - 2 && v > p[i + 1].0 { i += 1 }
        let (x0, y0) = p[i], (x1, y1) = p[i + 1]
        return y0 + (y1 - y0) * (v - x0) / (x1 - x0)
    }

    /// Measured/standard ratio: 0 points → 1; 1 point → constant;
    /// 2+ points → interpolated, constant beyond the extremes.
    private func ratio(gait g: Gait, speed v: Double) -> Double {
        let curve = g == .run ? Self.defaultRun : Self.defaultWalk
        let cal = g == .run ? runPoints : walkPoints
        let p: Curve = cal.map { ($0.speed, $0.cadence / Self.interp(curve, $0.speed)) }.sorted { $0.0 < $1.0 }
        guard let first = p.first, let last = p.last else { return 1 }
        if p.count == 1 || v <= first.0 { return first.1 }
        if v >= last.0 { return last.1 }
        return Self.interp(p, v)
    }
}
