import Foundation

/// «Now» for the seasonal theme and the Christmas gift. Always the real time, except in Debug with
/// `-stepteller.debugNow 2026-12-24T23:59` (local time): the clock starts there at launch and runs on, so the dates
/// of the gift and of the season can be checked on the Simulator (T-016).
enum AppClock {
    static func now() -> Date {
        #if DEBUG
        if let debug = debugStart { return debug.addingTimeInterval(Date().timeIntervalSince(launch)) }
        #endif
        return Date()
    }

    #if DEBUG
    private static let launch = Date()
    private static let debugStart: Date? = {
        guard let text = UserDefaults.standard.string(forKey: "stepteller.debugNow") else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f.date(from: text)
    }()
    #endif
}
