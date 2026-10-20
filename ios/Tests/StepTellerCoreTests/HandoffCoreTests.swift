import XCTest
@testable import StepTellerCore

/// Core of the «Dan Dan Dan» redesign: slider path, daily averages, dates of the longest streak.
final class SpeedTrackTests: XCTestCase {
    let track = SpeedTrack.road

    func testEndsMatchHandoffPath() {
        XCTAssertEqual(track.point(atFraction: 0), SpeedTrack.Point(50, 1697))
        let end = track.point(atFraction: 1)
        XCTAssertEqual(end.x, 600, accuracy: 0.001)
        XCTAssertEqual(end.y, 1380, accuracy: 0.001)
        XCTAssertEqual(track.totalLength, 883.8, accuracy: 1)   // the prototype's getTotalLength()
    }

    func testSpeedMapping() {
        XCTAssertEqual(SpeedTrack.speed(forFraction: 0), 3)
        XCTAssertEqual(SpeedTrack.speed(forFraction: 1), 16)
        XCTAssertEqual(SpeedTrack.speed(forFraction: 0.5), 9.5)
        XCTAssertEqual(SpeedTrack.fraction(forSpeed: 4), 1.0 / 13, accuracy: 1e-9)
        XCTAssertEqual(SpeedTrack.snap(8.3), 8.5)
        XCTAssertEqual(SpeedTrack.snap(6.2), 6.0)
        XCTAssertEqual(SpeedTrack.snap(20), 16)
        XCTAssertEqual(SpeedTrack.snap(1), 3)
    }

    func testProjectionRoundTrip() {
        for v in stride(from: 3.0, through: 16.0, by: 0.5) {
            let p = track.point(atFraction: SpeedTrack.fraction(forSpeed: v))
            let n = track.nearest(to: p)
            XCTAssertLessThan(n.distance, 0.5)
            XCTAssertEqual(SpeedTrack.speed(forFraction: n.fraction), v, "v=\(v)")
        }
    }

    func testProjectionOfPointOffTheRoad() {
        // 30 px below the start of the road: projects near the start, about 30 px away
        let n = track.nearest(to: SpeedTrack.Point(60, 1727))
        XCTAssertLessThan(n.fraction, 0.05)
        XCTAssertEqual(n.distance, 30, accuracy: 6)
        // far away (top left): large distance, the view rejects it
        XCTAssertGreaterThan(track.nearest(to: SpeedTrack.Point(100, 300)).distance, 1000)
    }

    func testPositionGrowsWithSpeedAlongTheArc() {
        var last = -1.0
        for v in stride(from: 3.0, through: 16.0, by: 0.5) {
            let f = track.nearest(to: track.point(atFraction: SpeedTrack.fraction(forSpeed: v))).fraction
            XCTAssertGreaterThan(f, last)
            last = f
        }
    }

    func testPlanAcceptsSixteen() {
        let p = Plan(goal: 10_000, steps: 3_465, speed: 16)
        XCTAssertEqual(p.speed, 16)
        XCTAssertGreaterThan(p.minutes, 0)
    }
}

final class HistoryAverageTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func day(_ d: Int, month: Int = 10, year: Int = 2026) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: d))!
    }

    func records() -> [DayRecord] {
        let w: [(Int, Int)] = [(19, 11_240), (20, 10_480), (21, 12_015), (22, 10_200), (23, 10_950), (24, 7_200)]
        return w.map { DayRecord(day: day($0.0), steps: $0.1, km: 0) }
            + [DayRecord(day: day(17, month: 6), steps: 24_318, km: 0)]
    }

    func stats() -> HistoryStats {
        HistoryStats(records: records(), goals: GoalHistory(), now: day(24).addingTimeInterval(50_000), calendar: cal)
    }

    func testAveragesExcludeToday() {
        let st = stats()
        XCTAssertEqual(st.dailyAverage(.week).steps, 10_977)    // 19–23 October, today (24) excluded
        XCTAssertEqual(st.dailyAverage(.month).steps, 2_386)    // 1–23 October, days without data = 0
        XCTAssertEqual(st.dailyAverage(.all).steps, 614)        // from 17 June (first data) to 23 October
    }

    func testYearAndAllBarsAreDailyAverages() {
        let st = stats()
        let year = st.averageBars(.year)
        XCTAssertEqual(year.count, 12)
        XCTAssertEqual(year[5].steps, 1_737)                    // June: 17th to 30th, 14 days
        XCTAssertEqual(year[9].steps, 2_386)                    // October
        XCTAssertTrue(year[9].isCurrent)
        XCTAssertEqual(year[0].steps, 0)                        // before the data
        let all = st.averageBars(.all)
        XCTAssertEqual(all.map(\.label), ["26"])
        XCTAssertEqual(all[0].steps, 614)
        XCTAssertEqual(st.title(.all), "2026")
        // week and month keep the day's steps
        XCTAssertEqual(st.averageBars(.week).map(\.steps), st.bars(.week).map(\.steps))
    }

    func testOnlyTodayInPeriod() {
        let st = HistoryStats(records: [DayRecord(day: day(24), steps: 4_000, km: 0)], goals: GoalHistory(),
                              now: day(24).addingTimeInterval(50_000), calendar: cal)
        XCTAssertEqual(st.dailyAverage(.week).steps, 4_000)
        XCTAssertEqual(st.dailyAverage(.week, offset: 1).steps, 0)
    }

    func testAllTitleSpansYears() {
        let st = HistoryStats(records: records() + [DayRecord(day: day(3, month: 2, year: 2020), steps: 5_000, km: 0)],
                              goals: GoalHistory(), now: day(24), calendar: cal)
        XCTAssertEqual(st.title(.all), "2020 – 2026")
        XCTAssertEqual(st.averageBars(.all).map(\.label), ["20", "21", "22", "23", "24", "25", "26"])
    }

    func testRangeLabels() {
        let st = stats()
        XCTAssertEqual(st.rangeLabel(from: day(3), to: day(17)), "3 – 17 ott 2026")
        XCTAssertEqual(st.rangeLabel(from: day(4, month: 6, year: 2024), to: day(30, month: 9, year: 2024)), "giu – set 2024")
        XCTAssertEqual(st.rangeLabel(from: day(20, month: 12, year: 2025), to: day(2, month: 2)), "dic 2025 – feb 2026")
        XCTAssertEqual(st.rangeLabel(from: day(5), to: day(5)), "5 ott 2026")
    }

    func testLongestStreakRange() {
        var steps: [Date: Int] = [:]
        for d in 1...5 { steps[day(d)] = 11_000 }     // streak of 5
        steps[day(6)] = 0                             // Jolly spent: the streak stays 5
        for d in 7...9 { steps[day(d)] = 11_000 }     // 8
        let s = StreakEngine.compute(start: day(1), initialJolly: 1, steps: steps, goals: GoalHistory(),
                                     now: day(12), calendar: cal)
        // the 10th missed without a Jolly: reset; today (12) in progress
        XCTAssertEqual(s.longest, 8)
        XCTAssertEqual(s.longestStart, day(1))
        XCTAssertEqual(s.longestEnd, day(9))
        XCTAssertEqual(s.streak, 0)
    }
}
