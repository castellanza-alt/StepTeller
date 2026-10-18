import SwiftUI
import StepTellerCore

/// Radice dell'app: tema (giorno/notte), la schermata scelta (Home ↔ Storico con transizione
/// orizzontale), la barra superiore fissa e la festa dell'obiettivo.
struct RootView: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var systemScheme
    @AppStorage(ThemeMode.storageKey) private var themeModeRaw = ThemeMode.system.rawValue
    @State private var screen: AppScreen
    @State private var showSettings: Bool
    @State private var storicoScrolled = false
    /// Giorno (yyyy-MM-dd) dell'ultima festa «Obiettivo raggiunto»: una sola al giorno.
    @AppStorage("stepteller.celebratedDay") private var celebratedDay = ""
    @State private var celebrating = false

    init() {
        var s = AppScreen.home
        var sheet = false
        #if DEBUG
        let d = UserDefaults.standard
        if d.string(forKey: "stepteller.debugTab") != nil { s = .storico }
        sheet = d.object(forKey: "stepteller.debugSheet") != nil
        #endif
        _screen = State(initialValue: s)
        _showSettings = State(initialValue: sheet)
    }

    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .system }

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let palette = MangaPalette.of(themeMode.resolve(systemScheme: systemScheme, now: timeline.date))
            GeometryReader { geo in
                let size = CGSize(width: geo.size.width,
                                  height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
                let s = size.width / Manga.frameWidth
                let rowTop = max(Manga.statusBarHeight, geo.safeAreaInsets.top / s)
                ZStack(alignment: .top) {
                    palette.paper
                    Group {
                        switch screen {
                        case .home:
                            HomeView(size: size)
                                .transition(.move(edge: .leading))
                        case .storico:
                            StoricoView(size: size, scrolled: $storicoScrolled)
                                .transition(.move(edge: .trailing))
                        }
                    }
                    MangaCanvas(width: size.width, height: rowTop + Manga.topBarHeight - Manga.statusBarHeight) {
                        TopBar(screen: screen, streak: store.history.streak.streak, jolly: store.history.streak.jolly,
                               storicoScrolled: storicoScrolled, rowTop: rowTop,
                               onNav: navigate, onSettings: { showSettings = true })
                    }
                    if celebrating {
                        GoalCelebration(steps: store.steps, goal: store.goal, streak: store.history.streak.streak) {
                            celebrating = false
                        }
                        .transition(.opacity)
                        .zIndex(1)
                    }
                }
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
            }
            .environment(\.manga, palette)
            .preferredColorScheme(themeMode == .system ? nil : palette.colorScheme)
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
                    .environment(\.manga, palette)
                    .preferredColorScheme(themeMode == .system ? nil : palette.colorScheme)
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
    }

    private func navigate() {
        withAnimation(.easeInOut(duration: Manga.navDuration)) {
            screen = screen == .home ? .storico : .home
        }
        if screen == .home { storicoScrolled = false }
    }
}

extension RootView {
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
              let read = store.lastUpdate, Calendar.current.isDateInToday(read)
        else { return }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        guard celebratedDay != today else { return }
        celebratedDay = today
        withAnimation(.easeOut(duration: 0.25)) { celebrating = true }
    }
}
