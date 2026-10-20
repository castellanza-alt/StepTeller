import XCTest
@testable import StepTellerCore

/// `HistoryStats` sums weeks, months and years once and computes `maxOffset` in closed form: here it is compared
/// with the previous implementation (recomputed at every call) on random histories spanning several years, with
/// gaps and goal changes. Same results, bit for bit.
final class HistoryStatsEquivalenceTests: XCTestCase {
    var cal = Calendar(identifier: .gregorian)
    override func setUp() { cal.timeZone = TimeZone(identifier: "Europe/Rome")! }

    /// Deterministic generator (LCG) for reproducible histories.
    struct Random {
        var seed: UInt64
        mutating func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(1 << 53)
        }
        mutating func int(_ range: ClosedRange<Int>) -> Int {
            range.lowerBound + Int(next() * Double(range.count - 1) + 0.5)
        }
    }

    func day(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d))! }

    func makeCase(seed: UInt64) -> (records: [DayRecord], goals: GoalHistory, now: Date) {
        var rnd = Random(seed: seed)
        let years = rnd.int(2...6)
        let today = day(2026, rnd.int(1...12), rnd.int(1...28))
        let start = cal.date(byAdding: .day, value: -(365 * years + rnd.int(0...300)), to: today)!
        var records: [DayRecord] = []
        var d = start
        while d <= today {
            if rnd.next() > 0.2 {                                  // 20% of days without data
                let steps = rnd.int(0...20_000)
                records.append(DayRecord(day: d.addingTimeInterval(Double(rnd.int(0...80_000))),
                                         steps: steps, km: Double(steps) * (0.0006 + rnd.next() * 0.0003)))
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        if rnd.next() < 0.3 { var g = SeededGenerator(seed: seed); records.shuffle(using: &g) }
        var goals = GoalHistory(initialGoal: 10_000)
        for _ in 0..<rnd.int(0...5) {
            let when = cal.date(byAdding: .day, value: -rnd.int(0...(365 * years)), to: today)!
            goals.set(rnd.int(2...16) * 500, from: cal.startOfDay(for: when))
        }
        let now = today.addingTimeInterval(Double(rnd.int(0...86_000)))
        return (records, goals, now)
    }

    func testMatchesPreviousImplementationOnRandomHistories() {
        for seed in 1...30 as ClosedRange<UInt64> {
            let c = makeCase(seed: seed)
            let stats = HistoryStats(records: c.records, goals: c.goals, now: c.now, calendar: cal)
            let legacy = LegacyStats(stats: stats)
            let ctx = "seed \(seed)"
            XCTAssertEqual(stats.interval(.all).start, legacy.intervalAllStart, ctx)
            for period in HistoryPeriod.allCases {
                XCTAssertEqual(stats.maxOffset(period), legacy.maxOffset(period), "\(ctx) maxOffset \(period)")
                for offset in 0...min(3, stats.maxOffset(period)) {
                    XCTAssertEqual(stats.bars(period, offset: offset), legacy.bars(period, offset: offset), "\(ctx) bars \(period) \(offset)")
                    XCTAssertEqual(stats.averageBars(period, offset: offset), legacy.averageBars(period, offset: offset), "\(ctx) averageBars \(period) \(offset)")
                    let a = stats.dailyAverage(period, offset: offset), l = legacy.dailyAverage(period, offset: offset)
                    XCTAssertEqual(a.steps, l.steps, "\(ctx) avg \(period) \(offset)"); XCTAssertEqual(a.km, l.km, "\(ctx) avg km \(period) \(offset)")
                }
            }
            let r = stats.personalRecords(), lr = legacy.personalRecords()
            XCTAssertEqual(r.day, lr.day, ctx)
            XCTAssertEqual(r.week?.steps, lr.week?.steps, ctx); XCTAssertEqual(r.week?.label, lr.week?.label, ctx)
            XCTAssertEqual(r.month?.steps, lr.month?.steps, ctx); XCTAssertEqual(r.month?.label, lr.month?.label, ctx)
            XCTAssertEqual(r.year?.steps, lr.year?.steps, ctx); XCTAssertEqual(r.year?.label, lr.year?.label, ctx)
            XCTAssertEqual(r.week?.km, lr.week?.km, ctx); XCTAssertEqual(r.month?.km, lr.month?.km, ctx); XCTAssertEqual(r.year?.km, lr.year?.km, ctx)
        }
    }

    func testEmptyHistory() {
        let stats = HistoryStats(records: [], goals: GoalHistory(), now: day(2026, 10, 20), calendar: cal)
        XCTAssertEqual(stats.maxOffset(.week), 0)
        XCTAssertEqual(stats.interval(.all).start, stats.today)
        XCTAssertEqual(stats.bars(.year).map(\.steps), Array(repeating: 0, count: 12))
        XCTAssertEqual(stats.personalRecords(), PersonalRecords(day: nil, week: nil, month: nil, year: nil))
        XCTAssertEqual(stats.dailyAverage(.month).steps, 0)
    }
}

/// Copy of the previous `HistoryStats` implementation (0.6.x): scans the records at every call.
private struct LegacyStats {
    let stats: HistoryStats
    var records: [DayRecord] { stats.records }
    var calendar: Calendar { stats.calendar }
    var today: Date { stats.today }

    var intervalAllStart: Date { records.map(\.day).min().map { calendar.startOfDay(for: $0) } ?? today }

    func interval(_ period: HistoryPeriod, offset: Int) -> (start: Date, end: Date) {
        period == .all ? (intervalAllStart, today) : stats.interval(period, offset: offset)
    }

    func maxOffset(_ period: HistoryPeriod) -> Int {
        guard period != .all, let first = records.map(\.day).min() else { return 0 }
        var offset = 0
        while offset < 2000 {
            let i = interval(period, offset: offset + 1)
            if i.end < calendar.startOfDay(for: first) { break }
            offset += 1
        }
        return offset
    }

    func bars(_ period: HistoryPeriod, offset: Int) -> [HistoryBar] {
        let i = interval(period, offset: offset)
        switch period {
        case .week, .month:
            return stats.bars(period, offset: offset)
        case .year:
            let year = calendar.component(.year, from: i.start)
            let thisMonth = calendar.dateComponents([.year, .month], from: today)
            return (1...12).map { m in
                let (s, km) = sum(year: year, month: m)
                let future = year > thisMonth.year! || (year == thisMonth.year! && m > thisMonth.month!)
                let current = year == thisMonth.year! && m == thisMonth.month!
                return HistoryBar(id: m - 1, label: stats.labels.monthLetters[m - 1], steps: s, km: km, goal: 0,
                                  isCurrent: current, isFuture: future)
            }
        case .all:
            let y0 = calendar.component(.year, from: i.start), y1 = calendar.component(.year, from: today)
            return (y0...max(y0, y1)).enumerated().map { n, y in
                let (s, km) = sum(year: y, month: nil)
                return HistoryBar(id: n, label: String(format: "%02d", y % 100), steps: s, km: km, goal: 0,
                                  isCurrent: y == y1, isFuture: false)
            }
        }
    }

    private func sum(year: Int, month: Int?) -> (Int, Double) {
        var steps = 0, km = 0.0
        for r in records {
            let c = calendar.dateComponents([.year, .month], from: r.day)
            if c.year == year && (month == nil || c.month == month) { steps += r.steps; km += r.km }
        }
        return (steps, km)
    }

    func averageBars(_ period: HistoryPeriod, offset: Int) -> [HistoryBar] {
        let base = bars(period, offset: offset)
        guard period == .year || period == .all else { return base }
        let i = interval(period, offset: offset)
        let year0 = calendar.component(.year, from: i.start)
        return base.map { b in
            let start: Date, end: Date
            if period == .year {
                start = calendar.date(from: DateComponents(year: year0, month: b.id + 1, day: 1)) ?? i.start
            } else {
                start = calendar.date(from: DateComponents(year: year0 + b.id, month: 1, day: 1)) ?? i.start
            }
            let next = calendar.date(byAdding: period == .year ? .month : .year, value: 1, to: start) ?? start
            end = calendar.date(byAdding: .day, value: -1, to: next) ?? start
            let avg = dailyAverage(from: start, to: end)
            return HistoryBar(id: b.id, label: b.label, steps: avg.steps, km: avg.km, goal: b.goal,
                              isCurrent: b.isCurrent, isFuture: b.isFuture)
        }
    }

    func dailyAverage(from start: Date, to end: Date) -> (steps: Int, km: Double) {
        guard let first = records.map(\.day).min().map({ calendar.startOfDay(for: $0) }) else { return (0, 0) }
        let byDay = Dictionary(records.map { (calendar.startOfDay(for: $0.day), $0) }, uniquingKeysWith: { a, _ in a })
        let from = max(calendar.startOfDay(for: start), first)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let to = min(calendar.startOfDay(for: end), yesterday)
        var steps = 0, km = 0.0, n = 0
        var day = from
        while day <= to {
            steps += byDay[day]?.steps ?? 0
            km += byDay[day]?.km ?? 0
            n += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        if n == 0 {
            let t = today
            guard t >= from, t <= calendar.startOfDay(for: end) else { return (0, 0) }
            return (byDay[t]?.steps ?? 0, byDay[t]?.km ?? 0)
        }
        return (Int((Double(steps) / Double(n)).rounded()), km / Double(n))
    }

    func dailyAverage(_ period: HistoryPeriod, offset: Int) -> (steps: Int, km: Double) {
        let i = interval(period, offset: offset)
        return dailyAverage(from: i.start, to: i.end)
    }

    func personalRecords() -> PersonalRecords {
        let labels = stats.labels
        let day = records.max(by: { $0.steps < $1.steps }).flatMap { r -> RecordEntry? in
            r.steps > 0 ? RecordEntry(steps: r.steps, km: r.km, label: labels.day(r.day, calendar)) : nil
        }
        var weeks: [Date: (Int, Double)] = [:]
        for r in records {
            let w = calendar.dateInterval(of: .weekOfYear, for: r.day)?.start ?? r.day
            let v = weeks[w] ?? (0, 0)
            weeks[w] = (v.0 + r.steps, v.1 + r.km)
        }
        let week = weeks.max(by: { $0.value.0 < $1.value.0 }).map { start, v -> RecordEntry in
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return RecordEntry(steps: v.0, km: v.1, label: labels.weekRange(start, end, calendar))
        }
        var months: [Int: (Int, Double)] = [:], years: [Int: (Int, Double)] = [:]
        for r in records {
            let c = calendar.dateComponents([.year, .month], from: r.day)
            let mk = c.year! * 100 + c.month!
            let m = months[mk] ?? (0, 0); months[mk] = (m.0 + r.steps, m.1 + r.km)
            let y = years[c.year!] ?? (0, 0); years[c.year!] = (y.0 + r.steps, y.1 + r.km)
        }
        let month = months.max(by: { $0.value.0 < $1.value.0 }).map { k, v in
            let first = calendar.date(from: DateComponents(year: k / 100, month: k % 100, day: 1)) ?? stats.now
            return RecordEntry(steps: v.0, km: v.1, label: labels.month(first, calendar))
        }
        let year = years.max(by: { $0.value.0 < $1.value.0 }).map { k, v in
            RecordEntry(steps: v.0, km: v.1, label: String(k))
        }
        return PersonalRecords(day: day, week: week, month: month, year: year)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed | 1 }
    mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1442695040888963407; return state }
}
