import Foundation
import StepTellerCore

/// What the iPhone sends to the Apple Watch (WatchConnectivity «application context»: the last value wins and
/// waits for the watch when it is not reachable): the settings the watch cannot know by itself. Today's steps are
/// read from Health on the watch; nothing travels back and no Health data travels at all.
/// On the watch the payload is stored in the App Group (`SharedStore`), so app and complications read it the same
/// way the iPhone widget does. Keys are stable: never renamed.
enum WatchPayload {
    private enum Keys {
        static let goal = "goal"
        static let speed = "speed"
        static let units = "units"
        static let streak = "streak"
        static let jolly = "jolly"
        static let calibration = "calibration"
    }

    /// iPhone side: the current settings from the App Group.
    static func current() -> [String: Any] {
        var payload: [String: Any] = [
            Keys.goal: SharedStore.goal,
            Keys.speed: SharedStore.speed,
            Keys.units: SharedStore.unitPreference.rawValue,
            Keys.streak: SharedStore.streak,
            Keys.jolly: SharedStore.jolly,
        ]
        if let data = try? JSONEncoder().encode(SharedStore.calibration) { payload[Keys.calibration] = data }
        return payload
    }

    /// Same content (property-list values compare by value).
    static func same(_ a: [String: Any], _ b: [String: Any]) -> Bool {
        NSDictionary(dictionary: a).isEqual(to: b)
    }

    /// Watch side: stores the received settings. Returns `true` if something changed (then the screen and the
    /// complications reload). Unknown or malformed values are ignored, one by one.
    @discardableResult
    static func apply(_ payload: [String: Any]) -> Bool {
        var changed = false
        if let goal = payload[Keys.goal] as? Int, goal >= 0, goal != SharedStore.goal {
            SharedStore.goal = goal; changed = true
        }
        if let speed = payload[Keys.speed] as? Double, DistanceUnit.kmhRange.contains(speed), speed != SharedStore.speed {
            SharedStore.speed = speed; changed = true
        }
        if let raw = payload[Keys.units] as? String, let units = UnitPreference(rawValue: raw), units != SharedStore.unitPreference {
            SharedStore.unitPreference = units; changed = true
        }
        if let streak = payload[Keys.streak] as? Int, streak >= 0, streak != SharedStore.streak {
            SharedStore.streak = streak; changed = true
        }
        if let jolly = payload[Keys.jolly] as? Int, jolly >= 0, jolly != SharedStore.jolly {
            SharedStore.jolly = jolly; changed = true
        }
        if let data = payload[Keys.calibration] as? Data,
           let calibration = try? JSONDecoder().decode(CalibrationResult.self, from: data),
           calibration != SharedStore.calibration {
            SharedStore.calibration = calibration; changed = true
        }
        return changed
    }
}
