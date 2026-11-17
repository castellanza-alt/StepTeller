import XCTest
@testable import StepTellerCore

final class BackupFileTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 1_790_000_000)

    func testRoundTrip() throws {
        var file = BackupFile(exportedAt: day)
        file.goal = 12_000
        file.speed = 5.5
        file.units = UnitPreference.miles.rawValue
        file.reminderOn = false
        file.reminderMinutes = 21 * 60 + 15
        file.theme = "night"
        file.streakStart = day.addingTimeInterval(-30 * 86_400)
        var goals = GoalHistory(initialGoal: 10_000)
        goals.set(12_000, from: day)
        file.goalHistory = goals
        file.calibration = CalibrationResult(walk: [.init(speed: 5, cadence: 110)], run: [], walkWorkouts: 3, runWorkouts: 0)
        file.eventNotificationsOn = false
        file.seasonalThemes = false
        XCTAssertEqual(try BackupFile.decode(file.encoded()), file)
    }

    func testFileOfVersion11WithoutEventSwitchStillReads() throws {
        // a 1.1 backup has no `eventNotificationsOn`: it reads, the value stays missing (the setting is not touched)
        let old = Data(#"{"format":"neat-backup","version":1,"exportedAt":"2026-11-01T10:00:00Z","goal":9000}"#.utf8)
        let read = try BackupFile.decode(old)
        XCTAssertEqual(read.goal, 9000)
        XCTAssertNil(read.eventNotificationsOn)
    }

    func testMissingValuesStayMissing() throws {
        let read = try BackupFile.decode(BackupFile(exportedAt: day).encoded())
        XCTAssertNil(read.goal)
        XCTAssertNil(read.streakStart)
        XCTAssertNil(read.goalHistory)
    }

    func testRejectsOtherFiles() {
        XCTAssertThrowsError(try BackupFile.decode(Data("{\"goal\": 5}".utf8))) {
            XCTAssertEqual($0 as? BackupFile.ReadError, .notABackup)
        }
        XCTAssertThrowsError(try BackupFile.decode(Data("not json".utf8))) {
            XCTAssertEqual($0 as? BackupFile.ReadError, .notABackup)
        }
    }

    func testRejectsNewerVersion() throws {
        var file = BackupFile(exportedAt: day)
        file.version = BackupFile.currentVersion + 1
        XCTAssertThrowsError(try BackupFile.decode(file.encoded())) {
            XCTAssertEqual($0 as? BackupFile.ReadError, .newerVersion)
        }
    }

    func testStreakStartKeepsTheEarliest() {
        let early = day.addingTimeInterval(-86_400)
        XCTAssertEqual(BackupFile.mergedStreakStart(current: day, imported: early), early)
        XCTAssertEqual(BackupFile.mergedStreakStart(current: early, imported: day), early)
        XCTAssertEqual(BackupFile.mergedStreakStart(current: nil, imported: day), day)
        XCTAssertEqual(BackupFile.mergedStreakStart(current: day, imported: nil), day)
    }
}
