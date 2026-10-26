import Foundation

public enum HistoryPeriod: String, Sendable, CaseIterable {
    case week, month, year, all
}

/// One bar of the chart.
public struct HistoryBar: Sendable, Equatable, Identifiable {
    public let id: Int
    public let label: String
    public let steps: Int
    public let km: Double
    /// Goal of the day (day charts only; 0 for months/years).
    public let goal: Int
    public let isCurrent: Bool
    public let isFuture: Bool
    public var reachedGoal: Bool { goal > 0 && steps >= goal }
}

public struct PeriodSummary: Sendable, Equatable {
    public let steps: Int
    public let km: Double
    /// Days elapsed in the period, today included.
    public let elapsedDays: Int
    public let averageSteps: Int
    public let daysAtGoal: Int
}

public struct RecordEntry: Sendable, Equatable {
    public let steps: Int
    public let km: Double
    /// Label of the day/period («17 giu 2026», «8 – 14 giu 2026», «Marzo 2026», «2025»).
    public let label: String
}

public struct PersonalRecords: Sendable, Equatable {
    public let day: RecordEntry?
    public let week: RecordEntry?
    public let month: RecordEntry?
    public let year: RecordEntry?
}

/// Statistics over the daily history. Weeks run Monday–Sunday.
public struct HistoryStats: Sendable {
    public let records: [DayRecord]
    public let goals: GoalHistory
    public let now: Date
    public let calendar: Calendar
    /// Date labels (Italian unless given).
    public let labels: HistoryLabels
    /// Record per start of day (the first one, if a day appears twice).
    public let byDay: [Date: DayRecord]
    /// First day with data (start of day); `nil` without records.
    public let firstDay: Date?
    // Totals per week (key: week start), month (year × 100 + month) and year, summed once in record order:
    // charts and records read them instead of scanning the whole history again.
    private let weekTotals: [Date: Total]
    private let monthTotals: [Int: Total]
    private let yearTotals: [Int: Total]

    private struct Total: Sendable {
        var steps = 0
        var km = 0.0
        mutating func add(_ r: DayRecord) { steps += r.steps; km += r.km }
    }

    public init(records: [DayRecord], goals: GoalHistory, now: Date, calendar: Calendar, labels: HistoryLabels = .italian) {
        var cal = calendar
        // ISO weeks: Monday first, the week holding 4 January is week 1 (same rule on every platform).
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        self.calendar = cal
        self.records = records
        self.goals = goals
        self.now = now
        self.labels = labels
        var byDay: [Date: DayRecord] = [:]
        var first: Date?
        var weeks: [Date: Total] = [:], months: [Int: Total] = [:], years: [Int: Total] = [:]
        for r in records {
            let day = cal.startOfDay(for: r.day)
            if byDay[day] == nil { byDay[day] = r }
            if first.map({ day < $0 }) ?? true { first = day }
            let c = cal.dateComponents([.year, .month], from: r.day)
            months[c.year! * 100 + c.month!, default: Total()].add(r)
            years[c.year!, default: Total()].add(r)
            weeks[cal.dateInterval(of: .weekOfYear, for: r.day)?.start ?? r.day, default: Total()].add(r)
        }
        self.byDay = byDay
        firstDay = first
        weekTotals = weeks
        monthTotals = months
        yearTotals = years
    }

    public var today: Date { calendar.startOfDay(for: now) }

    // MARK: intervals

    /// `[start, end]` interval (days included) of the period, `offset` periods back (0 = current).
    public func interval(_ period: HistoryPeriod, offset: Int = 0) -> (start: Date, end: Date) {
        switch period {
        case .week:
            let base = calendar.date(byAdding: .weekOfYear, value: -offset, to: today) ?? today
            let start = calendar.dateInterval(of: .weekOfYear, for: base)?.start ?? base
            return (start, calendar.date(byAdding: .day, value: 6, to: start) ?? start)
        case .month:
            let base = calendar.date(byAdding: .month, value: -offset, to: today) ?? today
            let start = calendar.dateInterval(of: .month, for: base)?.start ?? base
            let next = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            return (start, calendar.date(byAdding: .day, value: -1, to: next) ?? start)
        case .year:
            let base = calendar.date(byAdding: .year, value: -offset, to: today) ?? today
            let start = calendar.dateInterval(of: .year, for: base)?.start ?? base
            let next = calendar.date(byAdding: .year, value: 1, to: start) ?? start
            return (start, calendar.date(byAdding: .day, value: -1, to: next) ?? start)
        case .all:
            return (firstDay ?? today, today)
        }
    }

    /// Maximum number of periods back with data: whole periods between the first record's and today's.
    public func maxOffset(_ period: HistoryPeriod) -> Int {
        guard period != .all, let first = firstDay else { return 0 }
        let unit: Calendar.Component = period == .week ? .weekOfYear : period == .month ? .month : .year
        let from = calendar.dateInterval(of: unit, for: first)?.start ?? first
        let to = calendar.dateInterval(of: unit, for: today)?.start ?? today
        return max(0, calendar.dateComponents([unit], from: from, to: to).value(for: unit) ?? 0)
    }

    public func title(_ period: HistoryPeriod, offset: Int = 0) -> String {
        let i = interval(period, offset: offset)
        switch period {
        case .week:
            return labels.week(i.start, i.end, calendar)
        case .month:
            return labels.month(i.start, calendar)
        case .year:
            return String(calendar.component(.year, from: i.start))
        case .all:
            let y0 = calendar.component(.year, from: i.start), y1 = calendar.component(.year, from: today)
            return y0 == y1 ? "\(y1)" : "\(y0) – \(y1)"
        }
    }

    // MARK: bars

    public func bars(_ period: HistoryPeriod, offset: Int = 0) -> [HistoryBar] {
        let i = interval(period, offset: offset)
        switch period {
        case .week, .month:
            var result: [HistoryBar] = []
            var day = i.start
            var n = 0
            while day <= i.end {
                let rec = byDay[day]
                let label = period == .week
                    ? labels.weekdayLetters[n % 7]
                    : String(calendar.component(.day, from: day))
                result.append(HistoryBar(id: n, label: label, steps: rec?.steps ?? 0, km: rec?.km ?? 0,
                                         goal: goals.goal(on: day), isCurrent: day == today, isFuture: day > today))
                n += 1
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            return result
        case .year:
            let year = calendar.component(.year, from: i.start)
            let thisMonth = calendar.dateComponents([.year, .month], from: today)
            return (1...12).map { m in
                let (s, km) = sum(year: year, month: m)
                let future = year > thisMonth.year! || (year == thisMonth.year! && m > thisMonth.month!)
                let current = year == thisMonth.year! && m == thisMonth.month!
                return HistoryBar(id: m - 1, label: labels.monthLetters[m - 1], steps: s, km: km, goal: 0,
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
        let t = month.map { monthTotals[year * 100 + $0] } ?? yearTotals[year]
        return (t?.steps ?? 0, t?.km ?? 0)
    }

    // MARK: daily averages

    /// Year and All bars as the **daily average** (steps/day) of each month or year, so the daily goal
    /// stays comparable in every chart. Averaging rule: `dailyAverage`.
    public func averageBars(_ period: HistoryPeriod, offset: Int = 0) -> [HistoryBar] {
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

    /// Average of the daily totals between `start` and `end` (inclusive). Counts **completed** days
    /// (today excluded: half a day would pull the average down) from the first day with data;
    /// days without data count as 0. If the period only holds today, the average is today's value.
    public func dailyAverage(from start: Date, to end: Date) -> (steps: Int, km: Double) {
        guard let first = firstDay else { return (0, 0) }
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

    /// Daily average of a period (same rule as `dailyAverage`).
    public func dailyAverage(_ period: HistoryPeriod, offset: Int = 0) -> (steps: Int, km: Double) {
        let i = interval(period, offset: offset)
        return dailyAverage(from: i.start, to: i.end)
    }

    /// Label of a range of days (e.g. the longest streak): «3 – 17 ott 2026»,
    /// «giu – ott 2024», «dic 2025 – feb 2026», or the single day.
    public func rangeLabel(from start: Date, to end: Date) -> String {
        labels.span(start, end, calendar)
    }

    // MARK: summary

    public func summary(_ period: HistoryPeriod, offset: Int = 0) -> PeriodSummary {
        let i = interval(period, offset: offset)
        var steps = 0, km = 0.0, atGoal = 0, elapsed = 0
        var day = i.start
        while day <= min(i.end, today) {
            elapsed += 1
            if let r = byDay[day] {
                steps += r.steps
                km += r.km
            }
            if (byDay[day]?.steps ?? 0) >= goals.goal(on: day) && goals.goal(on: day) > 0 { atGoal += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return PeriodSummary(steps: steps, km: km, elapsedDays: elapsed,
                             averageSteps: elapsed > 0 ? Int((Double(steps) / Double(elapsed)).rounded()) : 0,
                             daysAtGoal: atGoal)
    }

    // MARK: records

    public func personalRecords() -> PersonalRecords {
        func fmt(_ d: Date) -> String { labels.day(d, calendar) }
        let day = records.max(by: { $0.steps < $1.steps }).flatMap { r -> RecordEntry? in
            r.steps > 0 ? RecordEntry(steps: r.steps, km: r.km, label: fmt(r.day)) : nil
        }
        let week = weekTotals.max(by: { $0.value.steps < $1.value.steps }).map { start, v -> RecordEntry in
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return RecordEntry(steps: v.steps, km: v.km, label: labels.weekRange(start, end, calendar))
        }
        let month = monthTotals.max(by: { $0.value.steps < $1.value.steps }).map { k, v in
            let first = calendar.date(from: DateComponents(year: k / 100, month: k % 100, day: 1)) ?? now
            return RecordEntry(steps: v.steps, km: v.km, label: labels.month(first, calendar))
        }
        let year = yearTotals.max(by: { $0.value.steps < $1.value.steps }).map { k, v in
            RecordEntry(steps: v.steps, km: v.km, label: String(k))
        }
        return PersonalRecords(day: day, week: week, month: month, year: year)
    }
}
