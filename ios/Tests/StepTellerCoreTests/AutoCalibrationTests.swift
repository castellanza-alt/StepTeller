import XCTest
@testable import StepTellerCore

final class AutoCalibrationTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_791_000_000)

    func sample(daysAgo: Double = 5, km: Double, minutes: Double, cadence: Double) -> WorkoutSample {
        WorkoutSample(date: now.addingTimeInterval(-daysAgo * 86_400), distanceKm: km,
                      durationMinutes: minutes, steps: Int((cadence * minutes).rounded()))
    }

    func testTwoRunsGiveOnePointAndMatchManualExample() {
        // 13 e 15 settembre 2026: 8,28 km/h · 154,8 spm e 8,31 km/h · 152,2 spm
        let r = AutoCalibration.compute(from: [
            sample(km: 8.28 * 0.5, minutes: 30, cadence: 154.8),
            sample(km: 8.31 * 0.5, minutes: 30, cadence: 152.2),
        ], now: now)
        XCTAssertEqual(r.runWorkouts, 2)
        XCTAssertEqual(r.run.count, 1)
        XCTAssertEqual(r.run[0].speed, 8.295, accuracy: 0.01)
        XCTAssertEqual(r.run[0].cadence, 153.5, accuracy: 0.01)
        XCTAssertTrue(r.walk.isEmpty)
    }

    func testSingleWorkoutIsNotEnough() {
        let r = AutoCalibration.compute(from: [sample(km: 4, minutes: 30, cadence: 150)], now: now)
        XCTAssertEqual(r, .empty)
    }

    func testOldAndShortWorkoutsAreIgnored() {
        let r = AutoCalibration.compute(from: [
            sample(daysAgo: 120, km: 4, minutes: 30, cadence: 154), sample(daysAgo: 100, km: 4, minutes: 30, cadence: 154),
            sample(km: 1.3, minutes: 8, cadence: 154), sample(km: 1.3, minutes: 8, cadence: 154),
        ], now: now)
        XCTAssertEqual(r, .empty)
    }

    func testOutlierIsDiscarded() {
        let r = AutoCalibration.compute(from: [
            sample(km: 4.15, minutes: 30, cadence: 153), sample(km: 4.15, minutes: 30, cadence: 155),
            sample(km: 4.15, minutes: 30, cadence: 154), sample(km: 4.15, minutes: 30, cadence: 100),
        ], now: now)
        XCTAssertEqual(r.runWorkouts, 3)
        XCTAssertEqual(r.run[0].cadence, 154, accuracy: 0.01)
    }

    func testTwoBucketsGiveTwoPointsAndWalkSeparate() {
        let runs = [8.0, 8.0, 10.0, 10.0].map { v in sample(km: v / 2, minutes: 30, cadence: 160) }
        let walks = [5.0, 5.0].map { v in sample(km: v / 2, minutes: 30, cadence: 112) }
        let r = AutoCalibration.compute(from: runs + walks, now: now)
        XCTAssertEqual(r.run.count, 2)
        XCTAssertEqual(r.run.map(\.speed), [8.0, 10.0])
        XCTAssertEqual(r.walk.count, 1)
        XCTAssertEqual(r.walk[0].cadence, 112, accuracy: 0.01)
        let model = CadenceModel(walkCalibration: r.walkPoints, runCalibration: r.runPoints)
        XCTAssertEqual(model.cadence(at: 5.0), 112, accuracy: 0.01)
    }
}
