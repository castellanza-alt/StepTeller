import XCTest
@testable import StepTellerCore

final class SeasonTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }
    func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testChristmasPeriodEdges() {
        XCTAssertNil(Season.active(on: at(2026, 11, 30, 23, 59), calendar: cal))
        XCTAssertEqual(Season.active(on: at(2026, 12, 1, 0, 0), calendar: cal), .christmas)
        XCTAssertEqual(Season.active(on: at(2026, 12, 25), calendar: cal), .christmas)
        XCTAssertEqual(Season.active(on: at(2027, 1, 1), calendar: cal), .christmas)
        XCTAssertEqual(Season.active(on: at(2027, 1, 6, 23, 59), calendar: cal), .christmas)
        XCTAssertNil(Season.active(on: at(2027, 1, 7, 0, 0), calendar: cal))
        XCTAssertNil(Season.active(on: at(2027, 7, 15), calendar: cal))
    }

    func testLocalTimeDecides() {
        // 30 November 23:30 in Rome is already 1 December in Tokyo
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let instant = at(2026, 11, 30, 23, 30)
        XCTAssertNil(Season.active(on: instant, calendar: cal))
        XCTAssertEqual(Season.active(on: instant, calendar: tokyo), .christmas)
    }

    func testSeasonInsideOneYear() {
        let halloween = Season(id: "halloween", start: (10, 24), end: (11, 1))
        XCTAssertTrue(halloween.contains(at(2026, 10, 31), calendar: cal))
        XCTAssertFalse(halloween.contains(at(2026, 11, 2), calendar: cal))
        XCTAssertFalse(halloween.contains(at(2026, 10, 23), calendar: cal))
    }

    func testNamed() {
        XCTAssertEqual(Season.named("christmas"), .christmas)
        XCTAssertNil(Season.named("none"))
    }
}
