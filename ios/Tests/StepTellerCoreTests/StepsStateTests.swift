import XCTest
@testable import StepTellerCore

private final class FakeProvider: StepsProvider, @unchecked Sendable {
    var available = true
    var value: Int?
    var handler: (@Sendable () async -> Void)?
    var isAvailable: Bool { available }
    func requestAccess() async {}
    func steps(from startOfDay: Date, to now: Date) async -> Int? { value }
    func observe(_ onChange: @escaping @Sendable () async -> Void) async { handler = onChange }
    func stopObserving() async { handler = nil }
}

final class StepsStateTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func date(_ d: Int, _ h: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h))!
    }

    func testHealthThenManualThenUseHealth() async {
        let p = FakeProvider(); p.value = 7_200
        let c = StepsController(provider: p, calendar: cal)
        var s = StepsState()
        await c.refresh(&s, now: date(8, 21))
        XCTAssertEqual(s.steps, 7_200); XCTAssertEqual(s.origin, .health)
        s.setManual(5_000, at: date(8, 21), calendar: cal)
        XCTAssertEqual(s.steps, 5_000); XCTAssertEqual(s.origin, .manual)
        p.value = 7_500
        await c.refresh(&s, now: date(8, 22))          // con override Salute non lo cambia
        XCTAssertEqual(s.steps, 5_000)
        s.useHealth()
        XCTAssertEqual(s.steps, 7_500); XCTAssertEqual(s.origin, .health)
    }

    func testOverrideExpiresNextDay() async {
        let p = FakeProvider(); p.value = 100
        let c = StepsController(provider: p, calendar: cal)
        var s = StepsState()
        s.setManual(9_000, at: date(8, 23), calendar: cal)
        await c.refresh(&s, now: date(9, 1))
        XCTAssertNil(s.override); XCTAssertEqual(s.steps, 100); XCTAssertEqual(s.origin, .health)
    }

    func testNoDataMeansManualWithWarning() async {
        let p = FakeProvider(); p.value = nil
        let c = StepsController(provider: p, calendar: cal)
        var s = StepsState()
        await c.refresh(&s, now: date(8, 9))
        XCTAssertEqual(s.steps, 0); XCTAssertEqual(s.origin, .manual); XCTAssertTrue(s.showsNoDataWarning)
    }

    func testHealthUnavailableIsManualWithoutWarning() async {
        let p = FakeProvider(); p.available = false
        let c = StepsController(provider: p, calendar: cal)
        var s = StepsState()
        await c.refresh(&s, now: date(8, 9))
        XCTAssertEqual(s.origin, .manual); XCTAssertFalse(s.showsNoDataWarning)
    }

    func testObserverUpdate() async {
        let p = FakeProvider(); p.value = 1_000
        let c = StepsController(provider: p, calendar: cal)
        var s = StepsState()
        await c.refresh(&s, now: date(8, 20))
        await p.observe { }
        p.value = 1_400
        await c.refresh(&s, now: date(8, 20))
        XCTAssertEqual(s.steps, 1_400)
        XCTAssertNotNil(p.handler)
    }
}
