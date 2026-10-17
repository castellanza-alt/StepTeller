#if DEBUG
import SwiftUI
import StepTellerCore

/// Solo build Debug: mostra il widget ingrandito (come nei mockup) per verificarlo negli screenshot
/// del simulatore. Argomenti di avvio: `-stepteller.debugWidget 1 -stepteller.debugSteps 7200`
/// (senza `debugSteps`: stato «dato non disponibile»).
struct WidgetPreviewScreen: View {
    var body: some View {
        let d = UserDefaults.standard
        let plan: Plan? = d.object(forKey: "stepteller.debugSteps") != nil
            ? Plan(goal: 10_000, steps: d.integer(forKey: "stepteller.debugSteps"), speed: Plan.glanceSpeed,
                   model: CalibrationResult.empty.model)
            : nil
        ZStack {
            Theme.ink.opacity(0.08).ignoresSafeArea()
            StepsWidgetView(plan: plan)
                .frame(width: 170, height: 170)
                .background(StepsWidgetBackground())
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.cardLine, lineWidth: 0.5))
                .scaleEffect(2.2)
        }
    }
}
#endif
