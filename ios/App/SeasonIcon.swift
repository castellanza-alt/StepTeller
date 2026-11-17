import OSLog
import UIKit
import StepTellerCore

/// App icon of the season (D-037, §6 of `docs/design/T-004-natale.md`): iOS's own API, which shows its own alert;
/// nothing hides it. At every return to the foreground, after the splash: the season's icon in the period with the
/// switch on, the normal one otherwise. If the app is not opened after the period, the icon stays until the next
/// opening (iOS limit, accepted).
@MainActor
enum SeasonIcon {
    private static let log = Logger(subsystem: "it.castellanza.stepteller", category: "season")

    static func update() {
        #if DEBUG
        // screenshots with fake steps: no system alert over the UI, unless `-stepteller.debugIcon 1` (queue checks)
        let d = UserDefaults.standard
        if d.object(forKey: "stepteller.debugSteps") != nil, d.object(forKey: "stepteller.debugIcon") == nil { return }
        #endif
        // not over the introduction (and its permission prompts): it is called again when the introduction ends
        guard UserDefaults.standard.bool(forKey: Onboarding.doneKey) else { return }
        let app = UIApplication.shared
        guard app.supportsAlternateIcons else { return }
        let wanted = SeasonalTheme.active().map { SeasonLook.of($0).iconName }
        guard app.alternateIconName != wanted else { return }
        app.setAlternateIconName(wanted) { error in
            if let error { log.error("icon \(wanted ?? "normal"): \(error.localizedDescription)") }
        }
    }

}
