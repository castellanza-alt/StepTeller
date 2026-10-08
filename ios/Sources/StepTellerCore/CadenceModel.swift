import Foundation

/// Andatura: sotto `CadenceModel.runFrom` si cammina, da lì si corre.
public enum Gait: String, Sendable {
    case walk
    case run

    /// Etichetta italiana mostrata nell'interfaccia.
    public var label: String { self == .run ? "corsa" : "cammino" }
}

/// Punto di taratura: velocità (km/h) e cadenza misurata (passi/min).
public struct CalibrationPoint: Sendable, Equatable {
    public let speed: Double
    public let cadence: Double
    public init(speed: Double, cadence: Double) {
        self.speed = speed
        self.cadence = cadence
    }
}

/// Punti di taratura personali. **È l'unico posto dove aggiungerne.**
/// Quando arriva un export di camminata: aggiungere qui un punto a `walk`
/// (es. `CalibrationPoint(speed: 5.0, cadence: 112.0)`).
public enum Calibration {
    /// Camminata: nessun punto, rapporto 1 (curva standard).
    public static let walk: [CalibrationPoint] = []
    /// Corsa: media di due uscite HealthFit (13 set 2026: 8,28 km/h · 154,8 spm;
    /// 15 set 2026: 8,31 km/h · 152,2 spm).
    public static let run: [CalibrationPoint] = [CalibrationPoint(speed: 8.3, cadence: 153.5)]
}

/// Modello di cadenza: `passi = cadenza(v) × minuti`.
public struct CadenceModel: Sendable {
    public typealias Curve = [(Double, Double)]

    /// Da questa velocità (inclusa) si corre.
    public static let runFrom = 7.1
    public static let minSpeed = 3.0
    public static let maxSpeed = 12.0

    /// Cammino: letteratura, uomo ~178 cm (Inferred).
    static let defaultWalk: Curve = [(2, 75), (3, 90), (4, 101), (5, 110), (6, 119), (7, 129), (8, 138)]
    /// Corsa: letteratura.
    static let defaultRun: Curve = [(6, 152), (7, 156), (8, 159), (9, 162), (10, 165), (12, 170), (14, 176)]

    private let walkPoints: [CalibrationPoint]
    private let runPoints: [CalibrationPoint]

    public init(walkCalibration: [CalibrationPoint] = Calibration.walk,
                runCalibration: [CalibrationPoint] = Calibration.run) {
        walkPoints = walkCalibration
        runPoints = runCalibration
    }

    /// Modello con la taratura reale di Will.
    public static let standard = CadenceModel()

    public func gait(at speed: Double) -> Gait { speed >= Self.runFrom ? .run : .walk }

    /// Cadenza della curva standard (senza taratura) alla velocità `speed`.
    static func baseCadence(at speed: Double) -> Double {
        Self.interp(speed >= runFrom ? defaultRun : defaultWalk, speed)
    }

    /// Cadenza in passi/min alla velocità `speed` (km/h).
    public func cadence(at speed: Double) -> Double {
        let g = gait(at: speed)
        let curve = g == .run ? Self.defaultRun : Self.defaultWalk
        return Self.interp(curve, speed) * ratio(gait: g, speed: speed)
    }

    /// Interpolazione lineare a tratti; fuori dai punti si estrapola sul primo/ultimo segmento.
    static func interp(_ p: Curve, _ v: Double) -> Double {
        var i = 0
        while i < p.count - 2 && v > p[i + 1].0 { i += 1 }
        let (x0, y0) = p[i], (x1, y1) = p[i + 1]
        return y0 + (y1 - y0) * (v - x0) / (x1 - x0)
    }

    /// Rapporto misurato/standard: 0 punti → 1; 1 punto → costante;
    /// 2+ punti → interpolato, costante oltre gli estremi.
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
