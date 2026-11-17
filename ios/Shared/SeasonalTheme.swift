import Foundation
import StepTellerCore

/// Which seasonal theme is in force (D-037): the switch in Settings (on by default, copied in the App Group so the
/// widget reads it) and the date. The app, the splash and the widget all ask here.
enum SeasonalTheme {
    static func active(now: Date = Date(), calendar: Calendar = .current) -> Season? {
        #if DEBUG
        // Screenshots and QA: `-stepteller.season christmas` (or `none`), copied in the App Group by the app.
        if let forced = SharedStore.forcedSeason { return Season.named(forced) }
        #endif
        guard SharedStore.seasonalOn else { return nil }
        return Season.active(on: now, calendar: calendar)
    }
}
