import Foundation

/// Un allenamento di camminata o corsa letto da Salute (solo valori aggregati).
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

    /// Velocità media in km/h.
    public var speedKmh: Double { durationMinutes > 0 ? distanceKm / (durationMinutes / 60) : 0 }
    /// Cadenza media in passi/min.
    public var cadence: Double { durationMinutes > 0 ? Double(steps) / durationMinutes : 0 }
}

/// Fornitore degli allenamenti recenti (in app: HealthKit; nei test: finto).
public protocol WorkoutsProvider: Sendable {
    func workouts(since: Date) async -> [WorkoutSample]
}

/// Esito della taratura automatica.
public struct CalibrationResult: Sendable, Equatable, Codable {
    public struct Point: Sendable, Equatable, Codable {
        public let speed: Double
        public let cadence: Double
        public init(speed: Double, cadence: Double) { self.speed = speed; self.cadence = cadence }
    }
    public var walk: [Point]
    public var run: [Point]
    /// Allenamenti usati (dopo aver scartato quelli anomali).
    public var walkWorkouts: Int
    public var runWorkouts: Int

    public static let empty = CalibrationResult(walk: [], run: [], walkWorkouts: 0, runWorkouts: 0)
    public init(walk: [Point], run: [Point], walkWorkouts: Int, runWorkouts: Int) {
        self.walk = walk; self.run = run; self.walkWorkouts = walkWorkouts; self.runWorkouts = runWorkouts
    }

    /// Modello di cadenza: taratura automatica se c'è, altrimenti quella manuale di `Calibration`.
    public var model: CadenceModel {
        CadenceModel(walkCalibration: walk.isEmpty ? Calibration.walk : walkPoints,
                     runCalibration: run.isEmpty ? Calibration.run : runPoints)
    }

    public var walkPoints: [CalibrationPoint] { walk.map { CalibrationPoint(speed: $0.speed, cadence: $0.cadence) } }
    public var runPoints: [CalibrationPoint] { run.map { CalibrationPoint(speed: $0.speed, cadence: $0.cadence) } }
}

/// Taratura automatica: dagli allenamenti degli ultimi 90 giorni ricava punti di cadenza per andatura.
///
/// Regole (tutte testate):
/// - contano solo allenamenti ≥ 10 min, con distanza e passi, velocità media 3–12 km/h e cadenza plausibile;
/// - l'andatura si decide dalla velocità media (da 7,1 km/h in su è corsa);
/// - per andatura si scartano gli allenamenti che si discostano più del 12% dal rapporto mediano
///   rispetto alla curva standard (pause, camminate con cane, GPS sbagliato…);
/// - servono almeno 2 allenamenti buoni per andatura, altrimenti nessun punto (resta la taratura manuale);
/// - con ≥ 2 fasce di velocità da 1 km/h con almeno 2 allenamenti ciascuna → un punto per fascia (max 4);
///   altrimenti un solo punto (mediane di velocità e cadenza).
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
