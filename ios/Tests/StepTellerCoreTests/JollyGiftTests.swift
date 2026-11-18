import XCTest
@testable import StepTellerCore

/// Christmas Jolly gift (D-040, T-016): window, once per season, every year, saved copies, and how
/// `StreakEngine` counts it.
final class JollyGiftTests: XCTestCase {
    func calendar(_ zone: String = "Europe/Rome") -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }
    lazy var cal = calendar()
    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10, _ min: Int = 0, cal c: Calendar? = nil) -> Date {
        (c ?? cal).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
    func day(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.startOfDay(for: date(y, m, d)) }
    let goals = GoalHistory(initialGoal: 10_000)

    // MARK: window

    func testWindowFromChristmasToEpiphany() {
        XCTAssertNil(JollyGift.season(of: date(2026, 12, 1), calendar: cal))           // season of the theme, no gift
        XCTAssertNil(JollyGift.season(of: date(2026, 12, 24, 23, 59), calendar: cal))  // Christmas Eve, a minute early
        XCTAssertEqual(JollyGift.season(of: date(2026, 12, 25, 0, 0), calendar: cal), 2026)
        XCTAssertEqual(JollyGift.season(of: date(2026, 12, 31, 23, 59), calendar: cal), 2026)
        XCTAssertEqual(JollyGift.season(of: date(2027, 1, 6, 23, 59), calendar: cal), 2026)  // Epiphany included
        XCTAssertNil(JollyGift.season(of: date(2027, 1, 7, 0, 0), calendar: cal))
    }

    func testClaimBeforeAndAfterChristmasEve() {
        var ledger = JollyGift.Ledger()
        XCTAssertFalse(JollyGift.claim(&ledger, now: date(2026, 12, 24, 23, 59), calendar: cal))
        XCTAssertTrue(ledger.days.isEmpty)
        XCTAssertTrue(JollyGift.claim(&ledger, now: date(2026, 12, 25, 0, 1), calendar: cal))
        XCTAssertEqual(ledger.days, ["2026": "2026-12-25"])
    }

    func testFirstOpeningLateStillGetsIt() {
        var ledger = JollyGift.Ledger()
        XCTAssertTrue(JollyGift.claim(&ledger, now: date(2027, 1, 3), calendar: cal))   // opens on 3 January
        XCTAssertEqual(ledger.days, ["2026": "2027-01-03"])
    }

    func testSixthYesSeventhNo() {
        var a = JollyGift.Ledger(), b = JollyGift.Ledger()
        XCTAssertTrue(JollyGift.claim(&a, now: date(2027, 1, 6, 22), calendar: cal))
        XCTAssertFalse(JollyGift.claim(&b, now: date(2027, 1, 7, 8), calendar: cal))
    }

    func testTwoOpeningsOneGift() {
        var ledger = JollyGift.Ledger()
        XCTAssertTrue(JollyGift.claim(&ledger, now: date(2026, 12, 25, 9), calendar: cal))
        XCTAssertFalse(JollyGift.claim(&ledger, now: date(2026, 12, 25, 18), calendar: cal))
        XCTAssertFalse(JollyGift.claim(&ledger, now: date(2027, 1, 2), calendar: cal))
        XCTAssertEqual(ledger.days.count, 1)
    }

    func testEveryYear() {
        var ledger = JollyGift.Ledger()
        XCTAssertTrue(JollyGift.claim(&ledger, now: date(2026, 12, 25), calendar: cal))
        XCTAssertTrue(JollyGift.claim(&ledger, now: date(2027, 12, 26), calendar: cal))
        XCTAssertEqual(ledger.days, ["2026": "2026-12-25", "2027": "2027-12-26"])
    }

    func testLocalTimeAndTimeZoneChange() {
        // 24/12 23:30 in Rome is already 25/12 07:30 in Tokyo: local time decides
        let instant = date(2026, 12, 24, 23, 30)
        var rome = JollyGift.Ledger(), tokyo = JollyGift.Ledger()
        XCTAssertFalse(JollyGift.claim(&rome, now: instant, calendar: calendar("Europe/Rome")))
        XCTAssertTrue(JollyGift.claim(&tokyo, now: instant, calendar: calendar("Asia/Tokyo")))
        XCTAssertEqual(tokyo.days, ["2026": "2026-12-25"])
        // back in Rome the same evening: still the same season, no second gift
        XCTAssertFalse(JollyGift.claim(&tokyo, now: instant.addingTimeInterval(3600), calendar: calendar("Europe/Rome")))
        // the day key stays the same day in any zone
        let inNewYork = JollyGift.days(tokyo, calendar: calendar("America/New_York"))
        XCTAssertEqual(inNewYork.map { DayKey.of($0, calendar: calendar("America/New_York")) }, ["2026-12-25"])
    }

    // MARK: saved copies (App Group, iCloud, Backup)

    func testReinstallWithICloudDoesNotRepeat() {
        // reinstall: this phone is empty, iCloud brings back the season already received
        let cloud = JollyGift.Ledger(days: ["2026": "2026-12-25"])
        var here = JollyGift.Ledger().merged(with: cloud)
        XCTAssertFalse(JollyGift.claim(&here, now: date(2026, 12, 28), calendar: cal))
    }

    func testReinstallWithoutICloudGivesItAgainButCountsOnce() {
        // no iCloud: nothing remembers the gift, and the streak count starts again today with it
        var here = JollyGift.Ledger()
        XCTAssertTrue(JollyGift.claim(&here, now: date(2026, 12, 28), calendar: cal))
        // a Backup imported later carries the first gift: the season keeps one day only, the earliest
        let backup = JollyGift.Ledger(days: ["2026": "2026-12-25"])
        let merged = here.merged(with: backup)
        XCTAssertEqual(merged.days, ["2026": "2026-12-25"])
        XCTAssertEqual(JollyGift.days(merged, calendar: cal).count, 1)
    }

    func testMergeNeverLosesASeason() {
        let a = JollyGift.Ledger(days: ["2025": "2025-12-30"])
        let b = JollyGift.Ledger(days: ["2026": "2026-12-26"])
        XCTAssertEqual(a.merged(with: b).days, ["2025": "2025-12-30", "2026": "2026-12-26"])
        XCTAssertEqual(a.merged(with: b), b.merged(with: a))
    }

    func testBackupRoundTripAndOldFiles() throws {
        var file = BackupFile(exportedAt: date(2026, 12, 28))
        file.jollyGifts = ["2026": "2026-12-25"]
        XCTAssertEqual(try BackupFile.decode(file.encoded()).jollyGifts, ["2026": "2026-12-25"])
        let old = Data(#"{"format":"neat-backup","version":1,"exportedAt":"2026-11-01T10:00:00Z"}"#.utf8)
        XCTAssertNil(try BackupFile.decode(old).jollyGifts)
    }

    // MARK: StreakEngine

    func run(start: Date, steps: [Date: Int], gifts: [Date], now: Date, initialJolly: Int = 3) -> StreakState {
        StreakEngine.compute(start: start, initialJolly: initialJolly, steps: steps, goals: goals, gifts: gifts,
                             now: now, calendar: cal)
    }

    func testGiftAddsOneJolly() {
        let s = run(start: day(2026, 12, 20), steps: [:], gifts: [day(2026, 12, 25)], now: date(2026, 12, 25, 9))
        XCTAssertEqual(s.jolly, 4)
        XCTAssertEqual(s.jollyGifted, 1)
        XCTAssertEqual(s.streak, 0)
        XCTAssertEqual(s.counter, 0)
    }

    func testGiftSavesTheStreak() {
        // 20–24 reached, gift on 25 (no Jolly before it), 25 missed: the gift saves it
        var steps: [Date: Int] = [:]
        for d in 20...24 { steps[day(2026, 12, d)] = 12_000 }
        steps[day(2026, 12, 26)] = 12_000
        let s = run(start: day(2026, 12, 20), steps: steps, gifts: [day(2026, 12, 25)], now: date(2026, 12, 27, 9),
                    initialJolly: 0)
        XCTAssertEqual(s.statuses[day(2026, 12, 25)], .saved)
        XCTAssertEqual(s.streak, 6)
        XCTAssertEqual(s.jolly, 0)
        XCTAssertEqual(s.jollyUsed, 1)
        // without the gift the streak breaks on the 25th
        let without = run(start: day(2026, 12, 20), steps: steps, gifts: [], now: date(2026, 12, 27, 9), initialJolly: 0)
        XCTAssertEqual(without.statuses[day(2026, 12, 25)], .missed)
        XCTAssertEqual(without.streak, 1)
    }

    func testGiftReceivedTodayCoversToday() {
        var steps: [Date: Int] = [:]
        for d in 20...27 { steps[day(2026, 12, d)] = 12_000 }
        let s = run(start: day(2026, 12, 20), steps: steps, gifts: [day(2026, 12, 28)], now: date(2026, 12, 28, 9),
                    initialJolly: 0)
        XCTAssertEqual(s.jolly, 1)
        XCTAssertTrue(s.todayWouldUseJolly)
        XCTAssertFalse(s.todayWouldBreak)
    }

    func testGiftDoesNotTouchTheCountToTheNextJolly() {
        var steps: [Date: Int] = [:]
        for d in 15...30 { steps[day(2026, 12, d)] = 12_000 }
        let s = run(start: day(2026, 12, 15), steps: steps, gifts: [day(2026, 12, 25)], now: date(2026, 12, 30, 9))
        XCTAssertEqual(s.streak, 16)
        XCTAssertEqual(s.jollyEarned, 1)                 // 15th day = 29/12
        XCTAssertEqual(s.jolly, 3 + 1 + 1)
        XCTAssertEqual(s.counter, 1)
    }

    func testGiftBeforeTheStartOrInTheFutureIsIgnored() {
        let s = run(start: day(2026, 12, 28), steps: [:], gifts: [day(2025, 12, 25), day(2026, 12, 30)],
                    now: date(2026, 12, 29, 9))
        XCTAssertEqual(s.jolly, 3)
        XCTAssertEqual(s.jollyGifted, 0)
    }

    func testTwoSeasonsTwoGifts() {
        let s = run(start: day(2026, 12, 1), steps: [:], gifts: [day(2026, 12, 25), day(2027, 12, 26)],
                    now: date(2027, 12, 27, 9), initialJolly: 0)
        XCTAssertEqual(s.jollyGifted, 2)
        XCTAssertEqual(s.jolly, 2)                      // streak always 0: nothing to save, nothing spent
    }

    func testGiftDayAfterTimeZoneChangeIsStillCounted() {
        // received on 25/12 in Tokyo, the phone is now in New York: the gift stays on its day there
        let tokyo = calendar("Asia/Tokyo"), ny = calendar("America/New_York")
        var ledger = JollyGift.Ledger()
        JollyGift.claim(&ledger, now: date(2026, 12, 25, 8, cal: tokyo), calendar: tokyo)
        let start = ny.startOfDay(for: date(2026, 12, 20, cal: ny))
        let s = StreakEngine.compute(start: start, initialJolly: 0, steps: [:], goals: goals,
                                     gifts: JollyGift.days(ledger, calendar: ny), now: date(2026, 12, 26, 9, cal: ny),
                                     calendar: ny)
        XCTAssertEqual(s.jollyGifted, 1)
        XCTAssertEqual(s.jolly, 1)
    }
}

/// Sleigh on the road (T-015 §3): it faces where the road goes, leans at most 25°, mirrored on the last curve.
final class SleighPoseTests: XCTestCase {
    func pose(kmh: Double) -> SpeedTrack.Pose {
        let f = DistanceUnit.kilometers.fraction(forKmh: kmh)
        return SpeedTrack.pose(direction: SpeedTrack.road.direction(atFraction: f))
    }

    func testRules() {
        XCTAssertEqual(SpeedTrack.pose(direction: -10), .init(mirrored: false, rotation: -10))
        XCTAssertEqual(SpeedTrack.pose(direction: -60), .init(mirrored: false, rotation: -25))
        XCTAssertEqual(SpeedTrack.pose(direction: 40), .init(mirrored: false, rotation: 25))
        XCTAssertEqual(SpeedTrack.pose(direction: -140), .init(mirrored: true, rotation: 25))    // 15 km/h example
        XCTAssertEqual(SpeedTrack.pose(direction: 170), .init(mirrored: true, rotation: -10))
        XCTAssertEqual(SpeedTrack.pose(direction: -175), .init(mirrored: true, rotation: 5))
    }

    func testOnTheRoad() {
        XCTAssertFalse(pose(kmh: 3).mirrored)
        XCTAssertFalse(pose(kmh: 8).mirrored)
        XCTAssertFalse(pose(kmh: 13).mirrored)
        XCTAssertTrue(pose(kmh: 14).mirrored)                    // from ≈ 13.6 km/h, the last curve
        XCTAssertTrue(pose(kmh: 16).mirrored)
        for v in stride(from: 3.0, through: 16, by: 0.5) { XCTAssertLessThanOrEqual(abs(pose(kmh: v).rotation), 25) }
    }
}
