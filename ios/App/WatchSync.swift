import Foundation
import WatchConnectivity

/// iPhone side of the Apple Watch link: sends goal, speed, units, streak, Jollies and calibration to the watch
/// app (`WatchPayload`) whenever they change. Nothing comes back and no Health data travels: the watch reads
/// today's steps from Health by itself.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    /// Activates the session once (at launch). Without a paired watch nothing happens.
    func start() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Sends the current settings if the watch app is installed and the content changed since the last send.
    func push() {
        guard let session, session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let payload = WatchPayload.current()
        guard !WatchPayload.same(payload, session.applicationContext) else { return }
        try? session.updateApplicationContext(payload)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        push()
    }

    /// The watch app has just been installed (or the watch changed): the settings go out right away.
    func sessionWatchStateDidChange(_ session: WCSession) {
        push()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Another watch was paired: the session is activated again for it.
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
