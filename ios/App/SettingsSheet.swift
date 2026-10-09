import SwiftUI
import StepTellerCore

/// Impostazioni: obiettivo giornaliero, promemoria serale, informazioni su streak e Jolly.
struct SettingsSheet: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var goalFocused: Bool
    @State private var showRules = false

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    SectionLabel("Impostazioni", tracking: 0.34)
                    Spacer()
                    Button("Fine") { goalFocused = false; dismiss() }
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                }

                section("Obiettivo giornaliero") {
                    HStack {
                        roundButton("minus", "Diminuisci obiettivo") { store.goal = max(500, store.goal - 500) }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            NumberField(value: store.goal, placeholder: "0", onEdit: { store.goal = $0 }, isFocused: $goalFocused)
                                .font(.system(size: 36, weight: .light)).tracking(-1).monospacedDigit()
                                .foregroundStyle(Theme.ink).fixedSize()
                                .accessibilityLabel("Obiettivo passi")
                            Text("passi").font(.system(size: 13)).foregroundStyle(Theme.soft)
                        }
                        Spacer()
                        roundButton("plus", "Aumenta obiettivo") { store.goal += 500 }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note("Vale da oggi. I giorni passati restano valutati con l'obiettivo che avevi allora, quindi la streak non cambia.")
                }

                section("Promemoria serale") {
                    VStack(spacing: 0) {
                        Toggle("Avvisami la sera", isOn: $store.reminderEnabled).tint(Theme.accent)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        DatePicker("Ora", selection: timeBinding, displayedComponents: .hourAndMinute)
                            .disabled(!store.reminderEnabled).opacity(store.reminderEnabled ? 1 : 0.4)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note("Se l'obiettivo non è chiuso: i minuti che ti servono e, se serve, un avviso sulla streak o sul Jolly.")
                }

                section("Aspetto") {
                    Toggle("Mostra il tapis roulant", isOn: $store.showsTreadmill).tint(Theme.accent)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note("Spento: nella card di Oggi restano solo i minuti e la velocità.")
                }

                section("Streak e Jolly") {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Partita il").foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(startText) · \(HistoryStore.initialJolly) Jolly").foregroundStyle(Theme.ink.opacity(0.62))
                        }
                        .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        Button { withAnimation { showRules.toggle() } } label: {
                            HStack {
                                Text("Come funzionano").foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: showRules ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.4))
                            }
                            .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        if showRules {
                            Text(rules).font(.system(size: 13)).foregroundStyle(Theme.ink.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 16).padding(.bottom, 14)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                }
            }
            .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }

    private var rules: String {
        """
        • Un giorno è riuscito se i passi raggiungono l'obiettivo di quel giorno. Oggi non rompe mai la streak.
        • Ogni 15 giorni riusciti di fila matura 1 Jolly (nessun limite).
        • Se manchi un giorno, un Jolly salva la streak da solo: la streak resta, non aumenta e il conto verso il prossimo Jolly riparte da 0.
        • Senza Jolly, un giorno mancato azzera la streak. Il record resta.
        • Nessun Jolly viene speso se la streak è a 0.
        """
    }

    private var startText: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "d MMMM yyyy"
        return f.string(from: store.history.streakStart)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title)
            content()
        }
    }

    private func note(_ text: String) -> some View {
        Text(text).font(.system(size: 12)).foregroundStyle(Theme.soft).fixedSize(horizontal: false, vertical: true)
    }

    private func roundButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44).background(Circle().fill(Theme.ink.opacity(0.07)))
        }
        .accessibilityLabel(label)
    }

    /// Ora del promemoria come `Date` (solo ora e minuti contano).
    private var timeBinding: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: store.reminderMinutes / 60, minute: store.reminderMinutes % 60, second: 0, of: Date()) ?? Date()
        } set: { date in
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 30)
        }
    }
}
