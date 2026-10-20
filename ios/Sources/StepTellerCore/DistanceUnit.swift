import Foundation

/// Unit shown for distances and speeds. **Display only**: speeds stay in km/h everywhere inside
/// (computation, calibration, App Group); the miles are a conversion at the edges.
public enum DistanceUnit: String, Sendable, CaseIterable {
    case kilometers
    case miles

    public static let kmPerMile = 1.609344

    /// Slider range and step in this unit: 3–16 km/h or 2–10 mph, both in 0.5 steps.
    public var minSpeed: Double { self == .miles ? 2 : SpeedTrack.minSpeed }
    public var maxSpeed: Double { self == .miles ? 10 : SpeedTrack.maxSpeed }
    public var step: Double { SpeedTrack.step }

    /// Speeds (km/h) the slider can produce in any unit: 3 km/h … 10 mph (16.09 km/h).
    public static let kmhRange: ClosedRange<Double> =
        min(SpeedTrack.minSpeed, 2 * kmPerMile)...max(SpeedTrack.maxSpeed, 10 * kmPerMile)

    /// Kilometers (or km/h) → this unit.
    public func value(fromKm km: Double) -> Double { self == .miles ? km / Self.kmPerMile : km }

    /// This unit → kilometers (or km/h).
    public func km(fromValue v: Double) -> Double { self == .miles ? v * Self.kmPerMile : v }

    /// Value in this unit clamped to the range and rounded to the step.
    public func snap(_ v: Double) -> Double {
        min(maxSpeed, max(minSpeed, (v / step).rounded() * step))
    }

    /// Speed in km/h moved to the nearest step of this unit (4 km/h → 2.5 mph → 4.02 km/h).
    /// For kilometers it is `SpeedTrack.snap`.
    public func snapKmh(_ kmh: Double) -> Double { km(fromValue: snap(value(fromKm: kmh))) }

    /// Speed (km/h) one step above or below, in this unit.
    public func kmh(_ kmh: Double, steps: Int) -> Double {
        km(fromValue: snap(snap(value(fromKm: kmh)) + Double(steps) * step))
    }

    /// Speed (km/h, on the step of this unit) for a fraction 0…1 of the road.
    public func kmh(forFraction f: Double) -> Double {
        km(fromValue: snap(minSpeed + min(1, max(0, f)) * (maxSpeed - minSpeed)))
    }

    /// Fraction 0…1 of the road for a speed in km/h.
    public func fraction(forKmh kmh: Double) -> Double {
        (min(maxSpeed, max(minSpeed, value(fromKm: kmh))) - minSpeed) / (maxSpeed - minSpeed)
    }
}

/// Choice in Settings: automatic (from the phone's region) or forced.
public enum UnitPreference: String, Sendable, CaseIterable {
    case automatic
    case kilometers
    case miles

    /// `regionUsesMiles`: the phone's measurement system is the US or UK one.
    public func resolved(regionUsesMiles: Bool) -> DistanceUnit {
        switch self {
        case .automatic: regionUsesMiles ? .miles : .kilometers
        case .kilometers: .kilometers
        case .miles: .miles
        }
    }
}
