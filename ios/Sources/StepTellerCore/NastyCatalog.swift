import Foundation

/// NEAT's voice (D-044, D-045): Normale is the app as it was; Piccante and NASTY roast. Chosen in Settings,
/// default Normale. Raw values are what Settings, iCloud and the Backup save.
public enum NastyLevel: String, Codable, CaseIterable, Sendable {
    case normale, piccante, nasty

    /// Name of the level in the catalog (`livello`); Normale has no lines.
    public var catalogName: String? {
        switch self {
        case .normale: nil
        case .piccante: "Piccante"
        case .nasty: "NASTY"
        }
    }

    /// Saved value, or nil when missing or written by a newer app (then the current value stays).
    public static func saved(_ raw: String?) -> NastyLevel? { raw.flatMap(NastyLevel.init(rawValue:)) }
}

/// How many roast notifications a day (Settings: Poche · Normali · Tante). Default Normali.
public enum RoastFrequency: String, Codable, CaseIterable, Sendable {
    case poche, normali, tante

    public static func saved(_ raw: String?) -> RoastFrequency? { raw.flatMap(RoastFrequency.init(rawValue:)) }
}

/// Situations of the catalog (`situazione`), the same for both levels except one: Piccante joins morning,
/// afternoon and evening in «Mattina, pomeriggio, sera».
public enum NastySituation: String, CaseIterable, Sendable {
    case pochiPassi, mattinaPomeriggio, sera, aMetaQuasi, obiettivo, jollySerie, fatto, notifiche, cuore

    public func catalogName(_ level: NastyLevel) -> String {
        switch self {
        case .pochiPassi: "Pochi passi"
        case .mattinaPomeriggio: level == .piccante ? "Mattina, pomeriggio, sera" : "Mattina e pomeriggio"
        case .sera: level == .piccante ? "Mattina, pomeriggio, sera" : "Sera"
        case .aMetaQuasi: "A metà e quasi"
        case .obiettivo: "Obiettivo scelto o cambiato"
        case .jollySerie: "Jolly e serie"
        case .fatto: "Quando ce la fai"
        case .notifiche: "Notifiche"
        case .cuore: "Se tocchi il cuore"
        }
    }

    /// Catalog names a level must have, each with at least one line.
    static func catalogNames(_ level: NastyLevel) -> Set<String> { Set(allCases.map { $0.catalogName(level) }) }
}

/// Facts a line can depend on (`evento`): a line with one is said only when it is true.
public enum NastyEvent: String, CaseIterable, Sendable {
    /// Goal changed: lower or higher than before.
    case abbassato, alzato
    /// A Jolly saved the streak; the last one did (none left, also `jollyUsato`); a Jolly earned.
    case jollyUsato, jollyFiniti, jollyGuadagnato
    /// The streak was lost (`{serie}` is the streak just lost); it goes on; it is at risk tonight.
    case seriePersa, serieInCorso, serieARischio
    /// Goal reached with the best day ever; with at least twice the goal.
    case record, doppio
}

/// Numbers a line can contain. A missing value, or one not above zero, leaves out the lines that need it.
public enum NastyPlaceholder: String, CaseIterable, Sendable {
    case passi, obiettivo, mancano, minuti, serie, jolly, percento

    var token: String { "{\(rawValue)}" }
}

/// A line of the catalog.
public struct NastyLine: Codable, Equatable, Sendable {
    public let id: String
    public let livello: String
    public let situazione: String
    public let testo: String
    /// Title of a notification (situation «Notifiche»).
    public let titolo: String?
    /// Hours it can be said in, local time: «HH:MM-HH:MM», both included.
    public let ore: String?
    /// The event it talks about (`NastyEvent` raw value).
    public let evento: String?

    public init(id: String, livello: String, situazione: String, testo: String, titolo: String? = nil,
                ore: String? = nil, evento: String? = nil) {
        self.id = id; self.livello = livello; self.situazione = situazione; self.testo = testo
        self.titolo = titolo; self.ore = ore; self.evento = evento
    }

    /// Placeholders in title and text.
    public var placeholders: Set<NastyPlaceholder> {
        let all = (titolo ?? "") + " " + testo
        return Set(NastyPlaceholder.allCases.filter { all.contains($0.token) })
    }

    /// Minutes from midnight, first and last (both included). Nil: any time (also when malformed: `check` refuses
    /// a catalog with one, so a line in use never has it).
    public var minutes: ClosedRange<Int>? {
        guard let ore else { return nil }
        let ends = ore.split(separator: "-").map(String.init)
        guard ends.count == 2, let a = Self.minute(ends[0]), let b = Self.minute(ends[1]), a <= b else { return nil }
        return a...b
    }

    public var event: NastyEvent? { evento.flatMap(NastyEvent.init(rawValue:)) }

    /// `"10:30"` → 630.
    static func minute(_ text: String) -> Int? {
        let p = text.split(separator: ":")
        guard p.count == 2, p[0].count == 2, p[1].count == 2, let h = Int(p[0]), let m = Int(p[1]),
              (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        return h * 60 + m
    }
}

/// The catalog of lines of one language (T-022 §4, D-046): the approved one ships inside the app; a downloaded one
/// replaces it only if it passes `check` and is not older (`NastyLibrary`). Pure: reading and checking only, the
/// download is the app's. Every language has the same ids, levels, situations, placeholders, hours and events as
/// the Italian one, which is the reference; a language may lack some lines (they are not said there).
public struct NastyCatalog: Codable, Equatable, Sendable {
    public static let format = "neat-battute"
    public static let currentVersion = 1
    /// Rules of a line (D-045: «massimo 12 parole»).
    public static let maxWords = 12
    public static let maxCharacters = 90
    public static let maxTitleWords = 4
    public static let maxTitleCharacters = 30

    public let formato: String
    public let versione: Int
    /// Date of the content, «AAAA-MM-GG»: a catalog replaces another only with an equal or later one.
    public let edizione: String
    public let lingua: String
    public let battute: [NastyLine]

    public init(formato: String = NastyCatalog.format, versione: Int = NastyCatalog.currentVersion, edizione: String,
                lingua: String = "it", battute: [NastyLine]) {
        self.formato = formato; self.versione = versione; self.edizione = edizione; self.lingua = lingua
        self.battute = battute
    }

    /// Reads and checks a catalog file; `reference`: the Italian catalog, for the other languages.
    public static func read(_ data: Data, reference: NastyCatalog? = nil) throws -> NastyCatalog {
        guard let catalog = try? JSONDecoder().decode(NastyCatalog.self, from: data) else {
            throw Problem.notACatalog
        }
        let problems = catalog.check(reference: reference)
        if let first = problems.first { throw first }
        return catalog
    }

    /// Lines of a level and situation.
    public func lines(_ level: NastyLevel, _ situation: NastySituation) -> [NastyLine] {
        guard let name = level.catalogName else { return [] }
        let sit = situation.catalogName(level)
        return battute.filter { $0.livello == name && $0.situazione == sit }
    }

    // MARK: check

    public enum Problem: Error, Equatable, Sendable {
        case notACatalog
        case wrongFormat(String)
        case newerVersion(Int)
        case badVersion(Int)
        case badEdition(String)
        case unknownLanguage(String)
        case empty
        case duplicateID(String)
        case badID(String)
        case unknownLevel(id: String, String)
        case unknownSituation(id: String, String)
        case missingSituation(level: String, String)
        case emptyText(String)
        case tooLong(String)
        case badTitle(String)
        case unknownPlaceholder(id: String, String)
        case badHours(String)
        case unknownEvent(id: String, String)
        /// Another language: an id the Italian catalog does not have.
        case unknownID(String)
        /// Another language: the line differs from the Italian one in level, situation, placeholders, title, hours or event.
        case differsFromReference(String)
    }

    /// Everything wrong with the catalog (empty: good). `reference`: the Italian catalog, when this is another language.
    public func check(reference: NastyCatalog? = nil) -> [Problem] {
        var out: [Problem] = []
        if formato != Self.format { out.append(.wrongFormat(formato)) }
        if versione > Self.currentVersion { out.append(.newerVersion(versione)) }
        if versione < 1 { out.append(.badVersion(versione)) }
        if !Self.isDay(edizione) { out.append(.badEdition(edizione)) }
        if !NastyLibrary.languages.contains(lingua) { out.append(.unknownLanguage(lingua)) }
        if battute.isEmpty { out.append(.empty) }
        var seen = Set<String>()
        let levels = NastyLevel.allCases.filter { $0.catalogName != nil }
        for line in battute {
            if !seen.insert(line.id).inserted { out.append(.duplicateID(line.id)) }
            if line.id.isEmpty || line.id.count > 12 || !line.id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) {
                out.append(.badID(line.id))
            }
            guard let level = levels.first(where: { $0.catalogName == line.livello }) else {
                out.append(.unknownLevel(id: line.id, line.livello))
                continue
            }
            if !NastySituation.catalogNames(level).contains(line.situazione) {
                out.append(.unknownSituation(id: line.id, line.situazione))
            }
            let text = line.testo.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { out.append(.emptyText(line.id)) }
            if Self.words(line.testo) > Self.maxWords || line.testo.count > Self.maxCharacters { out.append(.tooLong(line.id)) }
            if let title = line.titolo {
                if title.trimmingCharacters(in: .whitespaces).isEmpty || Self.words(title) > Self.maxTitleWords
                    || title.count > Self.maxTitleCharacters { out.append(.badTitle(line.id)) }
            }
            for bad in Self.badPlaceholders((line.titolo ?? "") + " " + line.testo) {
                out.append(.unknownPlaceholder(id: line.id, bad))
            }
            if line.ore != nil, line.minutes == nil { out.append(.badHours(line.id)) }
            if let e = line.evento, NastyEvent(rawValue: e) == nil { out.append(.unknownEvent(id: line.id, e)) }
            if let reference, reference.lingua != lingua {
                if let it = reference.battute.first(where: { $0.id == line.id }) {
                    if it.livello != line.livello || it.situazione != line.situazione || it.placeholders != line.placeholders
                        || (it.titolo == nil) != (line.titolo == nil) || it.ore != line.ore || it.evento != line.evento {
                        out.append(.differsFromReference(line.id))
                    }
                } else {
                    out.append(.unknownID(line.id))
                }
            }
        }
        for level in levels {
            let name = level.catalogName ?? ""
            for sit in NastySituation.catalogNames(level).sorted()
            where !battute.contains(where: { $0.livello == name && $0.situazione == sit }) {
                out.append(.missingSituation(level: name, sit))
            }
        }
        return out
    }

    static func words(_ text: String) -> Int {
        text.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
    }

    /// Braces that are not one of the allowed placeholders (also a lone `{` or `}`).
    static func badPlaceholders(_ text: String) -> [String] {
        var out: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(where: { $0 == "{" || $0 == "}" }) {
            if rest[open] == "}" { out.append("}"); rest = rest[rest.index(after: open)...]; continue }
            guard let close = rest[open...].firstIndex(of: "}") else { out.append(String(rest[open...])); break }
            let token = String(rest[open...close])
            if NastyPlaceholder.allCases.first(where: { $0.token == token }) == nil { out.append(token) }
            rest = rest[rest.index(after: close)...]
        }
        return out
    }

    /// «AAAA-MM-GG», a real month and day (an edition like «9999-99-99» would block every later catalog).
    static func isDay(_ text: String) -> Bool {
        let p = text.split(separator: "-", omittingEmptySubsequences: false)
        guard p.count == 3, p[0].count == 4, p[1].count == 2, p[2].count == 2,
              p.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let y = Int(p[0]), let m = Int(p[1]), let d = Int(p[2]) else { return false }
        return (2026...2100).contains(y) && (1...12).contains(m) && (1...31).contains(d)
    }
}

/// The catalogs of every language (D-046). A language without a valid catalog does not offer Piccante and NASTY;
/// a line missing in a language is not said there (never the Italian one instead).
public struct NastyLibrary: Equatable, Sendable {
    /// Languages of the app, as the catalogs name them (`lingua`).
    public static let languages: Set<String> = ["it", "en", "de", "fr", "es", "pt-BR", "ja", "ko", "zh-Hans", "zh-Hant"]
    /// The reference language: the others are checked against it.
    public static let reference = "it"

    public private(set) var catalogs: [String: NastyCatalog]

    public init(catalogs: [String: NastyCatalog]) { self.catalogs = catalogs }

    /// The catalogs inside the app (generated by `scripts/battute.py`): the ones that pass `check` (a test checks
    /// they all do).
    public static let onBoard: NastyLibrary = {
        var library = NastyLibrary(catalogs: [:])
        for code in onBoardJSON.keys.sorted(by: { ($0 != reference ? 1 : 0, $0) < ($1 != reference ? 1 : 0, $1) }) {
            library = library.replaced(by: Data(onBoardJSON[code]!.utf8))
        }
        return library
    }()

    /// The catalog for a language of the phone: the same code, or the code without its last parts
    /// (`it-CH` → `it`, `zh-Hans-CN` → `zh-Hans`). Nil: none.
    public func catalog(language: String) -> NastyCatalog? {
        var parts = language.replacingOccurrences(of: "_", with: "-").split(separator: "-").map(String.init)
        while !parts.isEmpty {
            let code = parts.joined(separator: "-")
            if let c = catalogs.first(where: { $0.key.lowercased() == code.lowercased() })?.value { return c }
            parts.removeLast()
        }
        return nil
    }

    /// Levels offered in a language: Piccante and NASTY only with a valid catalog. Without one the Voice section
    /// does not show and the app speaks Normale.
    public func levels(language: String) -> [NastyLevel] {
        catalog(language: language) == nil ? [.normale] : NastyLevel.allCases
    }

    /// The level the app uses: the saved one if the language has it, otherwise Normale (the saved choice stays, so
    /// it comes back with a language that has it).
    public func effective(_ level: NastyLevel, language: String) -> NastyLevel {
        levels(language: language).contains(level) ? level : .normale
    }

    /// A downloaded file (any language): it replaces that language's catalog if it is valid (against the Italian one
    /// for the other languages) and not older; otherwise nothing changes. A refused file never replaces a good one.
    public func replaced(by data: Data?) -> NastyLibrary {
        guard let data, let head = try? JSONDecoder().decode(NastyCatalog.self, from: data) else { return self }
        let reference = head.lingua == Self.reference ? nil : catalogs[Self.reference]
        if head.lingua != Self.reference, reference == nil { return self }
        guard let new = try? NastyCatalog.read(data, reference: reference) else { return self }
        if let old = catalogs[new.lingua], new.edizione < old.edizione { return self }
        var out = self
        out.catalogs[new.lingua] = new
        return out
    }
}
