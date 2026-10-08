import Foundation
import StepTellerCore

/// Dati condivisi tra app e widget tramite App Group: obiettivo, taratura e ultimo conteggio passi
/// (usato dal widget solo quando Salute è bloccata, cioè a telefono bloccato). Tutto resta sul telefono.
enum SharedStore {
    static let suite = "group.it.castellanza.stepteller"
    static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    private enum Keys {
        static let goal = "goal"
        static let calibration = "calibration"
        static let lastSteps = "lastSteps"
        static let lastStepsDay = "lastStepsDay"
    }

    static var goal: Int {
        get { defaults.object(forKey: Keys.goal) != nil ? defaults.integer(forKey: Keys.goal) : 10_000 }
        set { defaults.set(newValue, forKey: Keys.goal) }
    }

    static var calibration: CalibrationResult {
        get { defaults.data(forKey: Keys.calibration).flatMap { try? JSONDecoder().decode(CalibrationResult.self, from: $0) } ?? .empty }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: Keys.calibration) }
    }

    /// Ultimo conteggio letto da Salute, con il giorno a cui si riferisce.
    static func saveSteps(_ steps: Int, now: Date = Date(), calendar: Calendar = .current) {
        defaults.set(steps, forKey: Keys.lastSteps)
        defaults.set(calendar.startOfDay(for: now), forKey: Keys.lastStepsDay)
    }

    /// L'ultimo conteggio, solo se è di oggi.
    static func cachedStepsToday(now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let day = defaults.object(forKey: Keys.lastStepsDay) as? Date,
              calendar.isDate(day, inSameDayAs: now),
              defaults.object(forKey: Keys.lastSteps) != nil else { return nil }
        return defaults.integer(forKey: Keys.lastSteps)
    }
}
