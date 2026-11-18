import Foundation
import StepTellerCore

/// Data shared between app and widget through the App Group: goal, calibration, speed chosen in Home,
/// units, streak and Jollies, last step count (used by the widget only when Health is locked, i.e. with the
/// phone locked). Everything stays on the phone.
enum SharedStore {
    static let suite = "group.it.castellanza.stepteller"
    static let defaults = UserDefaults(suiteName: suite) ?? .standard

    private enum Keys {
        static let goal = "goal"
        static let calibration = "calibration"
        static let lastSteps = "lastSteps"
        static let lastStepsDay = "lastStepsDay"
        static let speed = "speed"
        static let streak = "streak"
        static let jolly = "jolly"
        static let units = "units"
        static let reminderOn = "reminderOn"
        static let reminderMinutes = "reminderMinutes"
        static let reminderWarning = "reminderWarning"
        static let eventsOn = "eventsOn"
        static let eventLedger = "eventLedger"
        static let goalReach = "goalReach"
        static let seasonal = "stepteller.seasonal"
        static let jollyGifts = "jollyGifts"
        static let forcedSeason = "debugSeason"
    }

    /// Speed of the Home slider (km/h): the widget computes its minutes with the same one.
    static var speed: Double {
        get { defaults.object(forKey: Keys.speed) != nil ? defaults.double(forKey: Keys.speed) : SpeedTrack.defaultSpeed }
        set { defaults.set(newValue, forKey: Keys.speed) }
    }

    /// Units chosen in Settings (`Units.current` resolves «automatic» with the phone's region).
    static var unitPreference: UnitPreference {
        get { defaults.string(forKey: Keys.units).flatMap(UnitPreference.init(rawValue:)) ?? .automatic }
        set { defaults.set(newValue.rawValue, forKey: Keys.units) }
    }

    /// Streak and Jollies as the app computes them (the widget does not read the history).
    static var streak: Int {
        get { defaults.integer(forKey: Keys.streak) }
        set { defaults.set(newValue, forKey: Keys.streak) }
    }

    static var jolly: Int {
        get { defaults.integer(forKey: Keys.jolly) }
        set { defaults.set(newValue, forKey: Keys.jolly) }
    }

    /// Streak and Jollies saved by an earlier launch (`nil` on a fresh install): shown until the history is read.
    static var cachedStreak: (streak: Int, jolly: Int)? {
        defaults.object(forKey: Keys.streak) != nil ? (streak, jolly) : nil
    }

    static var goal: Int {
        get { defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000 }
        set { defaults.set(newValue, forKey: Keys.goal) }
    }

    static var calibration: CalibrationResult {
        get { defaults.data(forKey: Keys.calibration).flatMap { try? JSONDecoder().decode(CalibrationResult.self, from: $0) } ?? .empty }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: Keys.calibration) }
    }

    // MARK: evening reminder (for the widget, see WidgetReminder)

    /// Reminder on and its time (minutes from midnight), as in Settings.
    static var reminderOn: Bool {
        get { defaults.object(forKey: Keys.reminderOn) != nil ? defaults.bool(forKey: Keys.reminderOn) : true }
        set { defaults.set(newValue, forKey: Keys.reminderOn) }
    }

    static var reminderMinutes: Int {
        get { defaults.object(forKey: Keys.reminderMinutes) != nil ? defaults.integer(forKey: Keys.reminderMinutes) : 20 * 60 + 30 }
        set { defaults.set(newValue, forKey: Keys.reminderMinutes) }
    }

    /// Streak warning of tonight's notification, decided by the app from the past days (`jolly:2`, `break:5`).
    static var reminderWarning: ReminderMessage.Warning? {
        get {
            let parts = (defaults.string(forKey: Keys.reminderWarning) ?? "").split(separator: ":")
            guard parts.count == 2, let n = Int(parts[1]) else { return nil }
            switch parts[0] {
            case "jolly": return .wouldUseJolly(jollyLeft: n)
            case "break": return .wouldBreak(streak: n)
            default: return nil
            }
        }
        set {
            switch newValue {
            case let .wouldUseJolly(n)?: defaults.set("jolly:\(n)", forKey: Keys.reminderWarning)
            case let .wouldBreak(n)?: defaults.set("break:\(n)", forKey: Keys.reminderWarning)
            case nil: defaults.removeObject(forKey: Keys.reminderWarning)
            }
        }
    }

    // MARK: goal and Jolly notifications (see EventNotifier)

    /// Notifications of goal and Jollies on, as in Settings (default yes).
    static var eventsOn: Bool {
        get { defaults.object(forKey: Keys.eventsOn) != nil ? defaults.bool(forKey: Keys.eventsOn) : true }
        set { defaults.set(newValue, forKey: Keys.eventsOn) }
    }

    /// Events already announced, shared by app and widget (`EventLedger`).
    static var eventLedger: EventLedger? {
        get { EventLedger.decoded(defaults.data(forKey: Keys.eventLedger)) }
        set { defaults.set(newValue?.encoded(), forKey: Keys.eventLedger) }
    }

    /// What reaching today's goal means (streak, Jollies, a Jolly earned on the 15th day), as computed by the app
    /// with its day: the widget, which does not read the history, tells it with these numbers, only on that day.
    static var goalReach: StreakEvents.Reach? {
        get { StreakEvents.Reach(encoded: defaults.string(forKey: Keys.goalReach)) }
        set { defaults.set(newValue?.encoded, forKey: Keys.goalReach) }
    }

    // MARK: seasonal themes (see SeasonalTheme)

    /// «Seasonal themes» switch, as in Settings (default yes).
    static var seasonalOn: Bool {
        get { defaults.object(forKey: Keys.seasonal) != nil ? defaults.bool(forKey: Keys.seasonal) : true }
        set { defaults.set(newValue, forKey: Keys.seasonal) }
    }

    /// Christmas gifts received (`JollyGift.Ledger`), copy in the App Group: the main copy is in the app's
    /// UserDefaults (iCloud, Backup), see `HistoryStore`.
    static var jollyGifts: JollyGift.Ledger {
        get { JollyGift.Ledger(days: defaults.dictionary(forKey: Keys.jollyGifts) as? [String: String] ?? [:]) }
        set { defaults.set(newValue.days, forKey: Keys.jollyGifts) }
    }

    #if DEBUG
    /// Season forced by the launch argument `-stepteller.season` (Debug only), for the widget too.
    static var forcedSeason: String? {
        get { defaults.string(forKey: Keys.forcedSeason) }
        set { defaults.set(newValue, forKey: Keys.forcedSeason) }
    }
    #endif

    /// Last count read from Health, with the day it refers to.
    static func saveSteps(_ steps: Int, now: Date = Date(), calendar: Calendar = .current) {
        defaults.set(steps, forKey: Keys.lastSteps)
        defaults.set(calendar.startOfDay(for: now), forKey: Keys.lastStepsDay)
    }

    /// The last count, only if it is today's.
    static func cachedStepsToday(now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let day = defaults.object(forKey: Keys.lastStepsDay) as? Date,
              calendar.isDate(day, inSameDayAs: now),
              defaults.object(forKey: Keys.lastSteps) != nil else { return nil }
        return defaults.integer(forKey: Keys.lastSteps)
    }
}
