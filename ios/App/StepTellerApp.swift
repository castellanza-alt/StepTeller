import SwiftUI
import StepTellerCore

@main
struct StepTellerApp: App {
    @State private var store = StepTellerApp.makeStore()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if UserDefaults.standard.object(forKey: "stepteller.debugWidget") != nil {
                WidgetPreviewScreen()          // Debug only: widget preview for the screenshots
            } else {
                root
            }
            #else
            root
            #endif
        }
    }

    private var root: some View { RootView().environment(store) }

    @MainActor
    private static func makeStore() -> StepsStore {
        // Before creating the store: recognizes who already had the app from the saved keys.
        Onboarding.resolveAtLaunch()
        #if DEBUG
        // Debug only (simulator screenshots/tests): `-stepteller.debugSteps 7200`.
        if UserDefaults.standard.object(forKey: "stepteller.debugSteps") != nil {
            // `-stepteller.debugSteps -1`: Health without data (warning in Home).
            let raw = UserDefaults.standard.integer(forKey: "stepteller.debugSteps")
            let n = max(0, raw)
            if UserDefaults.standard.object(forKey: "stepteller.debugHistory") != nil {
                let start = Calendar.current.date(byAdding: .day, value: -23, to: Calendar.current.startOfDay(for: Date()))
                return StepsStore(provider: DebugStepsProvider(value: n), historyProvider: DebugHistoryProvider(todaySteps: n),
                                  streakStartOverride: start)
            }
            return StepsStore(provider: DebugStepsProvider(value: raw < 0 ? nil : n))
        }
        #endif
        let health = HealthKitStepsProvider()
        return StepsStore(provider: health, workouts: health, historyProvider: health)
    }
}
