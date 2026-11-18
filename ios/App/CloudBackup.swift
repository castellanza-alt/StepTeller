import Foundation
import StepTellerCore

/// Copy of the app's few saved values in the user's iCloud (key-value store): after deleting and reinstalling
/// the app, or on a new iPhone with the same Apple Account, streak start, goal history and settings come back.
/// Only values the app already keeps in UserDefaults, never Health data. No server of ours: Apple's iCloud.
@MainActor
enum CloudBackup {
    /// Saved values that travel to iCloud. Not the introduction flags: after a reinstall the permissions
    /// of Health and notifications are gone, so the introduction must show again to ask for them.
    static let keys = [
        "stepteller.goal", "stepteller.goalHistory", "stepteller.streak.start", "stepteller.speed",
        "stepteller.units", "stepteller.reminder.on", "stepteller.reminder.minutes", "stepteller.calibration.v1",
        ThemeMode.storageKey, "stepteller.events.on", "stepteller.seasonal", giftsKey,
    ]
    private static let streakStartKey = "stepteller.streak.start"
    /// Christmas gifts received (`JollyGift.Ledger.days`): merged both ways, a season received anywhere stays.
    private static let giftsKey = "stepteller.jollyGifts"

    private static func gifts(_ value: Any?) -> JollyGift.Ledger {
        JollyGift.Ledger(days: value as? [String: String] ?? [:])
    }

    private static let cloud = NSUbiquitousKeyValueStore.default
    private static var observers: [NSObjectProtocol] = []
    private static var defaults = UserDefaults.standard
    /// iCloud has had its chance to bring back the saved values: true right away when the store already holds
    /// values here (every launch after the first sync), otherwise at iCloud's first sync after a (re)install or
    /// after `settleTimeout` (no iCloud account, offline). The Christmas gift waits for it, so a reinstall does
    /// not give it again only because iCloud has not answered yet (D-040).
    private(set) static var settled = skipped

    /// Debug runs with fake data or a simulated date never touch iCloud (and the store skips `start`).
    private static var skipped: Bool {
        #if DEBUG
        let d = UserDefaults.standard
        return d.object(forKey: "stepteller.debugSteps") != nil || HistoryStore.debugGifts
        #else
        return false
        #endif
    }
    static let settleTimeout: Duration = .seconds(15)

    /// At launch, before creating `StepsStore`: brings back from iCloud what is missing here, then keeps iCloud
    /// up to date. `onRestore` runs when iCloud brings values later (first sync after a reinstall).
    /// `onSettled` runs once, when `settled` becomes true later than the launch.
    static func start(_ defaults: UserDefaults = .standard, onRestore: @escaping @MainActor () -> Void,
                      onSettled: @escaping @MainActor () -> Void = {}) {
        #if DEBUG
        // Screenshots and tests with fake data or a simulated date: iCloud is neither read nor written.
        if skipped { return }
        #endif
        guard observers.isEmpty else { return }
        Self.defaults = defaults
        cloud.synchronize()
        settled = !cloud.dictionaryRepresentation.isEmpty
        restore(defaults)
        upload(defaults)
        func settle() {
            guard !settled else { return }
            settled = true
            onSettled()
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                if restore(Self.defaults) { onRestore() }
                settle()
            }
        })
        if !settled {
            Task { @MainActor in
                try? await Task.sleep(for: settleTimeout)
                settle()
            }
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: defaults, queue: .main
        ) { _ in
            MainActor.assumeIsolated { upload(Self.defaults) }
        })
    }

    /// Values saved on this phone only (not launch arguments, which UserDefaults also returns).
    private static func saved(_ defaults: UserDefaults) -> [String: Any] {
        Bundle.main.bundleIdentifier.flatMap { defaults.persistentDomain(forName: $0) } ?? [:]
    }

    /// Copies from iCloud the values missing here. The streak start is the earliest of the two: a fresh install
    /// saves «today», iCloud remembers the real start. Returns `true` if something changed.
    @discardableResult
    static func restore(_ defaults: UserDefaults) -> Bool {
        let local = saved(defaults)
        var changed = false
        for key in keys {
            guard let remote = cloud.object(forKey: key) else { continue }
            if let here = local[key] {
                if key == giftsKey {
                    let merged = gifts(here).merged(with: gifts(remote))
                    if merged != gifts(here) { defaults.set(merged.days, forKey: key); changed = true }
                } else if key == streakStartKey, let r = remote as? Date, let h = here as? Date, r < h {
                    defaults.set(r, forKey: key)
                    changed = true
                }
            } else {
                defaults.set(remote, forKey: key)
                changed = true
            }
        }
        return changed
    }

    /// Sends to iCloud the values that differ. The streak start never moves forward in iCloud.
    private static func upload(_ defaults: UserDefaults) {
        let local = saved(defaults)
        for key in keys {
            guard let value = local[key] else { continue }
            let remote = cloud.object(forKey: key)
            if let remote = remote as? NSObject, remote.isEqual(value) { continue }
            if key == streakStartKey, let r = remote as? Date, let v = value as? Date, r < v { continue }
            if key == giftsKey {
                let merged = gifts(value).merged(with: gifts(remote))
                if merged != gifts(remote) { cloud.set(merged.days, forKey: key) }
                continue
            }
            cloud.set(value, forKey: key)
        }
    }
}
