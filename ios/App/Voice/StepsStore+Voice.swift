import Foundation
import StepTellerCore

/// NEAT's voice in the app (T-027): the Home bubble and the heart, the first line after the update, the lines of the
/// goal, the pop-ups and the celebration, the catalog from the site, the roast notifications. The choices are the
/// core's (`NastyBubble`, `NastyPicker`, `RoastPlan`); here only when and with which numbers.
extension StepsStore {
    /// The level NEAT speaks with: the chosen one if the app's language has a valid catalog, otherwise Normale.
    var voice: NastyLevel {
        _ = catalogEdition
        return NastyVoice.library.effective(voiceLevel, language: NastyVoice.language)
    }

    /// Levels offered in the app's language (only Normale without a catalog: no Voice section, no intro page).
    var voiceLevels: [NastyLevel] {
        _ = catalogEdition
        return NastyVoice.levels
    }

    /// Today as the voice sees it.
    func voiceDay(now: Date = Date(), steps: Int? = nil, goal: Int? = nil) -> NastyMoment.Day {
        let cal = Calendar.current
        let goal = goal ?? self.goal
        let steps = steps ?? self.steps
        let minutes = Plan(goal: goal, steps: steps, speed: speed, model: model).minutes
        return NastyMoment.Day(steps: steps, goal: goal, minutesLeft: minutes, streak: history.streak.streak,
                               jolly: history.streak.jolly,
                               minuteOfDay: cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now))
    }

    // MARK: Home

    private var savedBubble: NastyBubble? {
        get { defaults.data(forKey: Keys.bubble).flatMap { try? JSONDecoder().decode(NastyBubble.self, from: $0) } }
        set { defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Keys.bubble) }
    }

    /// The bubble with Home on screen (a line counts as seen only when it shows): the line stays or changes
    /// (`NastyBubble.home`); when it comes or changes the heart speaks. The first line after the update wins once.
    func updateHomeLine(now: Date = Date()) {
        let level = voice
        guard level != .normale, let catalog = NastyVoice.catalog, !showsNoDataWarning, goal > 0 else {
            homeQuote = nil
            showsFirstLine = false
            return
        }
        let moment = NastyMoment.of(.home, day: voiceDay(now: now))
        if firstLine(moment.situations, now: now) { return }
        var memory = SharedStore.nastyMemory
        var rng = SystemRandomNumberGenerator()
        let previous = savedBubble
        guard let result = NastyBubble.home(previous, catalog: catalog, level: level, moment: moment, memory: &memory,
                                            now: now, calendar: .current, format: LocalFormat.integer, using: &rng)
        else { homeQuote = nil; return }
        let comes = homeQuote == nil || result.bubble.id != previous?.id || result.bubble.level != previous?.level
        if result.bubble != previous {
            savedBubble = result.bubble
            SharedStore.nastyMemory = memory
        }
        homeQuote = result.quote
        if comes { heart.speak(level, now: now) }
    }

    /// A tap on the heart: its reaction, then a line «Se tocchi il cuore» (T-023 §3.4).
    func tapHeart(now: Date = Date()) {
        let level = voice
        guard level != .normale, let catalog = NastyVoice.catalog else { return }
        heart.tap(level, now: now)
        var memory = SharedStore.nastyMemory
        var rng = SystemRandomNumberGenerator()
        guard let result = NastyBubble.heart(catalog: catalog, level: level,
                                             moment: NastyMoment.of(.home, day: voiceDay(now: now)), memory: &memory,
                                             now: now, format: LocalFormat.integer, using: &rng) else { return }
        savedBubble = result.bubble
        SharedStore.nastyMemory = memory
        if showsFirstLine { defaults.set("done", forKey: Keys.firstLine) }    // the first line gave way to the tap
        showsFirstLine = false
        homeQuote = result.quote
    }

    // MARK: first line after the update (T-023 §4)

    /// At launch, before anything is saved: who updates from 1.2 (introduction already done) will see the first
    /// line once; who installs now has the introduction page instead.
    static func resolveFirstLine(_ defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: Keys.firstLine) == nil else { return }
        defaults.set(defaults.bool(forKey: Onboarding.doneKey) ? "pending" : "none", forKey: Keys.firstLine)
    }

    /// The first line in the bubble: still to show (marked now, as it really shows in Home), or shown today and
    /// the situation not changed since. Returns whether it is in the bubble.
    private func firstLine(_ situations: [NastySituation], now: Date) -> Bool {
        let day = DayKey.of(now, calendar: .current)
        let here = day + ":" + situations.map(\.rawValue).joined(separator: ",")
        let state = defaults.string(forKey: Keys.firstLine) ?? "none"
        if state == "pending" {
            defaults.set("shown:" + here, forKey: Keys.firstLine)
            homeQuote = NastyQuote(id: "first", title: nil, text: L10n.text("voice.firstLine"))
            if !showsFirstLine { heart.speak(voice, slow: true, now: now) }
            showsFirstLine = true
            return true
        }
        guard state == "shown:" + here else {
            if showsFirstLine { homeQuote = nil }
            showsFirstLine = false
            return false
        }
        if !showsFirstLine { homeQuote = NastyQuote(id: "first", title: nil, text: L10n.text("voice.firstLine")) }
        showsFirstLine = true
        return true
    }

    // MARK: the other places (T-023 §6)

    private func say(_ moment: NastyMoment) -> NastyQuote? {
        let level = voice
        guard level != .normale, let catalog = NastyVoice.catalog else { return nil }
        var memory = SharedStore.nastyMemory
        var rng = SystemRandomNumberGenerator()
        guard let quote = NastyPicker.pick(catalog, level: level, moment: moment, memory: memory,
                                           format: LocalFormat.integer, using: &rng) else { return nil }
        memory.record(quote.id, level: level)
        SharedStore.nastyMemory = memory
        return quote
    }

    /// The line under the goal when it is chosen (`old` nil, the introduction) or changed.
    func goalLine(old: Int?, new: Int) -> NastyQuote? {
        say(NastyMoment.of(.goalChanged(old: old), day: voiceDay(goal: new)))
    }

    /// The line of a Jolly pop-up, instead of its first sentence (none for the Christmas gift).
    func popupLine(_ item: JollyPopupItem) -> NastyQuote? {
        var day = voiceDay()
        day.streak = item.streak
        day.jolly = item.jolly
        switch item.kind {
        case .used: return say(NastyMoment.of(.jollyUsed, day: day))
        case .earned: return say(NastyMoment.of(.jollyEarned, day: day))
        case .gift: return nil
        }
    }

    /// The title of the goal celebration.
    func celebrationLine(steps: Int, goal: Int, streak: Int) -> NastyQuote? {
        guard goal > 0, steps >= goal else { return nil }       // only «Quando ce la fai»
        var day = voiceDay(steps: steps, goal: goal)
        day.streak = streak
        return say(NastyMoment.of(.home, day: day))
    }

    // MARK: catalog from the site (T-022 §4)

    /// Once a day, only with a voice chosen (with Normale nothing is downloaded): the public file of the language
    /// (and the Italian one, which the others are checked against). Kept only if it passes the check; nothing sent.
    func refreshCatalog(now: Date = Date()) async {
        // the voice in force: chosen, and the language has a catalog (where the app speaks Normale, nothing)
        guard voice != .normale else { return }
        #if DEBUG
        if defaults.object(forKey: "stepteller.debugSteps") != nil { return }     // screenshots: the catalog on board
        #endif
        let last = defaults.object(forKey: Keys.catalogCheck) as? Date
        guard NastyDownload.isDue(last: last, now: now, calendar: .current) else { return }
        let language = NastyVoice.library.catalog(language: NastyVoice.language)?.lingua ?? NastyVoice.language
        var changed = false, answered = false
        for code in Set([NastyLibrary.reference, language]).sorted(by: { $0 == NastyLibrary.reference && $1 != $0 }) {
            guard let data = await CatalogDownload.fetch(NastyDownload.url(language: code)) else { continue }
            answered = true
            if NastyVoice.store(data) { changed = true }
        }
        // without network it tries again at the next opening, not tomorrow
        if answered { defaults.set(now, forKey: Keys.catalogCheck) }
        guard changed else { return }
        catalogEdition += 1
        await updateReminders()
    }

    // MARK: roast notifications (T-022 §3)

    /// What the roast planner needs, read on the main actor.
    func roastInput(steps: Int, now: Date = Date()) -> RoastScheduler.Input {
        var salt = defaults.object(forKey: Keys.roastSalt) as? Int
        if salt == nil {
            salt = Int.random(in: Int.min...Int.max)
            defaults.set(salt, forKey: Keys.roastSalt)
        }
        var level = voice
        #if DEBUG
        if defaults.object(forKey: "stepteller.debugSteps") != nil, defaults.object(forKey: "stepteller.debugRoast") == nil {
            level = .normale        // screenshots: no notification permission prompt over the UI
        }
        #endif
        return RoastScheduler.Input(now: now, level: level, frequency: roastFrequency, catalog: NastyVoice.catalog,
                                    day: voiceDay(now: now, steps: steps), salt: UInt64(bitPattern: Int64(salt ?? 0)))
    }
}
