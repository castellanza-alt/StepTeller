import SwiftUI
import StepTellerCore

@main
struct StepTellerApp: App {
    @State private var store = StepTellerApp.makeStore()

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if UserDefaults.standard.object(forKey: "stepteller.debugWidget") != nil {
                    WidgetPreviewScreen()          // solo Debug: anteprima del widget per gli screenshot
                } else {
                    ContentView().environment(store)
                }
                #else
                ContentView().environment(store)
                #endif
            }
        }
    }

    @MainActor
    private static func makeStore() -> StepsStore {
        #if DEBUG
        // Solo Debug (screenshot/test sul simulatore): `-stepteller.debugSteps 7200`.
        if UserDefaults.standard.object(forKey: "stepteller.debugSteps") != nil {
            let n = UserDefaults.standard.integer(forKey: "stepteller.debugSteps")
            return StepsStore(provider: DebugStepsProvider(value: n))
        }
        #endif
        let health = HealthKitStepsProvider()
        return StepsStore(provider: health, workouts: health)
    }
}
