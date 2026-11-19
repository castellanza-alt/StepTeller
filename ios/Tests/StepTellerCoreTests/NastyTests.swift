import Foundation
import XCTest
@testable import StepTellerCore

/// NASTY core (T-024): catalog and its check, situations, choice of the line, roast notifications, settings.
final class NastyCatalogTests: XCTestCase {
    static let ios = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()
    static let it = NastyLibrary.onBoard.catalogs["it"]!

    func testOnBoardCatalogIsTheApprovedOne() throws {
        let c = Self.it
        XCTAssertEqual(c.check(), [])
        XCTAssertEqual(c.battute.count, 196)
        XCTAssertEqual(c.battute.filter { $0.livello == "NASTY" }.count, 137)
        XCTAssertEqual(c.battute.filter { $0.livello == "Piccante" }.count, 59)
        XCTAssertEqual(c.lingua, "it")
        // every language shipped passes its check (none dropped by `onBoard`)
        XCTAssertEqual(Set(NastyLibrary.onBoard.catalogs.keys), Set(NastyLibrary.onBoardJSON.keys))
        for (code, c) in NastyLibrary.onBoard.catalogs {
            XCTAssertEqual(c.check(reference: code == "it" ? nil : Self.it), [], code)
        }
    }

    /// The approved catalogs, the ones inside the app and the ones for the site say the same thing
    /// (regenerate with `python3 scripts/battute.py`).
    func testFilesAreAligned() throws {
        struct Approved: Decodable { let id, livello, situazione, testo: String }
        let folder = Self.ios.appendingPathComponent("docs/design/T-021-nasty/catalogo")
        for (code, json) in NastyLibrary.onBoardJSON {
            let site = try String(contentsOf: Self.ios.appendingPathComponent("../neat/nasty/\(code)/battute.json"), encoding: .utf8)
            XCTAssertEqual(site, json + "\n", "neat/nasty/\(code)/battute.json non è il catalogo di bordo")
            let name = code == "it" ? "catalogo-approvato.json" : "lingue/\(code).json"
            let approved = try JSONDecoder().decode([Approved].self, from: Data(contentsOf: folder.appendingPathComponent(name)))
            guard let lines = NastyLibrary.onBoard.catalogs[code]?.battute else {
                XCTFail("\(code): catalogo di bordo rifiutato dal controllo"); continue
            }
            XCTAssertEqual(approved.map(\.id), lines.map(\.id), code)
            for (a, b) in zip(approved, lines) {
                XCTAssertEqual(a.livello, b.livello, a.id)
                XCTAssertEqual(a.situazione, b.situazione, a.id)
                XCTAssertEqual(a.testo, b.titolo.map { "\($0) / \(b.testo)" } ?? b.testo, a.id)
            }
        }
        // the hours and events of vincoli.json, the same in every language
        struct Rules: Decodable { let ore: [String: String]; let evento: [String: String] }
        let rules = try JSONDecoder().decode(Rules.self, from: Data(contentsOf: folder.appendingPathComponent("vincoli.json")))
        for c in NastyLibrary.onBoard.catalogs.values {
            for line in c.battute {
                XCTAssertEqual(line.ore, rules.ore[line.id], line.id)
                XCTAssertEqual(line.evento, rules.evento[line.id], line.id)
            }
        }
    }

    /// A line that names an hour or an event has the matching constraint in vincoli.json: a new line cannot slip
    /// through (Director, T-024).
    func testLinesNamingAnHourOrAnEventCarryIt() {
        func has(_ text: String, _ pattern: String) -> Bool {
            text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
        for line in Self.it.battute {
            let text = (line.titolo ?? "") + " / " + line.testo
            if has(text, #"\b(sono le|ore) \d{1,2}\b"#) || has(text, #"\bmezzogiorno\b"#) || has(text, #"\bultima ora\b"#) {
                XCTAssertNotNil(line.minutes, "\(line.id) nomina un'ora senza «ore»: \(text)")
            }
            for (match, hour) in (0...23).map({ (#"\b(sono le|ore) \#($0)\b"#, $0) }) + [(#"\bmezzogiorno\b"#, 12)]
            where has(text, match) {
                XCTAssertTrue(line.minutes?.contains(hour * 60) ?? false, "\(line.id): \(text)")
            }
            if has(text, #"\bultima ora\b"#) { XCTAssertEqual(line.ore, "19:00-19:59", line.id) }
            let words: [(String, Set<NastyEvent>)] = [
                // «alzati» (get up) and «il doppio» (twice as much) are not events: the goal raised, «doppio dell'obiettivo» are
                (#"\babbassat[oa]\b"#, [.abbassato]), (#"\balzat[oa]\b"#, [.alzato]), (#"\brecord\b"#, [.record]),
                (#"\bdoppio d"#, [.doppio]), (#"\bgiorno uno\b"#, [.seriePersa]),
                (#"\bjolly\b"#, [.jollyUsato, .jollyFiniti, .jollyGuadagnato]),
                (#"\bserie\b"#, [.seriePersa, .serieInCorso, .serieARischio]),
                (#"\{serie\}"#, [.seriePersa, .serieInCorso, .serieARischio]),
            ]
            for (word, events) in words where has(text, word) {
                XCTAssertTrue(line.event.map(events.contains) ?? false, "\(line.id) parla di un evento senza «evento»: \(text)")
            }
        }
        // the notifications are the only lines with a title
        for line in Self.it.battute {
            XCTAssertEqual(line.titolo != nil, line.situazione == "Notifiche", line.id)
        }
    }

    // MARK: check

    private func line(id: String = "X001", level: String = "NASTY", situation: String = "Pochi passi",
                      text: String = "{passi} passi. Muoviti.", title: String? = nil, ore: String? = nil,
                      evento: String? = nil) -> NastyLine {
        NastyLine(id: id, livello: level, situazione: situation, testo: text, titolo: title, ore: ore, evento: evento)
    }

    /// The on-board catalog with some lines added or changed.
    private func catalog(_ extra: [NastyLine] = [], formato: String = NastyCatalog.format, versione: Int = 1,
                         edizione: String = "2026-11-19", lingua: String = "it") -> NastyCatalog {
        NastyCatalog(formato: formato, versione: versione, edizione: edizione, lingua: lingua,
                     battute: Self.it.battute + extra)
    }

    func testCheckRefusesEveryKindOfMistake() {
        XCTAssertEqual(catalog([line()]).check(), [])
        XCTAssertEqual(catalog(formato: "altro").check(), [.wrongFormat("altro")])
        XCTAssertEqual(catalog(versione: 2).check(), [.newerVersion(2)])
        XCTAssertEqual(catalog(versione: 0).check(), [.badVersion(0)])
        for bad in ["19/11/2026", "9999-99-99", "2026-13-01", "2026-+1-01", "2026-11-1"] {
            XCTAssertEqual(catalog(edizione: bad).check(), [.badEdition(bad)], bad)
        }
        XCTAssertEqual(catalog(lingua: "xx").check(), [.unknownLanguage("xx")])
        XCTAssertEqual(catalog([line(id: "N001")]).check(), [.duplicateID("N001")])
        XCTAssertEqual(catalog([line(id: "X 1")]).check(), [.badID("X 1")])
        XCTAssertEqual(catalog([line(level: "Normale")]).check(), [.unknownLevel(id: "X001", "Normale")])
        XCTAssertEqual(catalog([line(level: "Piccante", situation: "Sera")]).check(), [.unknownSituation(id: "X001", "Sera")])
        XCTAssertEqual(catalog([line(text: " ")]).check(), [.emptyText("X001")])
        XCTAssertEqual(catalog([line(text: "uno due tre quattro cinque sei sette otto nove dieci undici dodici tredici")]).check(),
                       [.tooLong("X001")])
        XCTAssertEqual(catalog([line(text: String(repeating: "a", count: 91))]).check(), [.tooLong("X001")])
        XCTAssertEqual(catalog([line(title: "uno due tre quattro cinque")]).check(), [.badTitle("X001")])
        XCTAssertEqual(catalog([line(text: "{passo} passi.")]).check(), [.unknownPlaceholder(id: "X001", "{passo}")])
        XCTAssertEqual(catalog([line(text: "{passi passi.")]).check(), [.unknownPlaceholder(id: "X001", "{passi passi.")])
        XCTAssertEqual(catalog([line(text: "passi} passi.")]).check(), [.unknownPlaceholder(id: "X001", "}")])
        XCTAssertEqual(catalog([line(title: "{nome}")]).check(), [.unknownPlaceholder(id: "X001", "{nome}")])
        XCTAssertEqual(catalog([line(ore: "11-12")]).check(), [.badHours("X001")])
        XCTAssertEqual(catalog([line(ore: "12:00-11:00")]).check(), [.badHours("X001")])
        XCTAssertEqual(catalog([line(ore: "24:00-24:30")]).check(), [.badHours("X001")])
        XCTAssertEqual(catalog([line(evento: "compleanno")]).check(), [.unknownEvent(id: "X001", "compleanno")])
        let noHeart = NastyCatalog(edizione: "2026-11-19", battute: Self.it.battute.filter {
            !($0.livello == "Piccante" && $0.situazione == "Se tocchi il cuore")
        })
        XCTAssertEqual(noHeart.check(), [.missingSituation(level: "Piccante", "Se tocchi il cuore")])
        XCTAssertEqual(NastyCatalog(edizione: "2026-11-19", battute: []).check().first, .empty)
    }

    func testAllowedPlaceholdersPass() {
        let text = "{passi} {obiettivo} {mancano} {minuti} {serie} {jolly} {percento}%"
        XCTAssertEqual(NastyCatalog.badPlaceholders(text), [])
        XCTAssertEqual(line(text: text).placeholders, Set(NastyPlaceholder.allCases))
    }

    private func encoded(_ c: NastyCatalog) -> Data { try! JSONEncoder().encode(c) }

    /// A made-up English catalog: the Italian one with other words, same placeholders.
    private func english(_ change: (inout [NastyLine]) -> Void = { _ in }, edizione: String = "2026-11-20") -> NastyCatalog {
        var lines = Self.it.battute.map { l in
            NastyLine(id: l.id, livello: l.livello, situazione: l.situazione,
                      testo: "EN " + NastyPlaceholder.allCases.filter { l.testo.contains($0.token) }.map(\.token).joined(separator: " "),
                      titolo: l.titolo.map { _ in "Hey" }, ore: l.ore, evento: l.evento)
        }
        change(&lines)
        return NastyCatalog(edizione: edizione, lingua: "en", battute: lines)
    }

    /// A refused or older file never replaces the good one.
    func testReplacement() {
        let good = NastyLibrary.onBoard
        XCTAssertEqual(good.replaced(by: nil), good)
        XCTAssertEqual(good.replaced(by: Data("non è json".utf8)), good)
        XCTAssertEqual(good.replaced(by: Data("{\"formato\":\"neat-battute\"}".utf8)), good)
        XCTAssertEqual(good.replaced(by: encoded(catalog([line(text: "{nome}")], edizione: "2026-12-01"))), good)
        XCTAssertEqual(good.replaced(by: encoded(catalog([line()], versione: 2, edizione: "2026-12-01"))), good)
        XCTAssertEqual(good.replaced(by: encoded(catalog([line()], edizione: "2026-11-01"))), good)
        let newer = catalog([line()], edizione: "2026-12-01")
        XCTAssertEqual(good.replaced(by: encoded(newer)).catalogs["it"], newer)
        XCTAssertEqual(good.replaced(by: encoded(catalog([line()], edizione: "2026-11-19"))).catalogs["it"]?.battute.count, 197)
        // unknown fields of a later format revision are ignored
        let extra = String(decoding: encoded(newer), as: UTF8.self).replacingOccurrences(of: "\"lingua\"", with: "\"nuovo\":true,\"lingua\"")
        XCTAssertEqual(good.replaced(by: Data(extra.utf8)).catalogs["it"], newer)
    }

    func testReadThrowsTheFirstProblem() {
        XCTAssertThrowsError(try NastyCatalog.read(Data("[]".utf8))) { XCTAssertEqual($0 as? NastyCatalog.Problem, .notACatalog) }
        XCTAssertThrowsError(try NastyCatalog.read(encoded(catalog(versione: 9)))) {
            XCTAssertEqual($0 as? NastyCatalog.Problem, .newerVersion(9))
        }
        XCTAssertNoThrow(try NastyCatalog.read(Data(NastyLibrary.onBoardJSON["it"]!.utf8)))
    }

    // MARK: languages (D-046)

    func testOtherLanguagesAgainstTheItalianOne() {
        let en = english()
        XCTAssertEqual(en.check(reference: Self.it), [])
        // fewer lines: allowed (they are not said in English)
        XCTAssertEqual(english({ $0.removeAll { $0.id == "N001" } }).check(reference: Self.it), [])
        // an id Italian does not have, other placeholders, title, hours, event, level or situation: refused
        XCTAssertEqual(english({ $0.append(self.line(id: "Z999")) }).check(reference: Self.it), [.unknownID("Z999")])
        func changed(_ id: String, _ make: (NastyLine) -> NastyLine) -> [NastyCatalog.Problem] {
            english({ lines in
                let i = lines.firstIndex { $0.id == id }!
                lines[i] = make(lines[i])
            }).check(reference: Self.it)
        }
        func copy(_ l: NastyLine, testo: String? = nil, titolo: String?? = nil, ore: String?? = nil, evento: String?? = nil,
                  situazione: String? = nil) -> NastyLine {
            NastyLine(id: l.id, livello: l.livello, situazione: situazione ?? l.situazione, testo: testo ?? l.testo,
                      titolo: titolo ?? l.titolo, ore: ore ?? l.ore, evento: evento ?? l.evento)
        }
        XCTAssertEqual(changed("N001") { copy($0, testo: "EN {obiettivo}") }, [.differsFromReference("N001")])
        XCTAssertEqual(changed("N001") { copy($0, testo: "EN no number") }, [.differsFromReference("N001")])
        XCTAssertEqual(changed("N125") { copy($0, titolo: .some(nil)) }, [.differsFromReference("N125")])
        XCTAssertEqual(changed("N046") { copy($0, ore: .some(nil)) }, [.differsFromReference("N046")])
        XCTAssertEqual(changed("N080") { copy($0, evento: "alzato") }, [.differsFromReference("N080")])
        XCTAssertEqual(changed("N001") { copy($0, situazione: "Sera") }, [.differsFromReference("N001")])
        XCTAssertEqual(changed("N001") { copy($0, testo: "{passi} one two three four five six seven eight nine ten eleven twelve") },
                       [.tooLong("N001")])
    }

    func testLibraryLanguages() {
        let onBoard = NastyLibrary.onBoard
        XCTAssertEqual(onBoard.levels(language: "it"), [.normale, .piccante, .nasty])
        XCTAssertEqual(onBoard.levels(language: "it-CH"), [.normale, .piccante, .nasty])
        XCTAssertEqual(onBoard.levels(language: "it_IT"), [.normale, .piccante, .nasty])
        XCTAssertEqual(onBoard.levels(language: "xx"), [.normale])
        XCTAssertEqual(onBoard.effective(.nasty, language: "it"), .nasty)
        XCTAssertEqual(onBoard.effective(.nasty, language: "xx"), .normale)
        // the app ships all 10 languages (D-046, T-025)
        XCTAssertEqual(Set(onBoard.catalogs.keys), NastyLibrary.languages)
        XCTAssertEqual(onBoard.levels(language: "pt-BR"), [.normale, .piccante, .nasty])
        // an English catalog arrives in a library with Italian only: English offers the levels, Italian keeps its own
        let withEnglish = NastyLibrary(catalogs: ["it": Self.it]).replaced(by: encoded(english()))
        XCTAssertEqual(withEnglish.levels(language: "en-GB"), [.normale, .piccante, .nasty])
        XCTAssertEqual(withEnglish.catalog(language: "en")?.lingua, "en")
        XCTAssertEqual(withEnglish.catalog(language: "it")?.lingua, "it")
        XCTAssertNil(withEnglish.catalog(language: "de"))
        XCTAssertEqual(withEnglish.effective(.piccante, language: "de"), .normale)
        // refused or older English: nothing changes
        XCTAssertEqual(withEnglish.replaced(by: encoded(english({ $0.append(self.line(id: "Z999")) }, edizione: "2026-12-01"))),
                       withEnglish)
        XCTAssertEqual(withEnglish.replaced(by: encoded(english(edizione: "2026-11-01"))), withEnglish)
        // no Italian reference: another language cannot be checked, so it is not taken
        XCTAssertEqual(NastyLibrary(catalogs: [:]).replaced(by: encoded(english())), NastyLibrary(catalogs: [:]))
        // Chinese: the script decides, not the first part
        let zh = NastyLibrary(catalogs: ["it": Self.it, "zh-Hans": NastyCatalog(edizione: "2026-11-19", lingua: "zh-Hans", battute: [])])
        XCTAssertEqual(zh.catalog(language: "zh-Hans-CN")?.lingua, "zh-Hans")
        XCTAssertNil(zh.catalog(language: "zh-Hant-TW"))
        XCTAssertEqual(NastyLibrary.languages.count, 10)
    }

    /// A line missing in a language is not said there; never the Italian one instead.
    func testMissingLineIsNotSaid() {
        let en = english({ $0.removeAll { $0.situazione == "Se tocchi il cuore" && $0.livello == "NASTY" && $0.id != "N141" } })
        var rng = SeededRandom(seed: 1)
        let tap = NastyMoment.of(.heart, day: NastyMoment.Day(steps: 100, goal: 1_000, minutesLeft: 9, streak: 1, jolly: 0, minuteOfDay: 600))
        for _ in 0..<20 {
            XCTAssertEqual(NastyPicker.pick(en, level: .nasty, moment: tap, memory: NastyMemory(), using: &rng)?.id, "N141")
        }
    }

    // MARK: settings

    func testSavedValues() {
        XCTAssertEqual(NastyLevel.saved("nasty"), .nasty)
        XCTAssertNil(NastyLevel.saved("diabolico"))
        XCTAssertNil(NastyLevel.saved(nil))
        // words have a letter or a digit: the French « ? » is not one
        XCTAssertEqual(NastyCatalog.words("Toujours sur le canapé ?"), 4)
        XCTAssertEqual(NastyCatalog.words("3 200 pas — bravo !"), 4)
        // D-047: without a saved value (new install, update from 1.2) the voice is Senza pietà
        XCTAssertEqual(NastyLevel.standard, .nasty)
        XCTAssertEqual(NastyLevel.saved(nil) ?? .standard, .nasty)
        XCTAssertEqual(RoastFrequency.saved("tante"), .tante)
        XCTAssertNil(RoastFrequency.saved("sempre"))
        XCTAssertEqual(NastyLevel.normale.catalogName, nil)
    }

    /// The Backup of the 1.2 (no voice) still reads; the new fields travel.
    func testBackupFields() throws {
        let old = """
        {"format":"neat-backup","version":1,"exportedAt":"2026-11-10T10:00:00Z","goal":8000,"eventNotificationsOn":true}
        """
        let file = try BackupFile.decode(Data(old.utf8))
        XCTAssertNil(file.voiceLevel)
        XCTAssertNil(file.roastFrequency)
        XCTAssertEqual(file.goal, 8000)
        var new = BackupFile(exportedAt: Date(timeIntervalSince1970: 1_800_000_000))
        new.voiceLevel = NastyLevel.piccante.rawValue
        new.roastFrequency = RoastFrequency.poche.rawValue
        let back = try BackupFile.decode(new.encoded())
        XCTAssertEqual(back, new)
        XCTAssertEqual(NastyLevel.saved(back.voiceLevel), .piccante)
        XCTAssertEqual(RoastFrequency.saved(back.roastFrequency), .poche)
    }
}

final class NastyChoiceTests: XCTestCase {
    let catalog = NastyLibrary.onBoard.catalogs["it"]!

    private func day(_ steps: Int, goal: Int = 10_000, at hour: Int = 15, minute: Int = 0, streak: Int = 12,
                     jolly: Int = 2, record: Bool = false) -> NastyMoment.Day {
        NastyMoment.Day(steps: steps, goal: goal, minutesLeft: max(0, goal - steps) / 110, streak: streak, jolly: jolly,
                        isRecord: record, minuteOfDay: hour * 60 + minute)
    }

    // MARK: T-031

    /// Record and twice the goal win over the generic «Quando ce la fai», the record first.
    func testEventLinesComeFirst() {
        for (record, event) in [(true, NastyEvent.record), (false, .doppio)] {
            let moment = NastyMoment.of(.home, day: day(25_000, record: record))
            for level in [NastyLevel.nasty, .piccante] {
                // as many as the event's lines: each one once, then (seen) the next tier
                let count = catalog.battute.filter { $0.livello == level.catalogName && $0.event == event }.count
                var memory = NastyMemory()
                for seed in 0..<count {
                    var rng = SeededRandom(seed: UInt64(seed))
                    let quote = NastyPicker.pick(catalog, level: level, moment: moment, memory: memory, using: &rng)!
                    let line = catalog.battute.first { $0.id == quote.id }!
                    XCTAssertEqual(line.event, event, "\(level) \(quote.text)")
                    memory.record(quote.id, level: level)
                }
            }
        }
        // the event lines all seen recently: a fresh generic line rather than a repeat
        let moment = NastyMoment.of(.home, day: day(25_000))
        var memory = NastyMemory()
        for line in catalog.battute where line.livello == "NASTY" && line.event == .doppio { memory.record(line.id, level: .nasty) }
        var rng = SeededRandom(seed: 1)
        let quote = NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: memory, using: &rng)!
        XCTAssertNil(catalog.battute.first { $0.id == quote.id }!.event)
        XCTAssertEqual(NastyPicker.precedence(.record), 4)
        XCTAssertGreaterThan(NastyPicker.precedence(.doppio), NastyPicker.precedence(.jollyUsato))
        XCTAssertEqual(NastyPicker.precedence(nil), 0)
    }

    /// The pop-up never repeats its title nor the number of its tag; the reminder never its minutes and numbers.
    func testNoRepetitionOfThePlace() {
        XCTAssertEqual(NastyPicker.plain("JOLLY GUADAGNATO!"), "jolly guadagnato")
        XCTAssertEqual(NastyPicker.plain("Già fatto: perché?"), "gia fatto perche")
        for (trigger, title) in [(NastyMoment.Trigger.jollyEarned, "JOLLY GUADAGNATO!"), (.jollyUsed, "JOLLY USATO")] {
            let moment = NastyMoment.of(trigger, day: day(3_000, jolly: 3))
            for level in [NastyLevel.nasty, .piccante] {
                let said = Set((0..<60).compactMap { seed -> String? in
                    var rng = SeededRandom(seed: UInt64(seed))
                    return NastyPicker.pick(catalog, level: level, moment: moment, memory: NastyMemory(),
                                            excluding: [.jolly, .serie], notSaying: [title], using: &rng)?.id
                })
                // today's catalog: only «Jolly usato» in Senza pietà keeps lines (N092, N098); the others all repeat
                // title or tag, so those pop-ups keep their own sentence
                XCTAssertEqual(!said.isEmpty, trigger == .jollyUsed && level == .nasty, "\(level) \(title)")
                for id in said {
                    let line = catalog.battute.first { $0.id == id }!
                    XCTAssertTrue(line.placeholders.isDisjoint(with: [.jolly, .serie]), id)
                    XCTAssertFalse(NastyPicker.plain(line.testo).contains(NastyPicker.plain(title)), id)
                }
            }
        }
        // the ones the place repeats exist: without the rule they could come out
        XCTAssertTrue(catalog.battute.contains { NastyPicker.plain($0.testo).hasPrefix("jolly guadagnato") })
        // nothing left: nil, and the place keeps its own text
        var rng = SeededRandom(seed: 2)
        XCTAssertNil(NastyPicker.pick(catalog, level: .nasty, moment: NastyMoment.of(.jollyEarned, day: day(3_000)),
                                      memory: NastyMemory(), notSaying: ["a", "e", "i", "o", "u"], using: &rng))
    }

    /// Translations reword the title: the lines that repeat it are found on Italian and left out by id everywhere.
    func testTitleRepeatsLeftOutInEveryLanguage() {
        let earned = NastyPicker.repeating(["JOLLY GUADAGNATO!"], in: catalog)
        let used = NastyPicker.repeating(["JOLLY USATO"], in: catalog)
        XCTAssertTrue(earned.isSuperset(of: ["N099", "P039"]))
        XCTAssertTrue(used.isSuperset(of: ["N096", "P037"]))
        for (code, other) in NastyLibrary.onBoard.catalogs {
            for (trigger, ids) in [(NastyMoment.Trigger.jollyEarned, earned), (.jollyUsed, used)] {
                let moment = NastyMoment.of(trigger, day: day(3_000, jolly: 3))
                for seed in 0..<40 {
                    var rng = SeededRandom(seed: UInt64(seed))
                    if let q = NastyPicker.pick(other, level: .nasty, moment: moment, memory: NastyMemory(),
                                                excludingIDs: ids, using: &rng) {
                        XCTAssertFalse(ids.contains(q.id), "\(code) \(q.id)")
                    }
                }
            }
        }
    }

    // MARK: situations

    func testHomeSituations() {
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, at: 9)).situations, [.pochiPassi])
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, at: 10, minute: 59)).situations, [.pochiPassi])
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, at: 11)).situations, [.pochiPassi, .mattinaPomeriggio])
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, at: 17, minute: 59)).situations, [.pochiPassi, .mattinaPomeriggio])
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, at: 18)).situations, [.pochiPassi, .sera])
        XCTAssertEqual(NastyMoment.of(.home, day: day(4_999)).situations, [.pochiPassi, .mattinaPomeriggio])
        XCTAssertEqual(NastyMoment.of(.home, day: day(5_000)).situations, [.aMetaQuasi])
        XCTAssertEqual(NastyMoment.of(.home, day: day(9_999, at: 21)).situations, [.aMetaQuasi])
        XCTAssertEqual(NastyMoment.of(.home, day: day(10_000)).situations, [.fatto])
        XCTAssertEqual(NastyMoment.of(.home, day: day(10_000)).facts, [])
        XCTAssertEqual(NastyMoment.of(.home, day: day(12_000, record: true)).facts, [.record])
        XCTAssertEqual(NastyMoment.of(.home, day: day(20_000, record: true)).facts, [.record, .doppio])
        // no goal: never «done», nothing to divide
        XCTAssertEqual(NastyMoment.of(.home, day: day(3_000, goal: 0, at: 9)).situations, [.pochiPassi])
    }

    func testEventSituations() {
        XCTAssertEqual(NastyMoment.of(.heart, day: day(100)).situations, [.cuore])
        XCTAssertEqual(NastyMoment.of(.goalChanged(old: nil), day: day(0)).facts, [])
        XCTAssertEqual(NastyMoment.of(.goalChanged(old: 12_000), day: day(0)).facts, [.abbassato])
        XCTAssertEqual(NastyMoment.of(.goalChanged(old: 8_000), day: day(0)).facts, [.alzato])
        XCTAssertEqual(NastyMoment.of(.goalChanged(old: 10_000), day: day(0)).facts, [])
        XCTAssertEqual(NastyMoment.of(.jollyUsed, day: day(0, jolly: 1)).facts, [.jollyUsato])
        XCTAssertEqual(NastyMoment.of(.jollyUsed, day: day(0, jolly: 0)).facts, [.jollyUsato, .jollyFiniti])
        XCTAssertEqual(NastyMoment.of(.jollyEarned, day: day(0)).facts, [.jollyGuadagnato])
        let lost = NastyMoment.of(.streakLost(lost: 23), day: day(0, streak: 0))
        XCTAssertEqual(lost.facts, [.seriePersa])
        XCTAssertEqual(lost.values.serie, 23)
        XCTAssertEqual(NastyMoment.of(.streakAtRisk, day: day(3_000, at: 19)).situations, [.jollySerie])
        XCTAssertEqual(NastyMoment.of(.streakAtRisk, day: day(10_000, at: 19)).situations, [])
        XCTAssertEqual(NastyMoment.of(.notification, day: day(3_000)).situations, [.notifiche])
        XCTAssertEqual(NastyMoment.of(.notification, day: day(10_000)).situations, [])
    }

    func testValuesNeverZeroSteps() {
        XCTAssertNil(NastyValues(passi: 0)[.passi])
        XCTAssertNil(NastyValues(passi: 49)[.passi])
        XCTAssertEqual(NastyValues(passi: 50)[.passi], 50)
        XCTAssertNil(NastyValues(jolly: 0)[.jolly])
        XCTAssertNil(NastyValues(percento: 0)[.percento])
        XCTAssertNil(NastyValues(serie: -1)[.serie])
        XCTAssertEqual(day(3_456).percent, 34)
        XCTAssertNil(NastyMoment.of(.home, day: day(10_000)).values[.mancano])
    }

    // MARK: choice

    /// Every moment of a day, every level: no line shows an unfilled placeholder, a number below 50 steps, an hour
    /// it does not fit or an event that did not happen.
    func testNoChoiceBreaksTheRules() {
        var rng = SeededRandom(seed: 7)
        let triggers: [NastyMoment.Trigger] = [.home, .heart, .notification, .goalChanged(old: nil), .goalChanged(old: 15_000),
                                               .goalChanged(old: 5_000), .jollyUsed, .jollyEarned, .streakLost(lost: 9),
                                               .streakGoing, .streakAtRisk]
        var said = Set<String>()
        for level in [NastyLevel.piccante, .nasty] {
            for steps in [0, 1, 49, 50, 51, 2_345, 5_000, 9_999, 10_000, 25_000] {
                for hour in 0..<24 {
                    for jolly in [0, 3] {
                        for trigger in triggers {
                            let moment = NastyMoment.of(trigger, day: day(steps, at: hour, minute: 30, jolly: jolly, record: true))
                            for line in NastyPicker.candidates(catalog, level: level, moment: moment) {
                                said.insert(line.id)
                                XCTAssertEqual(line.livello, level.catalogName)
                                if let r = line.minutes { XCTAssertTrue(r.contains(hour * 60 + 30), line.id) }
                                if let e = line.event { XCTAssertTrue(moment.facts.contains(e), line.id) }
                                if steps < 50 { XCTAssertFalse(line.placeholders.contains(.passi), line.id) }
                                let q = NastyPicker.quote(line, values: moment.values)
                                XCTAssertFalse(q.text.contains("{") || (q.title ?? "").contains("{"), line.id)
                                XCTAssertFalse(q.text.contains(" 0 ") || q.text.hasPrefix("0 "), "\(line.id): \(q.text)")
                            }
                            if let q = NastyPicker.pick(catalog, level: level, moment: moment, memory: NastyMemory(), using: &rng) {
                                XCTAssertTrue(NastyPicker.candidates(catalog, level: level, moment: moment).contains { $0.id == q.id })
                            }
                        }
                    }
                }
            }
        }
        // every approved line can be said in some moment
        XCTAssertEqual(Set(catalog.battute.map(\.id)).subtracting(said), [])
        XCTAssertNil(NastyPicker.pick(catalog, level: .normale, moment: NastyMoment.of(.home, day: day(3_000)),
                                      memory: NastyMemory(), using: &rng))
    }

    func testHoursAndEvents() {
        let at11 = NastyPicker.candidates(catalog, level: .nasty, moment: NastyMoment.of(.home, day: day(3_000, at: 11, minute: 20)))
        XCTAssertTrue(at11.contains { $0.id == "N046" })        // «Sono le 11»
        let at15 = NastyPicker.candidates(catalog, level: .nasty, moment: NastyMoment.of(.home, day: day(3_000, at: 15)))
        XCTAssertFalse(at15.contains { $0.id == "N046" })
        XCTAssertTrue(at15.contains { $0.id == "N052" })        // «Ore 15»
        let lowered = NastyPicker.candidates(catalog, level: .nasty, moment: NastyMoment.of(.goalChanged(old: 12_000), day: day(0)))
        XCTAssertTrue(lowered.contains { $0.id == "N080" })
        XCTAssertFalse(lowered.contains { $0.id == "N089" })
        let first = NastyPicker.candidates(catalog, level: .nasty, moment: NastyMoment.of(.goalChanged(old: nil), day: day(0)))
        XCTAssertFalse(first.contains { $0.event != nil })
        XCTAssertTrue(first.contains { $0.id == "N078" })
        let lastJolly = NastyPicker.candidates(catalog, level: .nasty, moment: NastyMoment.of(.jollyUsed, day: day(0, jolly: 0)))
        XCTAssertTrue(lastJolly.contains { $0.id == "N107" })
        XCTAssertTrue(lastJolly.contains { $0.id == "N096" })
        XCTAssertFalse(lastJolly.contains { $0.id == "N097" })  // «Ne restano {jolly}» with none left
    }

    func testFilling() {
        let line = catalog.battute.first { $0.id == "N005" }!   // «{passi} passi su {obiettivo}. Ridicolo.»
        let q = NastyPicker.quote(line, values: NastyValues(passi: 1_234, obiettivo: 10_000))
        XCTAssertEqual(q.text, "1.234 passi su 10.000. Ridicolo.")
        let n = catalog.battute.first { $0.id == "N126" }!
        let qn = NastyPicker.quote(n, values: NastyValues(passi: 2_000, obiettivo: 8_000))
        XCTAssertEqual(qn.title, "Ehi, soprammobile")
        XCTAssertEqual(qn.text, "2.000 passi su 8.000. Muoviti.")
    }

    /// No line among the last 20 of its level; when everything was seen recently, the oldest.
    func testNoRepeatsAmongTheLast20() {
        var rng = SeededRandom(seed: 42)
        var memory = NastyMemory()
        var history: [String] = []
        let moment = NastyMoment.of(.home, day: day(3_000, at: 9))  // «Pochi passi»: 42 NASTY lines
        for _ in 0..<500 {
            let q = NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: memory, using: &rng)!
            XCTAssertFalse(history.suffix(20).contains(q.id), q.id)
            history.append(q.id)
            memory.record(q.id, level: .nasty)
        }
        XCTAssertEqual(memory.recent(.nasty).count, 20)
        XCTAssertEqual(memory.recent(.nasty).first, history.last)
        XCTAssertEqual(memory.recent(.piccante), [])
        // only 5 heart lines: after 5, the one seen longest ago comes back
        var heart = NastyMemory()
        let tap = NastyMoment.of(.heart, day: day(3_000))
        var order: [String] = []
        for _ in 0..<10 {
            let q = NastyPicker.pick(catalog, level: .nasty, moment: tap, memory: heart, using: &rng)!
            order.append(q.id)
            heart.record(q.id, level: .nasty)
        }
        XCTAssertEqual(Set(order.prefix(5)).count, 5)
        XCTAssertEqual(Array(order.suffix(5)), Array(order.prefix(5)))
    }

    func testSameSeedSameChoice() {
        let moment = NastyMoment.of(.home, day: day(3_000))
        var a = SeededRandom(seed: 99), b = SeededRandom(seed: 99)
        let x = (0..<20).map { _ in NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: NastyMemory(), using: &a)!.id }
        let y = (0..<20).map { _ in NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: NastyMemory(), using: &b)!.id }
        XCTAssertEqual(x, y)
        XCTAssertGreaterThan(Set(x).count, 5)
        XCTAssertEqual(SeededRandom.seed("abc"), SeededRandom.seed("abc"))
        XCTAssertNotEqual(SeededRandom.seed("abc"), SeededRandom.seed("abd"))
    }

    func testAvoidingPrefersLinesWithoutTheSteps() {
        var rng = SeededRandom(seed: 3)
        let moment = NastyMoment.of(.notification, day: day(3_000))
        for _ in 0..<50 {
            let q = NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: NastyMemory(), avoiding: [.passi], using: &rng)!
            XCTAssertTrue(["N133", "N136"].contains(q.id), q.id)
        }
        // both seen: the others with {passi} come
        var memory = NastyMemory()
        memory.record("N133", level: .nasty); memory.record("N136", level: .nasty)
        let q = NastyPicker.pick(catalog, level: .nasty, moment: moment, memory: memory, avoiding: [.passi], using: &rng)!
        XCTAssertFalse(["N133", "N136"].contains(q.id))
    }

    func testMemoryCodable() {
        var m = NastyMemory()
        m.record("N001", level: .nasty); m.record("P001", level: .piccante); m.record("N001", level: .nasty)
        XCTAssertEqual(m.recent(.nasty), ["N001"])
        XCTAssertEqual(NastyMemory.decoded(m.encoded()), m)
        XCTAssertNil(NastyMemory.decoded(Data("x".utf8)))
    }
}

final class RoastPlanTests: XCTestCase {
    let catalog = NastyLibrary.onBoard.catalogs["it"]!
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func date(_ hour: Int, _ minute: Int = 0, day: Int = 19) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func today(_ steps: Int, goal: Int = 10_000) -> NastyMoment.Day {
        NastyMoment.Day(steps: steps, goal: goal, minutesLeft: 60, streak: 4, jolly: 1, minuteOfDay: 8 * 60)
    }

    func testTimesForEverySeed() {
        for level in [NastyLevel.piccante, .nasty] {
            for frequency in RoastFrequency.allCases {
                var counts = Set<Int>()
                for seed in 0..<400 {
                    let m = RoastPlan.minutes(level: level, frequency: frequency, seed: UInt64(seed) &* 2_654_435_761)
                    counts.insert(m.count)
                    XCTAssertTrue(RoastPlan.countRange(level, frequency).contains(m.count))
                    XCTAssertTrue(m.allSatisfy { (600...1200).contains($0) }, "\(m)")
                    for (a, b) in zip(m, m.dropFirst()) { XCTAssertGreaterThanOrEqual(b - a, 90) }
                }
                XCTAssertEqual(counts, Set(RoastPlan.countRange(level, frequency)))
            }
        }
        // T-026 §1: Senza pietà 2 · 4–5 · 7, Piccante 1 · 1–2 · 3
        XCTAssertEqual(RoastFrequency.allCases.map { RoastPlan.countRange(.nasty, $0) }, [2...2, 4...5, 7...7])
        XCTAssertEqual(RoastFrequency.allCases.map { RoastPlan.countRange(.piccante, $0) }, [1...1, 1...2, 3...3])
        XCTAssertEqual(RoastPlan.minutes(level: .normale, frequency: .tante, seed: 1), [])
        // not fixed: the first time changes from day to day
        let firsts = Set((1...30).map { d in
            RoastPlan.minutes(level: .nasty, frequency: .normali, seed: RoastPlan.seed(day: "2026-11-\(d)", salt: 5)).first!
        })
        XCTAssertGreaterThan(firsts.count, 15)
    }

    func testPlanOfTheDay() {
        let plan = RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                  day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: 11)
        XCTAssertTrue((4...5).contains(plan.count))
        XCTAssertEqual(Set(plan.map(\.quote.id)).count, plan.count)
        XCTAssertTrue(plan.allSatisfy { $0.date >= date(10) && $0.date <= date(20) && $0.quote.title != nil })
        XCTAssertTrue(plan.allSatisfy { $0.id.hasPrefix("stepteller.roast.2026-11-19.") })
        // the two lines without {passi} come first
        XCTAssertEqual(Set(plan.prefix(2).map(\.quote.id)), ["N133", "N136"])
        // planned again later the same day: same times, the past ones gone
        let later = RoastPlan.plan(now: plan[1].date, calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                   day: today(3_500), lastDelivered: nil, memory: NastyMemory(), salt: 11)
        XCTAssertEqual(later.map(\.date), Array(plan.dropFirst(2)).map(\.date))
        XCTAssertEqual(later.map(\.id), Array(plan.dropFirst(2)).map(\.id))
        // same input, same plan
        XCTAssertEqual(plan, RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                            day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: 11))
    }

    func testPlanRespectsTheLastDeliveredAndTheGoal() {
        let last = date(12)
        for salt in 0..<50 as Range<UInt64> {
            let plan = RoastPlan.plan(now: date(12, 5), calendar: calendar, level: .nasty, frequency: .tante, catalog: catalog,
                                      day: today(3_000), lastDelivered: last, memory: NastyMemory(), salt: salt)
            XCTAssertTrue(plan.allSatisfy { $0.date >= last.addingTimeInterval(90 * 60) })
        }
        XCTAssertEqual(RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .tante, catalog: catalog,
                                      day: today(10_000), lastDelivered: nil, memory: NastyMemory(), salt: 1), [])
        XCTAssertEqual(RoastPlan.plan(now: date(8), calendar: calendar, level: .normale, frequency: .tante, catalog: catalog,
                                      day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: 1), [])
        XCTAssertEqual(RoastPlan.plan(now: date(20, 1), calendar: calendar, level: .nasty, frequency: .tante, catalog: catalog,
                                      day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: 1), [])
    }

    /// «Sono le 18» only at 18; below 50 steps never the steps.
    func testPlanLinesFitTheirTime() {
        for salt in 0..<300 as Range<UInt64> {
            for level in [NastyLevel.piccante, .nasty] {
                let plan = RoastPlan.plan(now: date(8), calendar: calendar, level: level, frequency: .tante, catalog: catalog,
                                          day: today(salt % 2 == 0 ? 20 : 3_000), lastDelivered: nil, memory: NastyMemory(),
                                          salt: salt)
                for item in plan {
                    let minute = calendar.component(.hour, from: item.date) * 60 + calendar.component(.minute, from: item.date)
                    if let r = catalog.battute.first(where: { $0.id == item.quote.id })?.minutes {
                        XCTAssertTrue(r.contains(minute), item.quote.id)
                    }
                    if salt % 2 == 0 { XCTAssertFalse(item.quote.text.contains("20 passi"), item.quote.text) }
                    XCTAssertFalse(item.quote.text.contains("{"))
                }
            }
        }
    }

    /// The days the clock changes: still between 10:00 and 20:00 on the clock, and the hour of a line is the clock's.
    func testClockChangeDays() {
        for (y, m, d) in [(2026, 10, 25), (2027, 3, 28)] {
            let morning = calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 7))!
            for salt in 0..<200 as Range<UInt64> {
                let plan = RoastPlan.plan(now: morning, calendar: calendar, level: .nasty, frequency: .tante, catalog: catalog,
                                          day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: salt)
                for item in plan {
                    let c = calendar.dateComponents([.hour, .minute, .day], from: item.date)
                    let minute = c.hour! * 60 + c.minute!
                    XCTAssertEqual(c.day, d)
                    XCTAssertTrue((600...1200).contains(minute), "\(y)-\(m)-\(d) \(c.hour!):\(c.minute!)")
                    XCTAssertTrue(item.id.hasSuffix(String(format: ".%02d%02d", c.hour!, c.minute!)), item.id)
                    if let r = catalog.battute.first(where: { $0.id == item.quote.id })?.minutes {
                        XCTAssertTrue(r.contains(minute), item.quote.id)
                    }
                }
                for (a, b) in zip(plan, plan.dropFirst()) {
                    XCTAssertGreaterThanOrEqual(b.date.timeIntervalSince(a.date), 89 * 60)
                }
            }
        }
    }

    /// Never the same notification twice, not even when few lines fit (below 50 steps no line shows the steps):
    /// fewer notifications instead.
    func testNoRepeatedNotifications() {
        for steps in [0, 20, 3_000] {
            for level in [NastyLevel.piccante, .nasty] {
                for salt in 0..<200 as Range<UInt64> {
                    let plan = RoastPlan.plan(now: date(8), calendar: calendar, level: level, frequency: .tante, catalog: catalog,
                                              day: today(steps), lastDelivered: nil, memory: NastyMemory(), salt: salt)
                    XCTAssertEqual(Set(plan.map(\.quote.id)).count, plan.count, "\(steps) \(level) \(plan.map(\.quote.id))")
                    if steps < 50 { XCTAssertTrue(plan.allSatisfy { !$0.quote.text.hasPrefix("\(steps) passi") && !$0.quote.text.contains(" \(steps) passi") }) }
                }
            }
        }
        // below 50 steps NASTY has one line without the steps ({mancano}): one notification, not five copies
        let low = RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                 day: today(20), lastDelivered: nil, memory: NastyMemory(), salt: 4)
        XCTAssertEqual(low.map(\.quote.id), ["N133"])
        // and nothing seen recently
        var memory = NastyMemory()
        memory.record("N133", level: .nasty)
        XCTAssertEqual(RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                      day: today(20), lastDelivered: nil, memory: memory, salt: 4), [])
    }

    func testOtherNumberFormat() {
        let plan = RoastPlan.plan(now: date(8), calendar: calendar, level: .nasty, frequency: .normali, catalog: catalog,
                                  day: today(3_000), lastDelivered: nil, memory: NastyMemory(), salt: 11,
                                  format: { "<\($0)>" })
        XCTAssertTrue(plan.contains { $0.quote.text.contains("<7000>") || $0.quote.text.contains("<30>") })
        XCTAssertFalse(plan.contains { $0.quote.text.contains("7.000") })
    }
}

final class NastyBubbleTests: XCTestCase {
    let catalog = NastyLibrary.onBoard.catalogs["it"]!
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Rome")!
        return c
    }()

    private func date(_ hour: Int, _ minute: Int = 0, day: Int = 19) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func home(_ steps: Int, _ hour: Int, _ minute: Int = 0) -> NastyMoment {
        NastyMoment.of(.home, day: NastyMoment.Day(steps: steps, goal: 10_000, minutesLeft: max(0, 10_000 - steps) / 110,
                                                   streak: 5, jolly: 1, minuteOfDay: hour * 60 + minute))
    }

    func testKeepsTheLineUntilTheSituationChangesAtMostHourly() {
        var memory = NastyMemory()
        var rng = SeededRandom(seed: 3)
        let first = NastyBubble.home(nil, catalog: catalog, level: .nasty, moment: home(3_000, 9), memory: &memory,
                                     now: date(9), calendar: calendar, using: &rng)!
        XCTAssertEqual(memory.recent(.nasty), [first.bubble.id])
        // same situation, hours later: the same line, numbers filled again
        let later = NastyBubble.home(first.bubble, catalog: catalog, level: .nasty, moment: home(3_400, 10, 30),
                                     memory: &memory, now: date(10, 30), calendar: calendar, using: &rng)!
        XCTAssertEqual(later.bubble, first.bubble)
        if catalog.battute.first(where: { $0.id == first.bubble.id })!.placeholders.contains(.passi) {
            XCTAssertTrue(later.quote.text.contains("3.400"), later.quote.text)
        }
        // situation changed (11:00 adds morning and afternoon) less than an hour after: still the same line
        let pick = NastyBubble(id: first.bubble.id, level: .nasty, situations: [.pochiPassi], since: date(10, 30), heart: false)
        let soon = NastyBubble.home(pick, catalog: catalog, level: .nasty, moment: home(3_400, 11, 10), memory: &memory,
                                    now: date(11, 10), calendar: calendar, using: &rng)!
        XCTAssertEqual(soon.bubble, pick)
        // and a new one after the hour
        let after = NastyBubble.home(pick, catalog: catalog, level: .nasty, moment: home(3_400, 11, 40), memory: &memory,
                                     now: date(11, 40), calendar: calendar, using: &rng)!
        XCTAssertEqual(after.bubble.situations, [.pochiPassi, .mattinaPomeriggio])
        XCTAssertEqual(after.bubble.since, date(11, 40))
    }

    func testChangesRightAwayWhenTheLineCanNoLongerBeSaid() {
        var memory = NastyMemory()
        var rng = SeededRandom(seed: 9)
        let low = NastyBubble.home(nil, catalog: catalog, level: .nasty, moment: home(3_000, 15), memory: &memory,
                                   now: date(15), calendar: calendar, using: &rng)!
        let done = NastyBubble.home(low.bubble, catalog: catalog, level: .nasty, moment: home(10_200, 15, 5),
                                    memory: &memory, now: date(15, 5), calendar: calendar, using: &rng)!
        XCTAssertEqual(done.bubble.situations, [.fatto])
        XCTAssertTrue(catalog.lines(.nasty, .fatto).contains { $0.id == done.bubble.id })
        // another level, another day: a new line
        let piccante = NastyBubble.home(done.bubble, catalog: catalog, level: .piccante, moment: home(10_200, 15, 6),
                                        memory: &memory, now: date(15, 6), calendar: calendar, using: &rng)!
        XCTAssertEqual(piccante.bubble.level, .piccante)
        let tomorrow = NastyBubble.home(piccante.bubble, catalog: catalog, level: .piccante, moment: home(10_200, 15, 6),
                                        memory: &memory, now: date(15, 6, day: 20), calendar: calendar, using: &rng)!
        XCTAssertEqual(tomorrow.bubble.since, date(15, 6, day: 20))
        // Normale: nothing
        XCTAssertNil(NastyBubble.home(nil, catalog: catalog, level: .normale, moment: home(3_000, 15), memory: &memory,
                                      now: date(15), calendar: calendar, using: &rng))
    }

    /// Twice the goal later the same day: the event's lines take the bubble, without waiting (T-031).
    func testAnEventLaterTakesTheBubble() {
        var memory = NastyMemory()
        var rng = SeededRandom(seed: 5)
        var bubble: NastyBubble?
        // a generic «Quando ce la fai» line at the goal
        for seed in 0..<50 {
            var r = SeededRandom(seed: UInt64(seed))
            let b = NastyBubble.home(nil, catalog: catalog, level: .nasty, moment: home(10_200, 15), memory: &memory,
                                     now: date(15), calendar: calendar, using: &r)!.bubble
            if catalog.battute.first(where: { $0.id == b.id })!.event == nil { bubble = b; break }
        }
        let generic = try! XCTUnwrap(bubble)
        // same situation ([.fatto]) ten minutes later, now twice the goal
        let twice = NastyBubble.home(generic, catalog: catalog, level: .nasty, moment: home(21_000, 15, 10),
                                     memory: &memory, now: date(15, 10), calendar: calendar, using: &rng)!
        XCTAssertEqual(catalog.battute.first { $0.id == twice.bubble.id }!.event, .doppio)
        // and it stays
        let still = NastyBubble.home(twice.bubble, catalog: catalog, level: .nasty, moment: home(21_500, 15, 20),
                                     memory: &memory, now: date(15, 20), calendar: calendar, using: &rng)!
        XCTAssertEqual(still.bubble, twice.bubble)
    }

    func testHeartLineStaysWhileTheSituationStaysAtMostAnHour() {
        var memory = NastyMemory()
        var rng = SeededRandom(seed: 4)
        let tap = NastyBubble.heart(catalog: catalog, level: .nasty, moment: home(3_000, 15), memory: &memory,
                                    now: date(15), using: &rng)!
        XCTAssertTrue(tap.bubble.heart)
        XCTAssertTrue(catalog.lines(.nasty, .cuore).contains { $0.id == tap.bubble.id })
        XCTAssertEqual(tap.bubble.situations, [.pochiPassi, .mattinaPomeriggio])
        let kept = NastyBubble.home(tap.bubble, catalog: catalog, level: .nasty, moment: home(3_100, 15, 30),
                                    memory: &memory, now: date(15, 30), calendar: calendar, using: &rng)!
        XCTAssertEqual(kept.bubble, tap.bubble)
        let hour = NastyBubble.home(tap.bubble, catalog: catalog, level: .nasty, moment: home(3_100, 16, 1),
                                    memory: &memory, now: date(16, 1), calendar: calendar, using: &rng)!
        XCTAssertFalse(hour.bubble.heart)
        let half = NastyBubble.home(tap.bubble, catalog: catalog, level: .nasty, moment: home(6_000, 15, 10),
                                    memory: &memory, now: date(15, 10), calendar: calendar, using: &rng)!
        XCTAssertEqual(half.bubble.situations, [.aMetaQuasi])
        XCTAssertFalse(half.bubble.heart)
    }

    func testRage() {
        XCTAssertEqual([1, 2, 3, 7].map(NastyRage.k), [1, 1.35, 1.7, 1.7])
        XCTAssertFalse(NastyRage.angry(taps: 1))
        XCTAssertTrue(NastyRage.angry(taps: 2))
        let now = Date(timeIntervalSince1970: 1_000)
        let taps = [now - 5, now - 3.9, now - 1, now]
        XCTAssertEqual(NastyRage.recent(taps, now: now), [now - 3.9, now - 1, now])
    }

    func testDownloadOnceADay() {
        XCTAssertEqual(NastyDownload.url(language: "pt-BR").absoluteString,
                       "https://castellanza-alt.github.io/StepTeller/neat/nasty/pt-BR/battute.json")
        XCTAssertTrue(NastyDownload.isDue(last: nil, now: date(9), calendar: calendar))
        XCTAssertFalse(NastyDownload.isDue(last: date(0, 5), now: date(23, 59), calendar: calendar))
        XCTAssertTrue(NastyDownload.isDue(last: date(23, 59, day: 18), now: date(0, 1), calendar: calendar))
        XCTAssertTrue(NastyDownload.isDue(last: date(10, day: 20), now: date(9), calendar: calendar))
    }
}
