import SwiftUI
import StepTellerCore

enum AppTab { case oggi, storico }

/// Radice dell'app: la pagina scelta su fondo carta. Da Oggi si va allo Storico con la bandierina,
/// dallo Storico si torna con le impronte.
struct RootView: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: AppTab
    @State private var showSettings: Bool
    /// Giorno (yyyy-MM-dd) dell'ultima festa «Obiettivo raggiunto»: una sola al giorno.
    @AppStorage("stepteller.celebratedDay") private var celebratedDay = ""
    @State private var celebrating = false

    init() {
        var t = AppTab.oggi
        var sheet = false
        #if DEBUG
        let d = UserDefaults.standard
        if d.string(forKey: "stepteller.debugTab") != nil { t = .storico }   // «storico» o «streak»
        sheet = d.object(forKey: "stepteller.debugSheet") != nil
        #endif
        _tab = State(initialValue: t)
        _showSettings = State(initialValue: sheet)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Group {
                switch tab {
                case .oggi:
                    OggiView(onSettings: { showSettings = true }, onHistory: { go(.storico) })
                        .transition(.move(edge: .leading).combined(with: .opacity))
                case .storico:
                    HistoryView(onSettings: { showSettings = true }, onToday: { go(.oggi) })
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard)

            if celebrating {
                GoalCelebration(steps: store.steps, goal: store.goal, streak: store.history.streak.streak) {
                    celebrating = false
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .task { await store.start() }
        .onAppear { celebrateIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await store.becameActive() }
                else if phase == .background { store.becameInactive() }
            }
            if phase == .active { celebrateIfNeeded() }
        }
        .onChange(of: store.plan.isDone) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.lastUpdate) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.history.loaded) { _, _ in celebrateIfNeeded() }
        .sheet(isPresented: $showSettings) { SettingsSheet().preferredColorScheme(store.appearance.scheme) }
        .preferredColorScheme(store.appearance.scheme)
    }
}

extension RootView {
    private func go(_ value: AppTab) {
        withAnimation(.easeInOut(duration: 0.3)) { tab = value }
    }

    /// Festa alla prima apertura dopo aver chiuso l'obiettivo del giorno (solo con i passi di Salute,
    /// non con una correzione manuale).
    private func celebrateIfNeeded() {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "stepteller.debugCelebrate") != nil, !celebrating {
            celebrating = true; return
        }
        #endif
        // solo con una lettura di oggi: al risveglio il numero può essere ancora quello di ieri
        guard scenePhase == .active, !celebrating, store.goal > 0, store.plan.isDone, store.origin == .health,
              store.history.loaded,      // senza lo storico la streak risulterebbe 1
              let read = store.lastUpdate, Calendar.current.isDateInToday(read)
        else { return }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        guard celebratedDay != today else { return }
        celebratedDay = today
        withAnimation(.easeOut(duration: 0.25)) { celebrating = true }
    }
}

extension AppAppearance {
    /// `nil` = segue il sistema.
    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
