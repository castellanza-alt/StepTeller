import SwiftUI

extension Binding where Value == Date {
    /// Reminder time (minutes from midnight) as today's `Date` for the `DatePicker`: only hour and minute matter.
    /// Used by Settings and by the introduction.
    static func reminderTime(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding<Date> {
            Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60,
                                  second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (c.hour ?? 20) * 60 + (c.minute ?? 30)
        }
    }
}
