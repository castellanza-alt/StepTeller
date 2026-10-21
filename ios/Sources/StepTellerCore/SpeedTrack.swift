import Foundation

/// Path of the speed slider: the dashed line of the road in the Home illustration.
/// Coordinates are **illustration pixels** (881 × 1786); the view converts them to points.
/// Path start = `minSpeed`, end = `maxSpeed`, linear along the arc length.
public struct SpeedTrack: Sendable {
    public struct Point: Sendable, Equatable {
        public var x: Double
        public var y: Double
        public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    }

    public static let minSpeed = 3.0
    public static let maxSpeed = 16.0
    public static let step = 0.5
    public static let defaultSpeed = 4.0

    /// `M 50 1697 C 170 1664, 310 1630, 480 1604 C 590 1586, 660 1560, 690 1530
    ///  C 715 1500, 712 1450, 690 1420 C 670 1395, 630 1385, 600 1380` (from the handoff).
    public static let road = SpeedTrack(start: Point(50, 1697), curves: [
        (Point(170, 1664), Point(310, 1630), Point(480, 1604)),
        (Point(590, 1586), Point(660, 1560), Point(690, 1530)),
        (Point(715, 1500), Point(712, 1450), Point(690, 1420)),
        (Point(670, 1395), Point(630, 1385), Point(600, 1380)),
    ])

    /// Points sampled along the path and cumulative length up to each one.
    public let samples: [Point]
    public let lengths: [Double]
    public var totalLength: Double { lengths.last ?? 0 }

    public init(start: Point, curves: [(Point, Point, Point)], samplesPerCurve: Int = 128) {
        var pts = [start]
        var p0 = start
        for (c1, c2, p3) in curves {
            for i in 1...samplesPerCurve {
                let t = Double(i) / Double(samplesPerCurve), u = 1 - t
                let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                pts.append(Point(a * p0.x + b * c1.x + c * c2.x + d * p3.x,
                                 a * p0.y + b * c1.y + c * c2.y + d * p3.y))
            }
            p0 = p3
        }
        var lens = [0.0]
        for i in 1..<pts.count { lens.append(lens[i - 1] + Self.distance(pts[i - 1], pts[i])) }
        samples = pts
        lengths = lens
    }

    /// Point at a fraction 0…1 of the length.
    public func point(atFraction f: Double) -> Point {
        let target = min(1, max(0, f)) * totalLength
        var lo = 0, hi = lengths.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if lengths[mid] < target { lo = mid } else { hi = mid }
        }
        let span = lengths[hi] - lengths[lo]
        let t = span > 0 ? (target - lengths[lo]) / span : 0
        let a = samples[lo], b = samples[hi]
        return Point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
    }

    /// Projection onto the path: fraction of the nearest point and its distance (same units as the points).
    public func nearest(to p: Point) -> (fraction: Double, distance: Double) {
        var best = (fraction: 0.0, distance: Double.infinity)
        for i in 1..<samples.count {
            let a = samples[i - 1], b = samples[i]
            let dx = b.x - a.x, dy = b.y - a.y
            let len2 = dx * dx + dy * dy
            let t = len2 > 0 ? min(1, max(0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2)) : 0
            let q = Point(a.x + dx * t, a.y + dy * t)
            let d = Self.distance(p, q)
            if d < best.distance {
                let along = lengths[i - 1] + (lengths[i] - lengths[i - 1]) * t
                best = (totalLength > 0 ? along / totalLength : 0, d)
            }
        }
        return best
    }

    /// Speed (rounded to `step`) for a fraction of the path.
    public static func speed(forFraction f: Double) -> Double {
        snap(minSpeed + min(1, max(0, f)) * (maxSpeed - minSpeed))
    }

    /// Fraction of the path for a speed.
    public static func fraction(forSpeed v: Double) -> Double {
        (min(maxSpeed, max(minSpeed, v)) - minSpeed) / (maxSpeed - minSpeed)
    }

    /// Speed clamped to the range and rounded to the step (0.5).
    public static func snap(_ v: Double) -> Double {
        min(maxSpeed, max(minSpeed, (v / step).rounded() * step))
    }

    static func distance(_ a: Point, _ b: Point) -> Double {
        ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot()
    }
}
