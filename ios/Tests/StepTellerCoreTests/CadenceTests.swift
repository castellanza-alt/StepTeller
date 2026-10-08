import XCTest
@testable import StepTellerCore

final class CadenceTests: XCTestCase {
    let model = CadenceModel.standard

    func testGoldenCadence() {
        let golden: [(Double, Gait, Double)] = [
            (3.0, .walk, 90.0), (5.0, .walk, 110.0), (6.0, .walk, 119.0), (7.0, .walk, 129.0),
            (7.1, .run, 150.0441), (8.0, .run, 152.6360), (8.3, .run, 153.5),
            (10.0, .run, 158.3959), (12.0, .run, 163.1957),
        ]
        for (v, gait, cad) in golden {
            XCTAssertEqual(model.gait(at: v), gait, "andatura a \(v)")
            XCTAssertEqual(model.cadence(at: v), cad, accuracy: 0.001, "cadenza a \(v)")
        }
    }

    func testGoldenPlans() {
        let cases: [(Int, Int, Double, Int, Double)] = [
            (10_000, 7_200, 6.0, 24, 2.40), (10_000, 7_200, 8.3, 19, 2.63),
            (10_000, 0, 10.0, 64, 10.67), (10_000, 3_000, 5.0, 64, 5.33),
        ]
        for (goal, steps, v, min, km) in cases {
            let p = Plan(goal: goal, steps: steps, speed: v)
            XCTAssertEqual(p.minutes, min, "minuti a \(v)")
            XCTAssertEqual(p.km, km, accuracy: 0.005, "km a \(v)")
        }
    }

    func testMonotonicWithinGait() {
        var prev: [Gait: Double] = [:]
        var v = 3.0
        while v <= 12.0 + 1e-9 {
            let g = model.gait(at: v)
            let c = model.cadence(at: v)
            if let p = prev[g] { XCTAssertGreaterThanOrEqual(c, p - 1e-9, "a \(v)") }
            prev[g] = c
            v = (v * 10).rounded() / 10 + 0.1
        }
    }

    func testGaitJump() {
        XCTAssertEqual(model.cadence(at: 7.0), 129, accuracy: 0.001)
        XCTAssertEqual(model.cadence(at: 7.1), 150.0441, accuracy: 0.001)
    }

    func testDoneState() {
        let p = Plan(goal: 10_000, steps: 10_000, speed: 6)
        XCTAssertTrue(p.isDone)
        XCTAssertEqual(p.minutes, 0)
        let q = Plan(goal: 10_000, steps: 12_345, speed: 6)
        XCTAssertTrue(q.isDone)
        XCTAssertEqual(q.remaining, 0)
    }

    func testZeroGoal() {
        let p = Plan(goal: 0, steps: 0, speed: 6)
        XCTAssertTrue(p.isDone)
        XCTAssertEqual(p.km, 0)
    }

    func testCalibrationZeroOneTwoPoints() {
        let none = CadenceModel(walkCalibration: [], runCalibration: [])
        XCTAssertEqual(none.cadence(at: 8.0), 159, accuracy: 0.001)
        let one = CadenceModel(walkCalibration: [], runCalibration: [CalibrationPoint(speed: 8, cadence: 150)])
        let r1 = 150.0 / 159.0
        XCTAssertEqual(one.cadence(at: 8.0), 150, accuracy: 0.001)
        XCTAssertEqual(one.cadence(at: 12.0), 170 * r1, accuracy: 0.001)   // costante
        XCTAssertEqual(one.cadence(at: 7.5), 157.5 * r1, accuracy: 0.001)
        let two = CadenceModel(walkCalibration: [], runCalibration: [
            CalibrationPoint(speed: 8, cadence: 159 * 1.0), CalibrationPoint(speed: 10, cadence: 165 * 1.1)])
        XCTAssertEqual(two.cadence(at: 9.0), 162 * 1.05, accuracy: 0.001)   // interpolato
        XCTAssertEqual(two.cadence(at: 7.2), two.cadence(at: 7.2), accuracy: 0)
        XCTAssertEqual(two.cadence(at: 7.5), 157.5 * 1.0, accuracy: 0.001)  // costante sotto
        XCTAssertEqual(two.cadence(at: 12.0), 170 * 1.1, accuracy: 0.001)   // costante sopra
    }

    func testItalianFormat() {
        XCTAssertEqual(ItalianFormat.number(10_000), "10.000")
        XCTAssertEqual(ItalianFormat.number(8.3, decimals: 1), "8,3")
        XCTAssertEqual(ItalianFormat.number(67.5, decimals: 1), "67,5")
        XCTAssertEqual(ItalianFormat.number(6, decimals: 1), "6,0")
        XCTAssertEqual(ItalianFormat.number(1_234_567), "1.234.567")
        XCTAssertEqual(ItalianFormat.number(0), "0")
        XCTAssertEqual(ItalianFormat.digits("7.200"), 7200)
        XCTAssertEqual(ItalianFormat.digits(""), 0)
    }

    func testGlancePlanAtFourKmh() {
        // widget: camminata a 4 km/h (101 passi/min), 7.200 su 10.000 → 28 min
        let p = Plan(goal: 10_000, steps: 7_200, speed: Plan.glanceSpeed, model: CalibrationResult.empty.model)
        XCTAssertEqual(p.minutes, 28)
        XCTAssertEqual(p.progress, 0.72, accuracy: 1e-9)
        XCTAssertEqual(Plan(goal: 0, steps: 0, speed: 4).progress, 1)
        XCTAssertEqual(Plan(goal: 10_000, steps: 12_000, speed: 4).progress, 1)
    }
}
