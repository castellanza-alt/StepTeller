import SwiftUI
import StepTellerCore

/// Impostazioni: obiettivo giornaliero, promemoria serale, streak e Jolly, link a privacy e supporto,
/// «Rivedi l'introduzione» e versione.
struct SettingsSheet: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var goalFocused: Bool
    @State private var showRules = false
    @AppStorage(ThemeMode.storageKey) private var themeMode = ThemeMode.system.rawValue
    /// «Rivedi l'introduzione»: chiude le Impostazioni e la mostra di nuovo.
    var onReplayIntro: () -> Void = {}

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    SectionLabel(L10n.text("set.title"), tracking: 0.34)
                    Spacer()
                    Button(L10n.text("set.done")) { goalFocused = false; dismiss() }
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                }

                section(L10n.text("set.goal.section")) {
                    HStack {
                        roundButton("minus", L10n.text("goal.minus.vo")) { store.goal = max(500, store.goal - 500) }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            NumberField(value: store.goal, placeholder: "0", onEdit: { store.goal = $0 }, isFocused: $goalFocused)
                                .font(.system(size: 36, weight: .light)).tracking(-1).monospacedDigit()
                                .foregroundStyle(Theme.ink).fixedSize()
                                .accessibilityLabel(L10n.text("goal.field.vo"))
                            Text(L10n.text("goal.unit")).font(.system(size: 13)).foregroundStyle(Theme.soft)
                        }
                        Spacer()
                        roundButton("plus", L10n.text("goal.plus.vo")) { store.goal += 500 }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note(L10n.text("set.goal.note"))
                }

                section(L10n.text("set.reminder.section")) {
                    VStack(spacing: 0) {
                        Toggle(L10n.text("reminder.toggle"), isOn: $store.reminderEnabled).tint(Theme.accent)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        DatePicker(L10n.text("reminder.time"), selection: timeBinding, displayedComponents: .hourAndMinute)
                            .disabled(!store.reminderEnabled).opacity(store.reminderEnabled ? 1 : 0.4)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note(L10n.text("set.reminder.note"))
                }

                section(L10n.text("set.theme.section")) {
                    Picker(L10n.text("set.theme.section"), selection: $themeMode) {
                        ForEach(ThemeMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    note(L10n.text("set.theme.note"))
                }

                section(L10n.text("set.streak.section")) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(L10n.text("set.streak.started")).foregroundStyle(Theme.ink)
                            Spacer()
                            Text(L10n.format("set.streak.startValue", startText, "\(HistoryStore.initialJolly)")).foregroundStyle(Theme.ink.opacity(0.62))
                        }
                        .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        Button { withAnimation { showRules.toggle() } } label: {
                            HStack {
                                Text(L10n.text("set.streak.how")).foregroundStyle(Theme.ink)
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

                section(L10n.text("set.info.section")) {
                    VStack(spacing: 0) {
                        linkRow(L10n.text("set.info.privacy"), Self.privacyURL)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        linkRow(L10n.text("set.info.support"), Self.supportURL)
                        Divider().overlay(Theme.ink.opacity(0.08))
                        Button { goalFocused = false; onReplayIntro() } label: {
                            HStack {
                                Text(L10n.text("set.info.intro")).foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.4))
                            }
                            .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
                    note(L10n.format("set.version", appVersion))
                }
            }
            .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
    }

    /// Regole, una per riga con il punto elenco.
    private var rules: String {
        (1...5).map { "• " + L10n.text("set.rules.\($0)") }.joined(separator: "\n")
    }

    /// Data d'inizio della serie nella lingua del telefono («8 ottobre 2026», «October 8, 2026»).
    private var startText: String {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return f.string(from: store.history.streakStart)
    }

    private static let privacyURL = URL(string: "https://castellanza-alt.github.io/StepTeller/neat/privacy/")!
    private static let supportURL = URL(string: "https://castellanza-alt.github.io/StepTeller/neat/supporto/")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private func linkRow(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title).foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.4))
            }
            .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

/// Etichetta di sezione delle Impostazioni: 11 pt, semibold, maiuscolo spaziato, colore tenue.
struct SectionLabel: View {
    let text: String
    var tracking: CGFloat = 0.24
    init(_ text: String, tracking: CGFloat = 0.24) { self.text = text; self.tracking = tracking }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).tracking(11 * tracking)
            .foregroundStyle(Theme.soft)
    }
}
