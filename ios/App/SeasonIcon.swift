import OSLog
import UIKit
import StepTellerCore

/// App icon of the season (D-037, D-040, §5 of `docs/design/T-015-natale.md`): iOS's own API, which shows its own alert;
/// nothing hides it. After the splash, at every return to the foreground and at the end of the introduction, but
/// only on a free screen (no celebration or pop-up, `RootView.watchIcon`), and right away from the switch in
/// Settings: the season's icon in the period with the switch on, the normal one otherwise. If the app is not opened after the period, the icon stays until the next
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
