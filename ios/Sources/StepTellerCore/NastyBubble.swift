import Foundation

/// The line in the Home bubble (T-022 §1, T-023 §2): it changes when the situation changes, at most once an hour,
/// and with the day; right away when it can no longer be said (goal reached, a number gone, its hours over). The
/// numbers are filled again at every showing, so «3.240 passi» follows the steps. Saved on the phone only.
public struct NastyBubble: Codable, Equatable, Sendable {
    public let id: String
    public let level: NastyLevel
    /// The situations of Home when it was chosen (for a heart line too: the Home it was said on).
    public let situations: [NastySituation]
    public let since: Date
    /// A line «Se tocchi il cuore»: it stays only while the situation stays, at most an hour.
    public let heart: Bool

    /// The line does not change more often than this when the situation changes.
    public static let minChange: TimeInterval = 3600

    public init(id: String, level: NastyLevel, situations: [NastySituation], since: Date, heart: Bool) {
        self.id = id; self.level = level; self.situations = situations; self.since = since; self.heart = heart
    }

    /// The line, if it can still be said now with these numbers.
    public func line(in catalog: NastyCatalog, moment: NastyMoment) -> NastyLine? {
        var said = moment
        if heart { said.situations = [.cuore]; said.facts = [] }
        return NastyPicker.candidates(catalog, level: level, moment: said).first { $0.id == id }
    }

    /// Whether the bubble keeps its line now.
    func keeps(level: NastyLevel, moment: NastyMoment, now: Date, calendar: Calendar) -> Bool {
        guard self.level == level, calendar.isDate(since, inSameDayAs: now), now >= since else { return false }
        let same = situations == moment.situations
        let recent = now.timeIntervalSince(since) < Self.minChange
        return heart ? same && recent : same || recent
    }

    /// The Home bubble now: the current line while it holds, otherwise a new one (recorded in `memory`). Nil with
    /// Normale or when no line fits.
    public static func home(_ current: NastyBubble?, catalog: NastyCatalog, level: NastyLevel, moment: NastyMoment,
                            memory: inout NastyMemory, now: Date, calendar: Calendar,
                            format: (Int) -> String = ItalianFormat.integer,
                            using rng: inout some RandomNumberGenerator) -> (bubble: NastyBubble, quote: NastyQuote)? {
        guard level != .normale else { return nil }
        if let current, current.keeps(level: level, moment: moment, now: now, calendar: calendar),
           let line = current.line(in: catalog, moment: moment),
           // an event came meanwhile (twice the goal, a record) and has its lines: they come first (T-031)
           !NastyPicker.candidates(catalog, level: level, moment: moment)
               .contains(where: { NastyPicker.precedence($0.event) > NastyPicker.precedence(line.event) }) {
            return (current, NastyPicker.quote(line, values: moment.values, format: format))
        }
        guard let quote = NastyPicker.pick(catalog, level: level, moment: moment, memory: memory, format: format,
                                           using: &rng) else { return nil }
        memory.record(quote.id, level: level)
        return (NastyBubble(id: quote.id, level: level, situations: moment.situations, since: now, heart: false), quote)
    }

    /// A tap on the heart (T-023 §3.4): a line «Se tocchi il cuore» with the numbers of Home.
    public static func heart(catalog: NastyCatalog, level: NastyLevel, moment: NastyMoment, memory: inout NastyMemory,
                             now: Date, format: (Int) -> String = ItalianFormat.integer,
                             using rng: inout some RandomNumberGenerator) -> (bubble: NastyBubble, quote: NastyQuote)? {
        guard level != .normale else { return nil }
        var tap = moment
        tap.situations = [.cuore]
        tap.facts = []
        guard let quote = NastyPicker.pick(catalog, level: level, moment: tap, memory: memory, format: format,
                                           using: &rng) else { return nil }
        memory.record(quote.id, level: level)
        return (NastyBubble(id: quote.id, level: level, situations: moment.situations, since: now, heart: true), quote)
    }
}

/// Anger of the heart (T-023 §3.1): taps within 4 s of each other make it angrier.
public enum NastyRage {
    public static let window: TimeInterval = 4

    /// The taps still counting at `now`.
    public static func recent(_ taps: [Date], now: Date) -> [Date] {
        taps.filter { now.timeIntervalSince($0) < window && now >= $0 }
    }

    /// `k` for the taps of the last 4 s, this one included: 1, then 1.35 at the second and 1.7 from the third.
    public static func k(taps: Int) -> Double { taps >= 3 ? 1.7 : taps == 2 ? 1.35 : 1 }

    /// Angry heartbeat (§3.2) from the second tap.
    public static func angry(taps: Int) -> Bool { taps >= 2 }
}

/// The catalog from NEAT's site (T-022 §4): a public file, the same for everybody, read once a day. Nothing is sent.
public enum NastyDownload {
    /// GitHub Pages of the repository, where `neat/nasty/<lingua>/battute.json` is published with the merge on main.
    public static let site = URL(string: "https://castellanza-alt.github.io/StepTeller/neat/nasty/")!

    public static func url(language: String) -> URL {
        site.appendingPathComponent(language, isDirectory: true).appendingPathComponent("battute.json")
    }

    /// Once a day: never tried, or last tried on another day (or in the future, clock moved back).
    public static func isDue(last: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let last else { return true }
        return last > now || !calendar.isDate(last, inSameDayAs: now)
    }
}
