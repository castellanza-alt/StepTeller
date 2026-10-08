import XCTest
@testable import StepTellerCore

final class ReminderTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h, minute: m))! }

    func testPreciseTextTodayGenericAfter() {
        let plan = Plan(goal: 10_000, steps: 7_200, speed: 8.3)
        let r = ReminderPlanner.schedule(now: date(8, 18), minutesFromMidnight: 20 * 60 + 30, plan: plan, calendar: cal)
        XCTAssertEqual(r.count, 7)
        XCTAssertEqual(r[0].id, "stepteller.reminder.2026-10-08")
        XCTAssertEqual(r[0].content.body, "Ti servono 19 min a 8,3 km/h per chiudere i 10.000 passi (mancano 2.800).")
        XCTAssertEqual(r[0].fire.hour, 20); XCTAssertEqual(r[0].fire.minute, 30)
        XCTAssertEqual(r[1].content, ReminderPlanner.genericContent())
    }

    func testTodaySkippedWhenGoalDoneOrTimePassed() {
        let done = Plan(goal: 10_000, steps: 10_500, speed: 6)
        XCTAssertEqual(ReminderPlanner.schedule(now: date(8, 18), minutesFromMidnight: 1230, plan: done, calendar: cal).count, 6)
        let open = Plan(goal: 10_000, steps: 100, speed: 6)
        let late = ReminderPlanner.schedule(now: date(8, 21), minutesFromMidnight: 1230, plan: open, calendar: cal)
        XCTAssertEqual(late.count, 6)
        XCTAssertEqual(late[0].id, "stepteller.reminder.2026-10-09")
    }
}
