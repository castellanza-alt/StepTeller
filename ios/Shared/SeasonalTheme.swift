import Foundation
import StepTellerCore

/// Which seasonal theme is in force (D-037): the switch in Settings (on by default, copied in the App Group so the
/// widget reads it) and the date. The app, the splash and the widget all ask here.
enum SeasonalTheme {
    static func active(now: Date = AppClock.now(), calendar: Calendar = .current) -> Season? {
        #if DEBUG
        // `-stepteller.debugNow`: the simulated date wins over the one passed (RootView's timeline)
        let now = UserDefaults.standard.object(forKey: "stepteller.debugNow") != nil ? AppClock.now() : now
        // Screenshots and QA: `-stepteller.season christmas` (or `none`), copied in the App Group by the app.
        if let forced = SharedStore.forcedSeason { return Season.named(forced) }
        #endif
        guard SharedStore.seasonalOn else { return nil }
        return Season.active(on: now, calendar: calendar)
    }
}
