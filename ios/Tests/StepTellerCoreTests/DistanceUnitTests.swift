import XCTest
@testable import StepTellerCore

/// Miles: conversions, 0.5 mph steps and mapping on the same road. Inside everything stays km/h.
final class DistanceUnitTests: XCTestCase {
    let km = DistanceUnit.kilometers, mi = DistanceUnit.miles

    func testConversions() {
        XCTAssertEqual(mi.value(fromKm: 1.609344), 1, accuracy: 1e-12)
        XCTAssertEqual(mi.value(fromKm: 10), 6.2137, accuracy: 1e-4)
        XCTAssertEqual(mi.km(fromValue: 3), 4.828032, accuracy: 1e-9)
        XCTAssertEqual(km.value(fromKm: 6.7), 6.7)
        XCTAssertEqual(km.km(fromValue: 6.7), 6.7)
        for v in stride(from: 0.0, through: 30, by: 0.37) {
            XCTAssertEqual(mi.km(fromValue: mi.value(fromKm: v)), v, accuracy: 1e-9)
        }
    }

    func testRanges() {
        XCTAssertEqual(mi.minSpeed, 2)
        XCTAssertEqual(mi.maxSpeed, 10)
        XCTAssertEqual(km.minSpeed, 3)
        XCTAssertEqual(km.maxSpeed, 16)
        XCTAssertEqual(DistanceUnit.kmhRange.lowerBound, 3)
        XCTAssertEqual(DistanceUnit.kmhRange.upperBound, 16.09344, accuracy: 1e-9)
    }

    func testSnapToHalfMph() {
        XCTAssertEqual(mi.snap(3.2), 3)
        XCTAssertEqual(mi.snap(3.3), 3.5)
        XCTAssertEqual(mi.snap(1), 2)
        XCTAssertEqual(mi.snap(12), 10)
        // 4 km/h = 2.49 mph → 2.5 mph; 6 km/h = 3.73 mph → 3.5 mph
        XCTAssertEqual(mi.snapKmh(4), 2.5 * 1.609344, accuracy: 1e-9)
        XCTAssertEqual(mi.snapKmh(6), 3.5 * 1.609344, accuracy: 1e-9)
        XCTAssertEqual(mi.value(fromKm: mi.snapKmh(16)), 10, accuracy: 1e-9)
        // already on a step: unchanged (no float drift)
        for v in stride(from: 2.0, through: 10.0, by: 0.5) {
            let kmh = mi.km(fromValue: v)
            XCTAssertEqual(mi.snapKmh(kmh), kmh, accuracy: 1e-9)
        }
    }

    func testKilometersMatchTheRoad() {
        for v in stride(from: 0.0, through: 20, by: 0.1) {
            XCTAssertEqual(km.snapKmh(v), SpeedTrack.snap(v))
            XCTAssertEqual(km.fraction(forKmh: v), SpeedTrack.fraction(forSpeed: v), accuracy: 1e-12)
        }
        for f in stride(from: 0.0, through: 1, by: 0.01) {
            XCTAssertEqual(km.kmh(forFraction: f), SpeedTrack.speed(forFraction: f))
        }
    }

    func testMilesOnTheRoad() {
        XCTAssertEqual(mi.kmh(forFraction: 0), 2 * 1.609344, accuracy: 1e-9)
        XCTAssertEqual(mi.kmh(forFraction: 1), 10 * 1.609344, accuracy: 1e-9)
        XCTAssertEqual(mi.value(fromKm: mi.kmh(forFraction: 0.5)), 6, accuracy: 1e-9)
        XCTAssertEqual(mi.fraction(forKmh: mi.km(fromValue: 4)), 0.25, accuracy: 1e-12)
        // every step projects onto the road and comes back to the same step
        let track = SpeedTrack.road
        var last = -1.0
        for v in stride(from: 2.0, through: 10.0, by: 0.5) {
            let kmh = mi.km(fromValue: v)
            let p = track.point(atFraction: mi.fraction(forKmh: kmh))
            let n = track.nearest(to: p)
            XCTAssertLessThan(n.distance, 0.5)
            XCTAssertEqual(mi.value(fromKm: mi.kmh(forFraction: n.fraction)), v, accuracy: 1e-9, "v=\(v)")
            XCTAssertGreaterThan(n.fraction, last)
            last = n.fraction
        }
    }

    func testStepButtons() {
        XCTAssertEqual(mi.value(fromKm: mi.kmh(mi.km(fromValue: 3), steps: 1)), 3.5, accuracy: 1e-9)
        XCTAssertEqual(mi.value(fromKm: mi.kmh(mi.km(fromValue: 10), steps: 1)), 10, accuracy: 1e-9)
        XCTAssertEqual(mi.value(fromKm: mi.kmh(mi.km(fromValue: 2), steps: -1)), 2, accuracy: 1e-9)
        XCTAssertEqual(km.kmh(4, steps: 1), 4.5)
        XCTAssertEqual(km.kmh(3, steps: -1), 3)
    }

    func testSwitchingUnitKeepsTheSpeed() {
        // km → miles → km comes back to the same 0.5 km/h step for every slider value
        for v in stride(from: 3.0, through: 16.0, by: 0.5) {
            let miles = mi.snapKmh(v)
            XCTAssertLessThanOrEqual(abs(miles - v), 0.25 * 1.609344 + 1e-9)
            XCTAssertLessThanOrEqual(abs(km.snapKmh(miles) - v), 0.5 + 1e-9, "v=\(v)")
        }
    }

    func testPlanAtTenMph() {
        let v = mi.km(fromValue: 10)
        let p = Plan(goal: 10_000, steps: 3_465, speed: v)
        XCTAssertEqual(p.speed, v, accuracy: 1e-9)
        XCTAssertEqual(mi.value(fromKm: p.km), 10 * Double(p.minutes) / 60, accuracy: 1e-9)
        XCTAssertEqual(Plan(goal: 10_000, steps: 0, speed: 99).speed, DistanceUnit.kmhRange.upperBound)
        XCTAssertEqual(Plan(goal: 10_000, steps: 0, speed: 1).speed, 3)
    }

    func testPreference() {
        XCTAssertEqual(UnitPreference.automatic.resolved(regionUsesMiles: true), .miles)
        XCTAssertEqual(UnitPreference.automatic.resolved(regionUsesMiles: false), .kilometers)
        XCTAssertEqual(UnitPreference.kilometers.resolved(regionUsesMiles: true), .kilometers)
        XCTAssertEqual(UnitPreference.miles.resolved(regionUsesMiles: false), .miles)
    }
}
