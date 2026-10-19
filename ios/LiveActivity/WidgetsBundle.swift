import SwiftUI
import WidgetKit

/// Punto di ingresso dell'estensione: widget «Passi di oggi» (piccolo, medio e blocco schermo).
@main
struct StepTellerWidgets: WidgetBundle {
    var body: some Widget {
        StepsWidget()
    }
}
