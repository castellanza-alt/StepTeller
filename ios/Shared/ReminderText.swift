import Foundation
import StepTellerCore

/// Text of the evening reminder in the phone's language, from the «Widget» table (app and widget both have it):
/// one whole sentence from the catalog per case, speed in km/h or mph.
enum ReminderText {
    static func content(_ message: ReminderMessage, unit: DistanceUnit) -> ReminderContent {
        let t = L10n.widget
        switch message {
        case let .precise(minutes, speed, goal, remaining, warning):
            let args: [CVarArg] = ["\(minutes)", unit.speedText(kmh: speed),
                                   LocalFormat.integer(goal), LocalFormat.integer(remaining)]
            let body: String
            switch warning {
            case let .wouldUseJolly(left)?:
                body = L10n.format(unit.pick("n.body.jolly", "n.body.jolly.mi"), table: t, arguments: args + ["\(left)"])
            case let .wouldBreak(streak)?:
                body = L10n.format(unit.pick("n.body.lose", "n.body.lose.mi"), table: t, arguments: args + ["\(streak)"])
            case nil:
                body = L10n.format(unit.pick("n.body", "n.body.mi"), table: t, arguments: args)
            }
            return ReminderContent(title: L10n.text("n.title", table: t), body: body)
        case .generic:
            return ReminderContent(title: L10n.text("n.generic.title", table: t), body: L10n.text("n.generic.body", table: t))
        }
    }
}
