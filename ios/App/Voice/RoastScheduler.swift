import Foundation
import UserNotifications
import StepTellerCore

/// The roast notifications (T-022 §3, `RoastPlan`): at every opening and Health wake-up the rest of the day is
/// planned again with the numbers of now; none with Normale or with the goal reached. Their own identifier prefix
/// (`stepteller.roast.`): reminder and events are never touched. iOS keeps at most 64 pending local notifications:
/// at most 7 of these, plus 7 reminders and the few events, stay far below.
enum RoastScheduler {
    struct Input: Sendable {
        let now: Date
        /// Steps really read from Health: without them nothing changes (no plan from an empty count).
        let known: Bool
        let level: NastyLevel
        let frequency: RoastFrequency
        let catalog: NastyCatalog?
        let day: NastyMoment.Day
        let salt: UInt64
    }

    /// Key of the line in the notification (to know, later, which ones were delivered).
    static let lineKey = "line"

    static func update(_ input: Input, calendar: Calendar = .current) async {
        // a voice in force but no count read: the plan of the last read stays (Normale still withdraws)
        guard input.known || input.level == .normale else { return }
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(RoastPlan.notificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus),
              input.level != .normale, let catalog = input.catalog else { return }

        // today's delivered ones: their lines are seen, and the next one keeps 90 minutes from the last
        let delivered = await center.deliveredNotifications()
            .filter { $0.request.identifier.hasPrefix(RoastPlan.notificationPrefix) && calendar.isDate($0.date, inSameDayAs: input.now) }
        let last = delivered.map(\.date).max()
        // read and written with no wait in between: the lines Home records meanwhile are not lost
        var memory = SharedStore.nastyMemory
        for note in delivered {
            if let id = note.request.content.userInfo[lineKey] as? String, !memory.recent(input.level).contains(id) {
                memory.record(id, level: input.level)
            }
        }
        SharedStore.nastyMemory = memory

        let items = RoastPlan.plan(now: input.now, calendar: calendar, level: input.level, frequency: input.frequency,
                                   catalog: catalog, day: input.day, lastDelivered: last, memory: memory,
                                   salt: input.salt, format: LocalFormat.integer)
        for item in items {
            let content = UNMutableNotificationContent()
            if let title = item.quote.title { content.title = title }
            content.body = item.quote.text
            content.sound = .default
            content.userInfo = [lineKey: item.quote.id]
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
        NastyVoice.log.notice("roast: \(items.count) planned (\(input.level.rawValue), \(input.frequency.rawValue))")
    }

}

/// The catalog file from the site: a plain GET of a public file. No cookie, no cache, no identifier, no data of
/// the user (T-026 §2); a generic User-Agent instead of the one with the app's name and version.
enum CatalogDownload {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.httpCookieAcceptPolicy = .never
        c.httpShouldSetCookies = false
        c.httpCookieStorage = nil
        c.urlCache = nil
        c.urlCredentialStorage = nil
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 40
        // generic: no app version, no phone language
        c.httpAdditionalHeaders = ["User-Agent": "NEAT", "Accept-Language": "*"]
        return URLSession(configuration: c)
    }()

    /// The file, or nil (no network, not found, too big). Never more than 1 MB.
    static func fetch(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200, data.count < 1_000_000 else {
            NastyVoice.log.notice("voice: \(url.lastPathComponent) not downloaded")
            return nil
        }
        return data
    }
}
