import SwiftUI
import WidgetKit

/// Entry point of the extension: «Today's steps» widget (small, medium and lock screen).
@main
struct StepTellerWidgets: WidgetBundle {
    var body: some Widget {
        StepsWidget()
    }
}
