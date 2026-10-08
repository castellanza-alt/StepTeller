import SwiftUI
import StepTellerCore

@main
struct StepTellerApp: App {
    @State private var store = StepTellerApp.makeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
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
