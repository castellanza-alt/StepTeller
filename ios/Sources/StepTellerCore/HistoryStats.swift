import Foundation

public enum HistoryPeriod: String, Sendable, CaseIterable {
    case week, month, year, all
}

/// Una barra del grafico.
public struct HistoryBar: Sendable, Equatable, Identifiable {
    public let id: Int
    public let label: String
    public let steps: Int
    public let km: Double
    /// Obiettivo del giorno (solo per i grafici a giorni; 0 per mesi/anni).
    public let goal: Int
    public let isCurrent: Bool
    public let isFuture: Bool
    public var reachedGoal: Bool { goal > 0 && steps >= goal }
}

public struct PeriodSummary: Sendable, Equatable {
    public let steps: Int
    public let km: Double
    /// Giorni trascorsi nel periodo, oggi compreso.
    public let elapsedDays: Int
    public let averageSteps: Int
    public let daysAtGoal: Int
}

public struct RecordEntry: Sendable, Equatable {
    public let steps: Int
    public let km: Double
    /// Etichetta italiana del giorno/periodo («17 giu 2026», «8 – 14 giu 2026», «Marzo 2026», «2025»).
    public let label: String
}

public struct PersonalRecords: Sendable, Equatable {
    public let day: RecordEntry?
    public let week: RecordEntry?
    public let month: RecordEntry?
    public let year: RecordEntry?
}

/// Statistiche sullo storico giornaliero. Settimana lunedì–domenica.
public struct HistoryStats: Sendable {
    public let records: [DayRecord]
    public let goals: GoalHistory
    public let now: Date
    public let calendar: Calendar
    private let byDay: [Date: DayRecord]

    static let monthNames = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
                             "agosto", "settembre", "ottobre", "novembre", "dicembre"]
    static let shortMonths = ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"]
    static let weekdayLetters = ["L", "M", "M", "G", "V", "S", "D"]
    static let monthLetters = ["G", "F", "M", "A", "M", "G", "L", "A", "S", "O", "N", "D"]

    public init(records: [DayRecord], goals: GoalHistory, now: Date, calendar: Calendar) {
        var cal = calendar
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        self.calendar = cal
        self.records = records
        self.goals = goals
        self.now = now
        byDay = Dictionary(records.map { (cal.startOfDay(for: $0.day), $0) }, uniquingKeysWith: { a, _ in a })
    }

    public var today: Date { calendar.startOfDay(for: now) }

    // MARK: intervalli

    /// Intervallo `[start, end]` (giorni inclusi) del periodo, `offset` periodi indietro (0 = corrente).
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
            let first = records.map(\.day).min().map { calendar.startOfDay(for: $0) } ?? today
            return (first, today)
        }
    }

    /// Numero massimo di periodi indietro con dati.
    public func maxOffset(_ period: HistoryPeriod) -> Int {
        guard period != .all, let first = records.map(\.day).min() else { return 0 }
        var offset = 0
        while offset < 2000 {
            let i = interval(period, offset: offset + 1)
            if i.end < calendar.startOfDay(for: first) { break }
            offset += 1
        }
        return offset
    }

    public func title(_ period: HistoryPeriod, offset: Int = 0) -> String {
        let i = interval(period, offset: offset)
        switch period {
        case .week:
            let a = calendar.dateComponents([.day, .month], from: i.start)
            let b = calendar.dateComponents([.day, .month], from: i.end)
            if a.month == b.month { return "\(a.day!) – \(b.day!) \(Self.monthNames[b.month! - 1])" }
            return "\(a.day!) \(Self.shortMonths[a.month! - 1]) – \(b.day!) \(Self.shortMonths[b.month! - 1])"
        case .month:
            let c = calendar.dateComponents([.year, .month], from: i.start)
            return Self.monthNames[c.month! - 1].capitalized + " \(c.year!)"
        case .year:
            return String(calendar.component(.year, from: i.start))
        case .all:
            return "Da sempre"
        }
    }

    // MARK: barre

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
                    ? Self.weekdayLetters[n % 7]
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
                return HistoryBar(id: m - 1, label: Self.monthLetters[m - 1], steps: s, km: km, goal: 0,
                                  isCurrent: current, isFuture: future)
            }
        case .all:
            let y0 = calendar.component(.year, from: i.start), y1 = calendar.component(.year, from: today)
            return (y0...max(y0, y1)).enumerated().map { n, y in
                let (s, km) = sum(year: y, month: nil)
                return HistoryBar(id: n, label: "’" + String(format: "%02d", y % 100), steps: s, km: km, goal: 0,
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

    // MARK: riepilogo

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

    // MARK: record

    public func personalRecords() -> PersonalRecords {
        func fmt(_ d: Date) -> String {
            let c = calendar.dateComponents([.day, .month, .year], from: d)
            return "\(c.day!) \(Self.shortMonths[c.month! - 1]) \(c.year!)"
        }
        let day = records.max(by: { $0.steps < $1.steps }).flatMap { r -> RecordEntry? in
            r.steps > 0 ? RecordEntry(steps: r.steps, km: r.km, label: fmt(r.day)) : nil
        }
        // settimane
        var weeks: [Date: (Int, Double)] = [:]
        for r in records {
            let w = calendar.dateInterval(of: .weekOfYear, for: r.day)?.start ?? r.day
            let v = weeks[w] ?? (0, 0)
            weeks[w] = (v.0 + r.steps, v.1 + r.km)
        }
        let week = weeks.max(by: { $0.value.0 < $1.value.0 }).map { start, v -> RecordEntry in
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let a = calendar.dateComponents([.day, .month, .year], from: start)
            let b = calendar.dateComponents([.day, .month, .year], from: end)
            let label = a.month == b.month ? "\(a.day!) – \(b.day!) \(Self.shortMonths[b.month! - 1]) \(b.year!)"
                                           : "\(a.day!) \(Self.shortMonths[a.month! - 1]) – \(fmt(end))"
            return RecordEntry(steps: v.0, km: v.1, label: label)
        }
        // mesi e anni
        var months: [Int: (Int, Double)] = [:], years: [Int: (Int, Double)] = [:]
        for r in records {
            let c = calendar.dateComponents([.year, .month], from: r.day)
            let mk = c.year! * 100 + c.month!
            let m = months[mk] ?? (0, 0); months[mk] = (m.0 + r.steps, m.1 + r.km)
            let y = years[c.year!] ?? (0, 0); years[c.year!] = (y.0 + r.steps, y.1 + r.km)
        }
        let month = months.max(by: { $0.value.0 < $1.value.0 }).map { k, v in
            RecordEntry(steps: v.0, km: v.1, label: Self.monthNames[k % 100 - 1].capitalized + " \(k / 100)")
        }
        let year = years.max(by: { $0.value.0 < $1.value.0 }).map { k, v in
            RecordEntry(steps: v.0, km: v.1, label: String(k))
        }
        return PersonalRecords(day: day, week: week, month: month, year: year)
    }
}
