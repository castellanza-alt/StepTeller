import XCTest
@testable import StepTellerCore

final class StreakTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func day(_ d: Int, month: Int = 10) -> Date { cal.date(from: DateComponents(year: 2026, month: month, day: d))! }
    func at(_ d: Int, hour: Int = 22) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: hour))! }
    let goals = GoalHistory(initialGoal: 10_000)

    /// steps[giorno 1...] come lista; giorni oltre la lista = 0
    func run(_ list: [Int], start: Int = 1, today: Int, todaySteps: Int? = nil, initialJolly: Int = 3) -> StreakState {
        var steps: [Date: Int] = [:]
        for (i, v) in list.enumerated() { steps[day(start + i)] = v }
        if let t = todaySteps { steps[day(today)] = t }
        return StreakEngine.compute(start: day(start), initialJolly: initialJolly, steps: steps,
                                    goals: goals, now: at(today), calendar: cal)
    }

    func testRulesExampleFromWill() {
        // giorni 1–15 riusciti (matura 1 Jolly), 16 mancato (Jolly speso), 17–23 riusciti, oggi 24 in corso
        var list = Array(repeating: 11_000, count: 15)
        list.append(7_900)
        list += Array(repeating: 10_500, count: 7)
        let s = run(list, today: 24, todaySteps: 7_200)
        XCTAssertEqual(s.streak, 22)
        XCTAssertEqual(s.jolly, 3)           // 3 iniziali + 1 maturato − 1 speso
        XCTAssertEqual(s.jollyEarned, 1)
        XCTAssertEqual(s.jollyUsed, 1)
        XCTAssertEqual(s.counter, 7)         // riparte da 0 dopo il Jolly speso, poi 7 giorni
        XCTAssertEqual(s.daysToNextJolly, 8)
        XCTAssertEqual(s.statuses[day(16)], .saved)
        XCTAssertEqual(s.statuses[day(24)], .inProgress)
        XCTAssertEqual(s.longest, 22)
        XCTAssertTrue(s.todayWouldUseJolly)
        XCTAssertFalse(s.todayReached)
    }

    func testTodayReachedCountsAndMaturesJolly() {
        let s = run(Array(repeating: 10_000, count: 14), today: 15, todaySteps: 10_000)
        XCTAssertEqual(s.streak, 15)
        XCTAssertEqual(s.jolly, 4)
        XCTAssertEqual(s.counter, 0)
        XCTAssertTrue(s.todayReached)
    }

    func testMissWithoutJollyResetsStreakKeepsRecord() {
        let s = run([10_000, 10_000, 10_000, 100, 10_000], today: 6, todaySteps: 0, initialJolly: 0)
        XCTAssertEqual(s.statuses[day(4)], .missed)
        XCTAssertEqual(s.streak, 1)          // solo il giorno 5
        XCTAssertEqual(s.longest, 3)
        XCTAssertTrue(s.todayWouldUseJolly == false)
        XCTAssertTrue(s.todayWouldBreak)
    }

    func testConsecutiveMissesSpendOneJollyEach() {
        let s = run([10_000, 0, 0, 0, 0, 10_000], today: 7, todaySteps: 0)
        XCTAssertEqual(s.jollyUsed, 3)       // 3 Jolly iniziali: giorni 2, 3, 4
        XCTAssertEqual(s.statuses[day(5)], .missed)   // finiti: la streak si interrompe
        XCTAssertEqual(s.streak, 1)          // solo il giorno 6
    }

    func testNoJollySpentWhenStreakIsZero() {
        let s = run([0, 0], today: 3, todaySteps: 0)
        XCTAssertEqual(s.jolly, 3)
        XCTAssertEqual(s.streak, 0)
        XCTAssertEqual(s.statuses[day(1)], .missed)
    }

    func testGoalChangeAppliesFromTodayOnly() {
        var g = GoalHistory(initialGoal: 10_000)
        g.set(8_000, from: day(5))
        XCTAssertEqual(g.goal(on: day(4)), 10_000)
        XCTAssertEqual(g.goal(on: day(5)), 8_000)
        XCTAssertEqual(g.goal(on: day(9)), 8_000)
        var steps: [Date: Int] = [:]
        for d in 1...3 { steps[day(d)] = 10_000 }
        for d in 4...6 { steps[day(d)] = 9_000 }
        let s = StreakEngine.compute(start: day(1), steps: steps, goals: g, now: at(7), calendar: cal)
        XCTAssertEqual(s.statuses[day(4)], .saved)   // 9.000 < 10.000 col vecchio obiettivo
        XCTAssertEqual(s.statuses[day(5)], .reached) // 9.000 ≥ 8.000
    }
}

final class HistoryStatsTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func day(_ d: Int, month: Int = 10, year: Int = 2026) -> Date { cal.date(from: DateComponents(year: year, month: month, day: d))! }

    func records() -> [DayRecord] {
        // settimana 19–25 ott 2026 (oggi = sabato 24)
        let w: [(Int, Int, Double)] = [(19, 11_240, 8.8), (20, 10_480, 8.2), (21, 12_015, 9.4), (22, 10_200, 8.0),
                                       (23, 10_950, 8.5), (24, 7_200, 5.6)]
        return w.map { DayRecord(day: day($0.0), steps: $0.1, km: $0.2) }
            + [DayRecord(day: day(17, month: 6), steps: 24_318, km: 18.9)]
    }

    func testWeekSummaryMatchesMockup() {
        let st = HistoryStats(records: records(), goals: GoalHistory(), now: day(24).addingTimeInterval(80_000), calendar: cal)
        let s = st.summary(.week)
        XCTAssertEqual(s.steps, 62_085)
        XCTAssertEqual(s.elapsedDays, 6)
        XCTAssertEqual(s.daysAtGoal, 5)
        XCTAssertEqual(s.averageSteps, 10_348)
        XCTAssertEqual(st.title(.week), "19 – 25 ottobre")
        let bars = st.bars(.week)
        XCTAssertEqual(bars.count, 7)
        XCTAssertEqual(bars.map(\.label), ["L", "M", "M", "G", "V", "S", "D"])
        XCTAssertTrue(bars[5].isCurrent); XCTAssertTrue(bars[6].isFuture)
        XCTAssertTrue(bars[0].reachedGoal); XCTAssertFalse(bars[5].reachedGoal)
    }

    func testRecordsAndMonthYear() {
        let st = HistoryStats(records: records(), goals: GoalHistory(), now: day(24), calendar: cal)
        let r = st.personalRecords()
        XCTAssertEqual(r.day?.steps, 24_318)
        XCTAssertEqual(r.day?.label, "17 giu 2026")
        XCTAssertEqual(r.year?.label, "2026")
        XCTAssertEqual(st.title(.month), "Ottobre 2026")
        XCTAssertEqual(st.bars(.month).count, 31)
        XCTAssertEqual(st.bars(.year).count, 12)
        XCTAssertEqual(st.summary(.month).steps, 62_085)
    }

    func testPreviousWeekAndMaxOffset() {
        let st = HistoryStats(records: records(), goals: GoalHistory(), now: day(24), calendar: cal)
        XCTAssertEqual(st.title(.week, offset: 1), "12 – 18 ottobre")
        XCTAssertEqual(st.maxOffset(.week), 18)   // dalla settimana del 17 giugno
    }
}
