import XCTest
@testable import StepTellerCore

/// The app hands the core `Calendar.autoupdatingCurrent`: if the phone changes time zone with the app in memory,
/// «today» follows the new zone. Here the change is simulated by swapping the controller calendar between
/// two reads (tests keep an explicit calendar).
final class TimeZoneChangeTests: XCTestCase {
    private final class RecordingProvider: StepsProvider, @unchecked Sendable {
        var value: Int?
        var lastRange: (from: Date, to: Date)?
        var isAvailable: Bool { true }
        func requestAccess() async {}
        func steps(from startOfDay: Date, to now: Date) async -> Int? { lastRange = (startOfDay, now); return value }
        func observe(_ onChange: @escaping @Sendable () async -> Void) async {}
        func stopObserving() async {}
    }

    func calendar(_ zone: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    func testManualOverrideExpiresAndTodayFollowsTheNewTimeZone() async {
        let rome = calendar("Europe/Rome"), tokyo = calendar("Asia/Tokyo")
        // 20 October 2026, 23:30 in Rome = 21 October, 06:30 in Tokyo
        let instant = rome.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 23, minute: 30))!
        let provider = RecordingProvider(); provider.value = 500
        var controller = StepsController(provider: provider, calendar: rome)
        var state = StepsState()
        state.setManual(9_000, at: instant, calendar: rome)
        await controller.refresh(&state, now: instant)
        XCTAssertEqual(state.steps, 9_000, "a Roma è ancora il 20: la correzione manuale vale")
        XCTAssertEqual(provider.lastRange?.from, rome.startOfDay(for: instant))

        controller.calendar = tokyo                       // the phone changes zone: in Tokyo it is already the 21st
        await controller.refresh(&state, now: instant)
        XCTAssertNil(state.override, "la correzione del 20 scade: è un altro giorno")
        XCTAssertEqual(state.steps, 500)
        XCTAssertEqual(provider.lastRange?.from, tokyo.startOfDay(for: instant))
        XCTAssertEqual(tokyo.component(.day, from: provider.lastRange!.from), 21)
    }

    func testHistoryTodayAndReminderDayFollowTheCalendar() {
        let rome = calendar("Europe/Rome"), tokyo = calendar("Asia/Tokyo")
        let instant = rome.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 23, minute: 30))!
        let records = [DayRecord(day: rome.startOfDay(for: instant), steps: 12_000, km: 9)]
        let inRome = HistoryStats(records: records, goals: GoalHistory(), now: instant, calendar: rome)
        let inTokyo = HistoryStats(records: records, goals: GoalHistory(), now: instant, calendar: tokyo)
        XCTAssertEqual(rome.component(.day, from: inRome.today), 20)
        XCTAssertEqual(tokyo.component(.day, from: inTokyo.today), 21)
        XCTAssertTrue(inRome.bars(.week).contains { $0.isCurrent && $0.steps == 12_000 })
        // reminder: the identifier carries the day of the current zone
        let plan = Plan(goal: 10_000, steps: 100, speed: 6)
        let r = ReminderPlanner.schedule(now: instant, minutesFromMidnight: 20 * 60 + 30, plan: plan, calendar: tokyo)
        XCTAssertEqual(r.first?.id, "stepteller.reminder.2026-10-21")
    }
}
