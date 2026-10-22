import SwiftUI
import UniformTypeIdentifiers
import StepTellerCore

/// Settings: daily goal, evening reminder, theme, units, streak and Jollies, backup, privacy and support links,
/// «Replay the introduction» and version.
struct SettingsSheet: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var goalFocused: Bool
    @State private var showRules = false
    @AppStorage(ThemeMode.storageKey) private var themeMode = ThemeMode.system.rawValue
    @State private var showImporter = false
    /// Backup read from the file, waiting for the confirmation.
    @State private var pendingBackup: BackupFile?
    /// Outcome of the import shown in an alert (done or error text).
    @State private var importMessage: String?
    /// «Replay the introduction»: closes Settings and shows it again.
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
                    .glassCard()
                    note(L10n.text("set.goal.note"))
                }

                section(L10n.text("set.reminder.section")) {
                    VStack(spacing: 0) {
                        Toggle(L10n.text("reminder.toggle"), isOn: $store.reminderEnabled).tint(Theme.accent)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        rowDivider
                        DatePicker(L10n.text("reminder.time"), selection: .reminderTime($store.reminderMinutes), displayedComponents: .hourAndMinute)
                            .disabled(!store.reminderEnabled).opacity(store.reminderEnabled ? 1 : 0.4)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .glassCard()
                    note(L10n.text("set.reminder.note"))
                }

                section(L10n.text("set.theme.section")) {
                    Picker(L10n.text("set.theme.section"), selection: $themeMode) {
                        ForEach(ThemeMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    note(L10n.text("set.theme.note"))
                }

                section(L10n.text("set.units.section")) {
                    Picker(L10n.text("set.units.section"), selection: $store.unitPreference) {
                        Text(L10n.text("set.units.auto")).tag(UnitPreference.automatic)
                        Text(L10n.text("set.units.km")).tag(UnitPreference.kilometers)
                        Text(L10n.text("set.units.mi")).tag(UnitPreference.miles)
                    }
                    .pickerStyle(.segmented)
                    note(L10n.text("set.units.note"))
                }

                section(L10n.text("set.streak.section")) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(L10n.text("set.streak.started")).foregroundStyle(Theme.ink)
                            Spacer()
                            Text(L10n.format("set.streak.startValue", startText, "\(HistoryStore.initialJolly)")).foregroundStyle(Theme.ink.opacity(0.62))
                        }
                        .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
                        rowDivider
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
                    .glassCard()
                }

                section(L10n.text("set.backup.section")) {
                    VStack(spacing: 0) {
                        ShareLink(item: BackupExport(file: store.makeBackup()),
                                  preview: SharePreview(L10n.text("set.backup.export"))) {
                            row(L10n.text("set.backup.export"), symbol: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                        rowDivider
                        Button { goalFocused = false; showImporter = true } label: {
                            row(L10n.text("set.backup.import"), symbol: "square.and.arrow.down")
                        }
                        .buttonStyle(.plain)
                    }
                    .glassCard()
                    note(L10n.text("set.backup.note"))
                }

                section(L10n.text("set.info.section")) {
                    VStack(spacing: 0) {
                        linkRow(L10n.text("set.info.privacy"), Self.privacyURL)
                        rowDivider
                        linkRow(L10n.text("set.info.support"), Self.supportURL)
                        rowDivider
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
                    .glassCard()
                    note(L10n.format("set.version", appVersion))
                }
            }
            .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { readBackup($0) }
        .alert(L10n.text("set.backup.confirm.title"), isPresented: Binding(
            get: { pendingBackup != nil }, set: { if !$0 { pendingBackup = nil } }
        ), presenting: pendingBackup) { file in
            Button(L10n.text("common.cancel"), role: .cancel) {}
            Button(L10n.text("set.backup.confirm.ok")) {
                store.importBackup(file)
                importMessage = L10n.text("set.backup.done")
            }
        } message: { file in
            Text(L10n.format("set.backup.confirm.body", Self.startFormatter.string(from: file.exportedAt)))
        }
        .alert(importMessage ?? "", isPresented: Binding(
            get: { importMessage != nil }, set: { if !$0 { importMessage = nil } }
        )) {
            Button(L10n.text("set.backup.ok"), role: .cancel) {}
        }
    }

    /// Reads the chosen file (outside the app's sandbox: security-scoped access) and asks for confirmation.
    private func readBackup(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            pendingBackup = try BackupFile.decode(Data(contentsOf: url))
        } catch BackupFile.ReadError.newerVersion {
            importMessage = L10n.text("set.backup.error.newer")
        } catch {
            importMessage = L10n.text("set.backup.error")
        }
    }

    /// Row of a card with a symbol on the right.
    private func row(_ title: String, symbol: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.4))
        }
        .font(.system(size: 15)).padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    /// Rules, one per line with a bullet.
    private var rules: String {
        (1...5).map { "• " + L10n.text("set.rules.\($0)") }.joined(separator: "\n")
    }

    /// Start date of the streak in the phone's language («8 ottobre 2026», «October 8, 2026»).
    private var startText: String { Self.startFormatter.string(from: store.history.streakStart) }

    private static let startFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return f
    }()

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

    /// Thin line between the rows of a card.
    private var rowDivider: some View { Divider().overlay(Theme.ink.opacity(0.08)) }

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
}

private extension View {
    /// Settings card: glass background with a thin border, continuous corners.
    func glassCard() -> some View {
        background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
    }
}

/// Settings section label: 11 pt, semibold, spaced uppercase, muted color.
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

/// Backup file for the share sheet (Save to Files, AirDrop, Mail…): `NEAT-backup-2026-10-22.json`.
private struct BackupExport: Transferable {
    let file: BackupFile

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { item in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(item.fileName)
            try item.file.encoded().write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    private var fileName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return "NEAT-backup-\(f.string(from: file.exportedAt)).json"
    }
}
