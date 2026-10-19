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
    /// Etichetta del giorno/periodo («17 giu 2026», «8 – 14 giu 2026», «Marzo 2026», «2025»).
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
    /// Etichette delle date (italiano se non indicato).
    public let labels: HistoryLabels
    private let byDay: [Date: DayRecord]

    public init(records: [DayRecord], goals: GoalHistory, now: Date, calendar: Calendar, labels: HistoryLabels = .italian) {
        var cal = calendar
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        self.calendar = cal
        self.records = records
        self.goals = goals
        self.now = now
        self.labels = labels
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
        var steps = 0, km = 0.0
        for r in records {
            let c = calendar.dateComponents([.year, .month], from: r.day)
            if c.year == year && (month == nil || c.month == month) { steps += r.steps; km += r.km }
        }
        return (steps, km)
    }

    // MARK: medie giornaliere

    /// Barre di Anno e Sempre come **media giornaliera** (passi/giorno) di ogni mese o anno, così
    /// l'obiettivo giornaliero resta confrontabile in tutti i grafici. Regola delle medie: `dailyAverage`.
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

    /// Media dei totali giornalieri tra `start` ed `end` (inclusi). Conta i giorni **conclusi**
    /// (oggi escluso, perché a metà giornata abbasserebbe la media) a partire dal primo giorno con dati;
    /// i giorni senza dati valgono 0. Se nel periodo c'è solo oggi, la media è il valore di oggi.
    public func dailyAverage(from start: Date, to end: Date) -> (steps: Int, km: Double) {
        guard let first = records.map(\.day).min().map({ calendar.startOfDay(for: $0) }) else { return (0, 0) }
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

    /// Media giornaliera di un periodo (stessa regola di `dailyAverage`).
    public func dailyAverage(_ period: HistoryPeriod, offset: Int = 0) -> (steps: Int, km: Double) {
        let i = interval(period, offset: offset)
        return dailyAverage(from: i.start, to: i.end)
    }

    /// Etichetta di un intervallo di giorni (es. la streak più lunga): «3 – 17 ott 2026»,
    /// «giu – ott 2024», «dic 2025 – feb 2026», o il solo giorno.
    public func rangeLabel(from start: Date, to end: Date) -> String {
        labels.span(start, end, calendar)
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
        func fmt(_ d: Date) -> String { labels.day(d, calendar) }
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
            return RecordEntry(steps: v.0, km: v.1, label: labels.weekRange(start, end, calendar))
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
            let first = calendar.date(from: DateComponents(year: k / 100, month: k % 100, day: 1)) ?? now
            return RecordEntry(steps: v.0, km: v.1, label: labels.month(first, calendar))
        }
        let year = years.max(by: { $0.value.0 < $1.value.0 }).map { k, v in
            RecordEntry(steps: v.0, km: v.1, label: String(k))
        }
        return PersonalRecords(day: day, week: week, month: month, year: year)
    }
}
