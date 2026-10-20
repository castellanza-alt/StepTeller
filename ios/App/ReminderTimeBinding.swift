import SwiftUI

extension Binding where Value == Date {
    /// Ora del promemoria (minuti da mezzanotte) come `Date` di oggi per il `DatePicker`: contano solo ora e minuti.
    /// Usata dalle Impostazioni e dall'introduzione.
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
