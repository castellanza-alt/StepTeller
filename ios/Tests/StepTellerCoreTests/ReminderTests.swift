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

    func testStreakWarningsInText() {
        let plan = Plan(goal: 10_000, steps: 7_200, speed: 6)
        var st = StreakState(); st.streak = 22; st.jolly = 3; st.todayWouldUseJolly = true
        XCTAssertTrue(ReminderPlanner.content(for: plan, streak: st)!.body.hasSuffix("stasera usi un Jolly (ne restano 2)."))
        st.todayWouldUseJolly = false; st.jolly = 0; st.todayWouldBreak = true
        XCTAssertTrue(ReminderPlanner.content(for: plan, streak: st)!.body.hasSuffix("la streak di 22 giorni si interrompe."))
    }

    /// The core gives case and numbers: the app composes the text in the phone's language.
    func testMessageCarriesNumbers() {
        let plan = Plan(goal: 10_000, steps: 7_200, speed: 8.3)
        var st = StreakState(); st.streak = 22; st.jolly = 3; st.todayWouldUseJolly = true
        XCTAssertEqual(ReminderPlanner.message(for: plan, streak: st),
                       .precise(minutes: 19, speed: 8.3, goal: 10_000, remaining: 2_800, warning: .wouldUseJolly(jollyLeft: 2)))
        st.todayWouldUseJolly = false; st.jolly = 0; st.todayWouldBreak = true
        XCTAssertEqual(ReminderPlanner.message(for: plan, streak: st)?.italian.body,
                       "Ti servono 19 min a 8,3 km/h per chiudere i 10.000 passi (mancano 2.800). Senza Jolly, la streak di 22 giorni si interrompe.")
        XCTAssertNil(ReminderPlanner.message(for: Plan(goal: 10_000, steps: 10_500, speed: 6)))
    }

    func testIdentifierAndNextFire() {
        let r = ReminderPlanner.schedule(now: date(8, 18), minutesFromMidnight: 20 * 60 + 30,
                                         plan: Plan(goal: 10_000, steps: 4_000, speed: 4), calendar: cal)
        XCTAssertEqual(r[0].id, ReminderPlanner.identifier(for: date(8, 18), calendar: cal))
        XCTAssertEqual(r[0].id, "stepteller.reminder.2026-10-08")
        // 18:00 → tonight at 20:30; 21:00 → tomorrow at 20:30
        XCTAssertEqual(ReminderPlanner.nextFire(now: date(8, 18), minutesFromMidnight: 1230, calendar: cal), date(8, 20, 30))
        XCTAssertEqual(ReminderPlanner.nextFire(now: date(8, 21), minutesFromMidnight: 1230, calendar: cal), date(9, 20, 30))
    }

    func testWarningFromStreak() {
        var st = StreakState()
        st.streak = 22; st.jolly = 0; st.todayWouldBreak = true
        XCTAssertEqual(ReminderPlanner.warning(for: st), .wouldBreak(streak: 22))
        let plan = Plan(goal: 10_000, steps: 9_000, speed: 4)
        XCTAssertEqual(ReminderPlanner.message(for: plan, warning: nil),
                       .precise(minutes: plan.minutes, speed: 4, goal: 10_000, remaining: 1_000, warning: nil))
    }
}
