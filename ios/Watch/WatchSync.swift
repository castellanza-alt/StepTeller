import Foundation
import WatchConnectivity
import WidgetKit

/// Watch side of the iPhone link: receives the settings (`WatchPayload`), keeps them in the App Group for the app
/// and the complications and tells the app when something changed. The last context received survives
/// relaunches, so the watch works with the phone far away.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()
    private var onChange: (@Sendable () -> Void)?

    func start(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func apply(_ context: [String: Any]) {
        guard !context.isEmpty, WatchPayload.apply(context) else { return }
        WidgetCenter.shared.reloadAllTimelines()
        onChange?()
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }
}
