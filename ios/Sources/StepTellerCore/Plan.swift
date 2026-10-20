import Foundation

/// Result of the computation for a speed, a goal and today's steps.
public struct Plan: Sendable, Equatable {
    public let goal: Int
    public let steps: Int
    public let speed: Double
    public let cadence: Double
    public let gait: Gait
    /// Steps missing to the goal (never negative).
    public let remaining: Int
    /// Treadmill minutes (0 once the goal is reached).
    public let minutes: Int
    public let km: Double

    /// Goal reached: «Done» state.
    public var isDone: Bool { remaining == 0 }
    /// Progress 0…1 (goal 0 ⇒ 1).
    public var progress: Double { goal > 0 ? min(1, Double(steps) / Double(goal)) : 1 }
    /// Ordinary walking pace, a rough reference used by the tests (the widget uses the Home slider speed).
    public static let glanceSpeed = 4.0

    public init(goal: Int, steps: Int, speed: Double, model: CadenceModel = .standard) {
        let v = min(SpeedTrack.maxSpeed, max(SpeedTrack.minSpeed, speed))
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
