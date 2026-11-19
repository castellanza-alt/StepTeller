import Foundation

/// The numbers for the placeholders. Nil (or not above zero) means «no value»: the lines that need it are not chosen.
public struct NastyValues: Equatable, Sendable {
    public var passi: Int?
    public var obiettivo: Int?
    public var mancano: Int?
    public var minuti: Int?
    public var serie: Int?
    public var jolly: Int?
    public var percento: Int?

    public init(passi: Int? = nil, obiettivo: Int? = nil, mancano: Int? = nil, minuti: Int? = nil, serie: Int? = nil,
                jolly: Int? = nil, percento: Int? = nil) {
        self.passi = passi; self.obiettivo = obiettivo; self.mancano = mancano; self.minuti = minuti
        self.serie = serie; self.jolly = jolly; self.percento = percento
    }

    public subscript(_ p: NastyPlaceholder) -> Int? {
        let v: Int? = switch p {
        case .passi: passi
        case .obiettivo: obiettivo
        case .mancano: mancano
        case .minuti: minuti
        case .serie: serie
        case .jolly: jolly
        case .percento: percento
        }
        guard let v, v > 0 else { return nil }
        // never «zero passi» (William): below 50 steps no line with the number of steps
        if p == .passi, v < NastyMoment.minStepsShown { return nil }
        return v
    }
}

/// What is happening, from the data the app has (T-022 §2): the situations whose lines fit, the true facts and the
/// numbers. Pure: the thresholds are here and in the tests.
public struct NastyMoment: Equatable, Sendable {
    public var situations: [NastySituation]
    public var facts: Set<NastyEvent>
    public var values: NastyValues
    /// Minutes from midnight when the line is said (the delivery time for a notification).
    public var minuteOfDay: Int

    public init(situations: [NastySituation], facts: Set<NastyEvent> = [], values: NastyValues, minuteOfDay: Int) {
        self.situations = situations; self.facts = facts; self.values = values; self.minuteOfDay = minuteOfDay
    }

    /// Below this many steps no line shows the steps (`{passi}`): never «0 passi», «12 passi».
    public static let minStepsShown = 50
    /// From this percentage of the goal: «A metà e quasi».
    public static let halfPercent = 50
    /// Low steps from 11:00: also the lines of the time of day; from 18:00 those of the evening.
    public static let afternoonFrom = 11 * 60
    public static let eveningFrom = 18 * 60

    /// The day so far: what the app knows now.
    public struct Day: Equatable, Sendable {
        public var steps: Int
        public var goal: Int
        /// Minutes still to walk at the chosen speed (`Plan.minutes`).
        public var minutesLeft: Int
        public var streak: Int
        public var jolly: Int
        /// Today is the best day ever (the app knows the history).
        public var isRecord: Bool
        public var minuteOfDay: Int

        public init(steps: Int, goal: Int, minutesLeft: Int, streak: Int, jolly: Int, isRecord: Bool = false,
                    minuteOfDay: Int) {
            self.steps = steps; self.goal = goal; self.minutesLeft = minutesLeft; self.streak = streak
            self.jolly = jolly; self.isRecord = isRecord; self.minuteOfDay = minuteOfDay
        }

        public var percent: Int { goal > 0 ? max(0, steps) * 100 / goal : 0 }
        public var reached: Bool { goal > 0 && steps >= goal }

        var values: NastyValues {
            NastyValues(passi: steps, obiettivo: goal, mancano: max(0, goal - steps), minuti: reached ? nil : minutesLeft,
                        serie: streak, jolly: jolly, percento: reached ? nil : percent)
        }
    }

    /// Why NEAT speaks.
    public enum Trigger: Equatable, Sendable {
        /// The bubble in Home.
        case home
        /// A tap on the heart.
        case heart
        /// A roast notification (`minuteOfDay` of the day is the delivery time).
        case notification
        /// The goal was chosen (`old` nil: the first time) or changed.
        case goalChanged(old: Int?)
        /// A pop-up of Jolly and streak.
        case jollyUsed
        case jollyEarned
        /// The streak was lost: `lost` days.
        case streakLost(lost: Int)
        /// The streak still goes on (e.g. a round number), or is at risk tonight.
        case streakGoing
        case streakAtRisk
    }

    /// The moment for a trigger.
    public static func of(_ trigger: Trigger, day: Day) -> NastyMoment {
        var values = day.values
        var facts: Set<NastyEvent> = []
        let situations: [NastySituation]
        switch trigger {
        case .home:
            situations = homeSituations(day)
            if day.reached {
                if day.isRecord { facts.insert(.record) }
                if day.steps >= 2 * day.goal { facts.insert(.doppio) }
            }
        case .heart:
            situations = [.cuore]
        case .notification:
            situations = day.reached ? [] : [.notifiche]
        case .goalChanged(let old):
            situations = [.obiettivo]
            if let old, day.goal < old { facts.insert(.abbassato) }
            if let old, day.goal > old { facts.insert(.alzato) }
        case .jollyUsed:
            situations = [.jollySerie]
            facts.insert(.jollyUsato)
            if day.jolly == 0 { facts.insert(.jollyFiniti) }
        case .jollyEarned:
            situations = [.jollySerie]
            facts.insert(.jollyGuadagnato)
        case .streakLost(let lost):
            situations = [.jollySerie]
            facts.insert(.seriePersa)
            values.serie = lost
        case .streakGoing:
            situations = [.jollySerie]
            facts.insert(.serieInCorso)
        case .streakAtRisk:
            situations = day.reached ? [] : [.jollySerie]
            facts.insert(.serieARischio)
        }
        return NastyMoment(situations: situations, facts: facts, values: values, minuteOfDay: day.minuteOfDay)
    }

    /// Home: goal reached → «Quando ce la fai»; from half the goal → «A metà e quasi»; below, «Pochi passi», from
    /// 11:00 also the lines of the time of day and from 18:00 those of the evening.
    static func homeSituations(_ day: Day) -> [NastySituation] {
        if day.reached { return [.fatto] }
        if day.percent >= halfPercent { return [.aMetaQuasi] }
        if day.minuteOfDay >= eveningFrom { return [.pochiPassi, .sera] }
        if day.minuteOfDay >= afternoonFrom { return [.pochiPassi, .mattinaPomeriggio] }
        return [.pochiPassi]
    }
}

/// Lines already seen, per level, last first (T-022 §2): on the phone only, never in iCloud or the Backup.
public struct NastyMemory: Codable, Equatable, Sendable {
    /// No line repeats among the last this many of its level.
    public static let size = 20
    public var seen: [String: [String]] = [:]

    public init() {}

    public func recent(_ level: NastyLevel) -> [String] { seen[level.rawValue] ?? [] }

    public mutating func record(_ id: String, level: NastyLevel) {
        var list = recent(level).filter { $0 != id }
        list.insert(id, at: 0)
        seen[level.rawValue] = Array(list.prefix(Self.size))
    }

    public func encoded() -> Data? { try? JSONEncoder().encode(self) }
    public static func decoded(_ data: Data?) -> NastyMemory? { data.flatMap { try? JSONDecoder().decode(NastyMemory.self, from: $0) } }
}

/// A line ready to show: placeholders filled.
public struct NastyQuote: Equatable, Sendable {
    public let id: String
    public let title: String?
    public let text: String

    public init(id: String, title: String?, text: String) { self.id = id; self.title = title; self.text = text }
}

/// Choice of the line (T-022 §2).
public enum NastyPicker {
    /// Lines that may be said in a moment: right level and situation, their hours, their event true, every number
    /// they show available (so never «zero passi»).
    public static func candidates(_ catalog: NastyCatalog, level: NastyLevel, moment: NastyMoment) -> [NastyLine] {
        moment.situations.flatMap { catalog.lines(level, $0) }
            .reduce(into: [NastyLine]()) { out, line in if !out.contains(where: { $0.id == line.id }) { out.append(line) } }
            .filter { line in
                if let range = line.minutes, !range.contains(moment.minuteOfDay) { return false }
                if let raw = line.evento { guard let e = NastyEvent(rawValue: raw), moment.facts.contains(e) else { return false } }
                return line.placeholders.allSatisfy { moment.values[$0] != nil }
            }
    }

    /// At random among the candidates not among the last `NastyMemory.size` of the level; when all were seen
    /// recently, the one seen longest ago (with `allowRecent`; otherwise nil). Nil: no line fits (Normale, or
    /// nothing for these numbers).
    /// - The lines of a true event come before the generic ones, the rarest event first (`precedence`: record, then
    ///   twice the goal…): «Doppio dell'obiettivo» wins over «Obiettivo raggiunto» (T-031).
    /// - `avoiding`: placeholders to do without when possible (notifications: `{passi}` can be old by delivery time).
    /// - `excluding`: placeholders never said, because the place shows that number already (the Jolly tag of the
    ///   pop-up, the minutes of the reminder).
    /// - `notSaying`: texts the line must not repeat, because the place shows them already (the pop-up's title);
    ///   compared without case, accents and punctuation. Translations reword titles: `repeating` finds the lines on
    ///   the Italian reference, and `excludingIDs` leaves them out in every language (ids are shared).
    /// - `excludingIDs`: lines never said here.
    public static func pick(_ catalog: NastyCatalog, level: NastyLevel, moment: NastyMoment, memory: NastyMemory,
                            avoiding: Set<NastyPlaceholder> = [], excluding: Set<NastyPlaceholder> = [],
                            excludingIDs: Set<String> = [], notSaying: [String] = [], allowRecent: Bool = true,
                            format: (Int) -> String = ItalianFormat.integer,
                            using rng: inout some RandomNumberGenerator) -> NastyQuote? {
        let shown = notSaying.map(plain).filter { !$0.isEmpty }
        let all = candidates(catalog, level: level, moment: moment).filter { line in
            !excludingIDs.contains(line.id) && line.placeholders.isDisjoint(with: excluding)
                && !shown.contains { plain((line.titolo ?? "") + " " + line.testo).contains($0) }
        }
        guard !all.isEmpty else { return nil }
        let recent = memory.recent(level)
        func preferred(_ lines: [NastyLine]) -> [NastyLine] {
            let without = lines.filter { $0.placeholders.isDisjoint(with: avoiding) }
            return without.isEmpty ? lines : without
        }
        // tiers by event, rarest first; in each, the lines not seen recently
        let tiers = Dictionary(grouping: all, by: { precedence($0.event) }).sorted { $0.key > $1.key }.map(\.value)
        for tier in tiers {
            let fresh = tier.filter { !recent.contains($0.id) }
            guard !fresh.isEmpty else { continue }
            let pool = preferred(fresh)
            return quote(pool[Int.random(in: 0..<pool.count, using: &rng)], values: moment.values, format: format)
        }
        guard allowRecent, let top = tiers.first else { return nil }
        let line = preferred(top).max { (recent.firstIndex(of: $0.id) ?? .max) < (recent.firstIndex(of: $1.id) ?? .max) }!
        return quote(line, values: moment.values, format: format)
    }

    /// Lines of `catalog` (the Italian reference) that repeat one of `texts`: their ids, to leave out in any language.
    public static func repeating(_ texts: [String], in catalog: NastyCatalog) -> Set<String> {
        let shown = texts.map(plain).filter { !$0.isEmpty }
        return Set(catalog.battute.filter { line in
            shown.contains { plain((line.titolo ?? "") + " " + line.testo).contains($0) }
        }.map(\.id))
    }

    /// Which lines come first: the rarer the event, the higher (T-031: record, then twice the goal, then the last
    /// Jolly, then any other event, then the generic lines).
    static func precedence(_ event: NastyEvent?) -> Int {
        switch event {
        case nil: 0
        case .record: 4
        case .doppio: 3
        case .jollyFiniti: 2
        default: 1
        }
    }

    /// Lowercase letters and digits only, words split by one space: «JOLLY GUADAGNATO!» → «jolly guadagnato».
    static func plain(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return folded.split(whereSeparator: { !($0.isLetter || $0.isNumber) }).joined(separator: " ")
    }

    /// Fills the placeholders. `format`: numbers as in the rest of the app in the catalog's language (the app passes
    /// its `LocalFormat.integer`; Italian «10.000» by default).
    public static func quote(_ line: NastyLine, values: NastyValues,
                             format: (Int) -> String = ItalianFormat.integer) -> NastyQuote {
        func fill(_ text: String) -> String {
            NastyPlaceholder.allCases.reduce(text) { out, p in
                guard let v = values[p] else { return out }
                return out.replacingOccurrences(of: p.token, with: format(v))
            }
        }
        return NastyQuote(id: line.id, title: line.titolo.map(fill), text: fill(line.testo))
    }
}

/// Repeatable randomness (SplitMix64): the same seed gives the same choices, on every platform.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Stable seed from a text (FNV-1a): `Hasher` changes at every launch, this does not.
    public static func seed(_ text: String) -> UInt64 {
        text.utf8.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
    }
}
