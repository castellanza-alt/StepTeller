import SwiftUI

/// Apple Watch app (1.2): one screen with today's steps and the settings received from the iPhone.
/// The complications live in the `StepTellerWatchWidgets` extension (same views as the iPhone lock screen).
@main
struct StepTellerWatchApp: App {
    @State private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView().environment(store)
        }
    }
}
