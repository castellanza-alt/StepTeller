import Foundation
import OSLog
import StepTellerCore

/// NEAT's voice where app and widget both need it (T-027): the catalog (the one on board, or the one downloaded
/// from the site, kept in the App Group), the level in force for the language of the app, the lines already seen,
/// and the voice of the evening reminder and of the goal and Jolly notifications. Everything stays on the phone.
enum NastyVoice {
    static let log = Logger(subsystem: "it.castellanza.stepteller", category: "voice")

    /// Language of the app: the catalogs have the same codes as its localizations.
    static var language: String { Bundle.main.preferredLocalizations.first ?? NastyLibrary.reference }

    // MARK: catalog

    /// Downloaded catalogs, one file per language, in the App Group (the widget reads them too).
    private static var folder: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.suite)?
            .appendingPathComponent("NastyCatalogs", isDirectory: true)
    }

    private static func file(_ language: String) -> URL? {
        folder?.appendingPathComponent("\(language).json")
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cached: (library: NastyLibrary, stamp: [String: Date])?

    /// Modification dates of the downloaded files: another process (the app, for the widget) may have saved one.
    private static func stamp() -> [String: Date] {
        var out: [String: Date] = [:]
        for code in NastyLibrary.languages {
            guard let url = file(code),
                  let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
            else { continue }
            out[code] = date
        }
        return out
    }

    /// The catalogs on board, replaced by the downloaded ones that pass the check (Italian first: the others are
    /// checked against it). A file that does not pass leaves the one on board.
    static var library: NastyLibrary {
        lock.lock(); defer { lock.unlock() }
        let stamp = stamp()
        if let cached, cached.stamp == stamp { return cached.library }
        var library = NastyLibrary.onBoard
        let codes = NastyLibrary.languages.sorted { ($0 != NastyLibrary.reference ? 1 : 0, $0) < ($1 != NastyLibrary.reference ? 1 : 0, $1) }
        for code in codes {
            guard let url = file(code), let data = try? Data(contentsOf: url) else { continue }
            library = library.replaced(by: data)
        }
        cached = (library, stamp)
        return library
    }

    /// The catalog of the app's language (nil: the language has none, and NEAT speaks Normale).
    static var catalog: NastyCatalog? { library.catalog(language: language) }

    /// A file downloaded from the site: kept only if it passes the check and is newer than the catalog in use.
    /// Returns whether the catalog changed.
    @discardableResult
    static func store(_ data: Data) -> Bool {
        let before = library
        let after = before.replaced(by: data)
        guard after != before, let code = after.catalogs.first(where: { before.catalogs[$0.key] != $0.value })?.key,
              let folder, let url = file(code) else { return false }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            log.error("voice: catalog \(code) not saved: \(error.localizedDescription)")
            return false
        }
        log.notice("voice: catalog \(code) \(after.catalogs[code]?.edizione ?? "") in use")
        return true
    }

    // MARK: level

    /// The level the app speaks with: the chosen one if the language has a valid catalog, otherwise Normale.
    static var level: NastyLevel { library.effective(SharedStore.voiceLevel, language: language) }

    /// Levels offered in the app's language (only Normale without a valid catalog: no Voice section).
    static var levels: [NastyLevel] { library.levels(language: language) }

    // MARK: notifications

    /// Repeatable choice for a notification: the same for the same day and purpose (the widget rewrites the
    /// reminder often, and the text must not change at every rewrite), different every day. Without the memory of
    /// the lines seen: it changes during the day, and the line with it.
    /// `excluding`, `notSaying`: what the notification says already (T-031).
    private static func line(_ moment: NastyMoment, purpose: String, day: String, excluding: Set<NastyPlaceholder> = [],
                             notSaying: [String] = []) -> NastyQuote? {
        let level = level
        guard level != .normale, let catalog else { return nil }
        var rng = SeededRandom(seed: SeededRandom.seed("voice.\(purpose).\(day)"))
        return NastyPicker.pick(catalog, level: level, moment: moment, memory: NastyMemory(),
                                excluding: excluding, notSaying: notSaying,
                                format: LocalFormat.integer, using: &rng)
    }

    /// The evening reminder with the voice: the line first, then the numbers of the reminder (its reason to be).
    /// Days still to come (generic text) get a line without numbers.
    static func reminder(_ base: ReminderContent, message: ReminderMessage, fire: DateComponents,
                         calendar: Calendar = .current) -> ReminderContent {
        guard let date = calendar.date(from: fire) else { return base }
        let minute = (fire.hour ?? 20) * 60 + (fire.minute ?? 0)
        let day = DayKey.of(date, calendar: calendar)
        var quote: NastyQuote?
        switch message {
        case let .precise(minutes, _, goal, remaining, warning):
            let today = NastyMoment.Day(steps: max(0, goal - remaining), goal: goal, minutesLeft: minutes,
                                        streak: SharedStore.streak, jolly: SharedStore.jolly, minuteOfDay: minute)
            if case .wouldBreak? = warning {
                quote = line(NastyMoment.of(.streakAtRisk, day: today), purpose: "reminder.risk", day: day,
                             excluding: reminderNumbers)
            }
            quote = quote ?? line(NastyMoment.of(.notification, day: today), purpose: "reminder", day: day,
                                  excluding: reminderNumbers)
        case .generic:
            let moment = NastyMoment(situations: [.notifiche], values: NastyValues(obiettivo: SharedStore.goal),
                                     minuteOfDay: minute)
            quote = line(moment, purpose: "reminder", day: day)
        }
        guard let quote else { return base }
        return ReminderContent(title: base.title, body: quote.text + gap + base.body)
    }

    /// Goal and Jolly notifications with the voice: their title, and the line as the text («Quando ce la fai» for
    /// the goal, «Jolly e serie» for the Jollies). Without a line, the usual text.
    static func event(_ base: ReminderContent, event: StreakEvent, steps: Int, goal: Int, now: Date,
                      calendar: Calendar = .current) -> ReminderContent {
        let minute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let today = NastyMoment.Day(steps: steps, goal: goal, minutesLeft: 0, streak: event.streak, jolly: event.jolly,
                                    minuteOfDay: minute)
        let trigger: NastyMoment.Trigger = switch event.kind {
        case .goalReached: .home
        case .jollyEarned: .jollyEarned
        case .jollyUsed: .jollyUsed
        }
        // never the notification's title again («Jolly usato» / «Jolly usato. Ieri hai fatto schifo.»)
        guard let quote = line(NastyMoment.of(trigger, day: today), purpose: "event." + event.id, day: event.day,
                               notSaying: [base.title]) else { return base }
        return ReminderContent(title: base.title, body: quote.text)
    }

    /// The reminder says minutes, goal and steps left by itself («… per arrivare a 10.000 (mancano 6.535)»): its line
    /// never repeats them (T-031).
    private static let reminderNumbers: Set<NastyPlaceholder> = [.mancano, .minuti, .obiettivo]

    /// Between two sentences: a space, none in Japanese and Chinese.
    private static var gap: String {
        let code = Locale.current.language.languageCode
        return code == .japanese || code == .chinese ? "" : " "
    }
}
