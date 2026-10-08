import SwiftUI
import StepTellerCore

/// Foglio con l'unica impostazione dell'app: promemoria serale (acceso/spento e ora).
struct ReminderSheet: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 18) {
            Text("PROMEMORIA SERALE")
                .font(.system(size: 11, weight: .semibold)).tracking(11 * 0.24)
                .foregroundStyle(Theme.soft)
            Toggle("Avvisami la sera", isOn: $store.reminderEnabled)
                .tint(Theme.accent)
            DatePicker("Ora", selection: timeBinding, displayedComponents: .hourAndMinute)
                .disabled(!store.reminderEnabled)
                .opacity(store.reminderEnabled ? 1 : 0.4)
            Text("Se l'obiettivo non è chiuso, a quest'ora ricevi i minuti di tappeto che ti servono, calcolati con i passi di Salute. Tutto resta sul telefono.")
                .font(.system(size: 13)).foregroundStyle(Theme.soft)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.height(320)])
    }

    /// Ora del promemoria come `Date` (solo ora e minuti contano).
    private var timeBinding: Binding<Date> {
        Binding {
            let cal = Calendar.current
            return cal.date(bySettingHour: store.reminderMinutes / 60, minute: store.reminderMinutes % 60, second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 30)
        }
    }
}
