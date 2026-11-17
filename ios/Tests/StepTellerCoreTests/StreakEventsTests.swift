import XCTest
@testable import StepTellerCore

/// Notifications and pop-ups of goal and Jollies (D-038): every event told once, never lost, never repeated.
final class StreakEventsTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func day(_ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: d))! }
    func at(_ d: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: hour, minute: minute))!
    }
    let goals = GoalHistory(initialGoal: 10_000)

    /// Days from `start` with the given steps; `now` decides «today».
    func state(_ list: [Int], start: Int = 1, now: Date, calendar: Calendar? = nil, initialJolly: Int = 3) -> StreakState {
        let c = calendar ?? cal
        var steps: [Date: Int] = [:]
        let first = c.date(from: DateComponents(year: 2026, month: 11, day: start))!
        for (i, v) in list.enumerated() { steps[c.date(byAdding: .day, value: i, to: first)!] = v }
        return StreakEngine.compute(start: first, initialJolly: initialJolly, steps: steps, goals: goals, now: now, calendar: c)
    }

    func ids(_ events: [StreakEvent]) -> [String] { events.map(\.id) }

    // MARK: events

    func testGoalReachedToday() {
        let s = state([10_000, 10_000, 12_000], now: at(3, 18))
        XCTAssertEqual(ids(StreakEvents.events(in: s, now: at(3, 18), calendar: cal)), ["goal.2026-11-03"])
    }

    func testTodayInProgressHasNoGoalEvent() {
        let s = state([10_000, 10_000, 3_000], now: at(3, 18))
        XCTAssertTrue(StreakEvents.events(in: s, now: at(3, 18), calendar: cal).isEmpty)
    }

    func testJollyEarnedOnThe15thDay() {
        let s = state(Array(repeating: 10_000, count: 15), now: at(15, 19))
        let e = StreakEvents.events(in: s, now: at(15, 19), calendar: cal)
        XCTAssertEqual(ids(e), ["earned.2026-11-15", "goal.2026-11-15"])
        XCTAssertEqual(e.first?.jolly, 4)
        XCTAssertEqual(e.first?.streak, 15)
    }

    func testWouldEarnJollyFlagBeforeThe15thDay() {
        XCTAssertTrue(state(Array(repeating: 10_000, count: 14) + [500], now: at(15, 12)).todayWouldEarnJolly)
        XCTAssertFalse(state(Array(repeating: 10_000, count: 13) + [500], now: at(14, 12)).todayWouldEarnJolly)
    }

    func testJollyUsedIsYesterdayMorningAfter() {
        let s = state([10_000, 10_000, 2_000, 800], now: at(4, 9))
        let e = StreakEvents.events(in: s, now: at(4, 9), calendar: cal)
        XCTAssertEqual(ids(e), ["used.2026-11-03"])
        XCTAssertEqual(e.first?.jolly, 2)
    }

    func testTwoJolliesTheSameMorningAreTwoEventsAndOnePopup() {
        // closed for two days, two Jollies spent: both notified once, one pop-up «used» counting 2
        let s = state([10_000, 10_000, 0, 0, 0], now: at(5, 9))
        var ledger = EventLedger(since: "2026-11-01")
        let events = StreakEvents.events(in: s, now: at(5, 9), calendar: cal)
        XCTAssertEqual(ids(events), ["used.2026-11-03", "used.2026-11-04"])
        // notifications: yesterday only (the one of the day before is old news)
        let notify = StreakEvents.toNotify(events, ledger: ledger, now: at(5, 9), calendar: cal)
        XCTAssertEqual(ids(notify), ["used.2026-11-04"])
        let show = StreakEvents.toShow(events, ledger: ledger, now: at(5, 9), calendar: cal)
        let popups = StreakEvents.popups(show)
        XCTAssertEqual(popups.count, 1)
        XCTAssertEqual(popups.first?.count, 2)
        XCTAssertEqual(popups.first?.event.day, "2026-11-04")
        ledger.notified.formUnion(ids(notify))
        ledger.shown.formUnion(ids(show))
        XCTAssertTrue(StreakEvents.toNotify(events, ledger: ledger, now: at(5, 10), calendar: cal).isEmpty)
        XCTAssertTrue(StreakEvents.toShow(events, ledger: ledger, now: at(5, 10), calendar: cal).isEmpty)
    }

    // MARK: once

    func testNotifiedOnceAcrossLaunches() {
        let s = state([10_000, 10_000, 12_000], now: at(3, 18))
        var ledger = EventLedger()
        StreakEvents.start(&ledger, now: at(3, 18), calendar: cal)
        let first = StreakEvents.toNotify(StreakEvents.events(in: s, now: at(3, 18), calendar: cal), ledger: ledger, now: at(3, 18), calendar: cal)
        XCTAssertEqual(ids(first), ["goal.2026-11-03"])
        ledger.notified.formUnion(ids(first))
        let later = state([10_000, 10_000, 15_000], now: at(3, 21))
        XCTAssertTrue(StreakEvents.toNotify(StreakEvents.events(in: later, now: at(3, 21), calendar: cal),
                                            ledger: ledger, now: at(3, 21), calendar: cal).isEmpty)
    }

    func testGoalOfYesterdayIsNeverNotifiedToday() {
        let events = [StreakEvent(kind: .goalReached, day: "2026-11-02", streak: 2, jolly: 3)]
        XCTAssertTrue(StreakEvents.toNotify(events, ledger: EventLedger(since: "2026-11-01"), now: at(3, 9), calendar: cal).isEmpty)
    }

    func testWidgetAndAppTogetherMergeWithoutRepeats() {
        // both processes read the same ledger, both notice the goal; the second write merges the first
        let base = EventLedger(since: "2026-11-01")
        var app = base, widget = base
        app.notified.insert("goal.2026-11-03")
        widget.notified.insert("goal.2026-11-03")
        widget.notified.insert("earned.2026-11-03")
        let stored = widget.merged(with: app)
        XCTAssertEqual(stored.notified, ["goal.2026-11-03", "earned.2026-11-03"])
        XCTAssertEqual(app.merged(with: widget), stored)
        let s = state(Array(repeating: 10_000, count: 3), now: at(3, 18))
        XCTAssertTrue(StreakEvents.toNotify(StreakEvents.events(in: s, now: at(3, 18), calendar: cal),
                                            ledger: stored, now: at(3, 18), calendar: cal).isEmpty)
    }

    func testMergeKeepsTheEarliestStart() {
        XCTAssertEqual(EventLedger(since: "2026-11-05").merged(with: EventLedger(since: "2026-11-02")).since, "2026-11-02")
        XCTAssertEqual(EventLedger().merged(with: EventLedger(since: "2026-11-02")).since, "2026-11-02")
    }

    func testTimeZoneChangeDoesNotRepeat() {
        // Jolly spent on 3 November seen in Rome, then the phone moves to New York: same day key, nothing new
        let rome = cal
        var ny = Calendar(identifier: .gregorian); ny.timeZone = TimeZone(identifier: "America/New_York")!
        let list = [10_000, 10_000, 500, 3_000]
        let nowRome = at(4, 20)
        var ledger = EventLedger(since: "2026-11-01")
        let seen = StreakEvents.toNotify(StreakEvents.events(in: state(list, now: nowRome), now: nowRome, calendar: rome),
                                         ledger: ledger, now: nowRome, calendar: rome)
        XCTAssertEqual(ids(seen), ["used.2026-11-03"])
        ledger.notified.formUnion(ids(seen))
        let nowNY = nowRome.addingTimeInterval(3 * 3600)          // 4 November, 17:00 in New York
        let again = StreakEvents.events(in: state(list, now: nowNY, calendar: ny), now: nowNY, calendar: ny)
        XCTAssertEqual(ids(again), ["used.2026-11-03"])
        XCTAssertTrue(StreakEvents.toNotify(again, ledger: ledger, now: nowNY, calendar: ny).isEmpty)
    }

    func testReinstallDoesNotTellThePast() {
        // fresh ledger today; iCloud then brings back the old streak start: older events are not news
        var ledger = EventLedger()
        StreakEvents.start(&ledger, now: at(10, 9), calendar: cal)
        XCTAssertEqual(ledger.since, "2026-11-10")
        let s = state(Array(repeating: 10_000, count: 6) + [0] + Array(repeating: 10_000, count: 2), now: at(10, 9))
        let events = StreakEvents.events(in: s, now: at(10, 9), calendar: cal)
        XCTAssertEqual(ids(events), ["used.2026-11-07"])
        XCTAssertTrue(StreakEvents.toNotify(events, ledger: ledger, now: at(10, 9), calendar: cal).isEmpty)
        XCTAssertTrue(StreakEvents.toShow(events, ledger: ledger, now: at(10, 9), calendar: cal).isEmpty)
        // a second start does not move the date
        StreakEvents.start(&ledger, now: at(12, 9), calendar: cal)
        XCTAssertEqual(ledger.since, "2026-11-10")
    }

    func testPopupWindowIsOneWeek() {
        let events = [StreakEvent(kind: .jollyUsed, day: "2026-11-02", streak: 5, jolly: 1),
                      StreakEvent(kind: .jollyEarned, day: "2026-11-08", streak: 15, jolly: 2)]
        let shown = StreakEvents.toShow(events, ledger: EventLedger(since: "2026-10-01"), now: at(10, 9), calendar: cal)
        XCTAssertEqual(ids(shown), ["earned.2026-11-08"])
    }

    func testGoalHasNoPopup() {
        let events = [StreakEvent(kind: .goalReached, day: "2026-11-10", streak: 5, jolly: 1)]
        XCTAssertTrue(StreakEvents.toShow(events, ledger: EventLedger(since: "2026-11-01"), now: at(10, 19), calendar: cal).isEmpty)
    }

    func testPruneKeepsRecentOnly() {
        var ledger = EventLedger(since: "2026-09-01")
        ledger.notified = ["goal.2026-09-30", "used.2026-11-02"]
        ledger.shown = ["used.2026-09-30", "used.2026-11-02"]
        ledger.prune(before: "2026-10-15")
        XCTAssertEqual(ledger.notified, ["used.2026-11-02"])
        XCTAssertEqual(ledger.shown, ["used.2026-11-02"])
        XCTAssertEqual(EventLedger.decoded(ledger.encoded()), ledger)
    }

    // MARK: night

    func testNight() {
        XCTAssertTrue(StreakEvents.isNight(at(3, 23), calendar: cal))
        XCTAssertTrue(StreakEvents.isNight(at(3, 7, 59), calendar: cal))
        XCTAssertFalse(StreakEvents.isNight(at(3, 8), calendar: cal))
        XCTAssertFalse(StreakEvents.isNight(at(3, 21, 59), calendar: cal))
    }

    func testJollyAtNightMovesTo8() {
        XCTAssertNil(StreakEvents.morningDelivery(after: at(3, 12), calendar: cal))
        XCTAssertEqual(StreakEvents.morningDelivery(after: at(3, 0, 10), calendar: cal),
                       DateComponents(year: 2026, month: 11, day: 3, hour: 8, minute: 0))
        XCTAssertEqual(StreakEvents.morningDelivery(after: at(3, 23, 30), calendar: cal),
                       DateComponents(year: 2026, month: 11, day: 4, hour: 8, minute: 0))
    }

    func testDayKeyIsGregorianWhateverThePhoneCalendar() {
        var japanese = Calendar(identifier: .japanese); japanese.timeZone = cal.timeZone
        var buddhist = Calendar(identifier: .buddhist); buddhist.timeZone = cal.timeZone
        XCTAssertEqual(DayKey.of(at(3, 12), calendar: japanese), "2026-11-03")
        XCTAssertEqual(DayKey.of(at(3, 12), calendar: buddhist), "2026-11-03")
    }

    func testDayKeyAcrossZones() {
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let instant = at(3, 23, 30)                     // 3 Nov 23:30 in Rome = 4 Nov 07:30 in Tokyo
        XCTAssertEqual(DayKey.of(instant, calendar: cal), "2026-11-03")
        XCTAssertEqual(DayKey.of(instant, calendar: tokyo), "2026-11-04")
        XCTAssertEqual(DayKey.of(instant, minusDays: 1, calendar: cal), "2026-11-02")
    }
}
