import Foundation

/// Risultato del calcolo per una velocità, un obiettivo e i passi di oggi.
public struct Plan: Sendable, Equatable {
    public let goal: Int
    public let steps: Int
    public let speed: Double
    public let cadence: Double
    public let gait: Gait
    /// Passi mancanti all'obiettivo (mai negativi).
    public let remaining: Int
    /// Minuti di tappeto (0 se l'obiettivo è chiuso).
    public let minutes: Int
    public let km: Double

    /// Obiettivo chiuso: stato «Fatto».
    public var isDone: Bool { remaining == 0 }
    /// Avanzamento 0…1 (obiettivo 0 ⇒ 1).
    public var progress: Double { goal > 0 ? min(1, Double(steps) / Double(goal)) : 1 }
    /// Velocità di riferimento del widget: camminata normale, solo per dare un'idea di massima.
    public static let glanceSpeed = 4.0

    public init(goal: Int, steps: Int, speed: Double, model: CadenceModel = .standard) {
        let v = min(CadenceModel.maxSpeed, max(CadenceModel.minSpeed, speed))
        let cad = model.cadence(at: v)
        let gap = max(0, goal - steps)
        self.goal = goal
        self.steps = steps
        self.speed = v
        self.cadence = cad
        self.gait = model.gait(at: v)
        self.remaining = gap
        self.minutes = gap > 0 ? Int((Double(gap) / cad).rounded(.up)) : 0
        self.km = v * Double(minutes) / 60
    }
}

extension Plan {
    /// Quando finirebbe il tappeto se si parte a `start` (per il conto alla rovescia).
    public func finishDate(from start: Date) -> Date { start.addingTimeInterval(Double(minutes) * 60) }
}
