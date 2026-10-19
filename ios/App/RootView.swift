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
    /// Giorno (yyyy-MM-dd) dell'ultima festa «Obiettivo raggiunto»: una sola al giorno.
    @AppStorage("stepteller.celebratedDay") private var celebratedDay = ""
    @State private var celebrating = false
    /// Ultima apertura (o ritorno in primo piano): la festa aspetta uno storico riletto da allora,
    /// altrimenti la serie mostrerebbe solo oggi («1 giorno di fila»).
    @State private var activeSince = Date()

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
                            // i gesti dei figli (cursore sulla strada) hanno la precedenza sullo swipe
                            HomeView(size: size)
                                .contentShape(Rectangle())
                                .gesture(swipe(to: .storico))
                                .transition(.move(edge: .leading))
                        case .storico:
                            // simultaneo, altrimenti blocca lo scorrimento verticale
                            StoricoView(size: size)
                                .simultaneousGesture(swipe(to: .home))
                                .transition(.move(edge: .trailing))
                        }
                    }
                    MangaCanvas(width: size.width, height: rowTop + Manga.topBarHeight - Manga.statusBarHeight) {
                        TopBar(screen: screen, streak: store.history.streak.streak, jolly: store.history.streak.jolly,
                               rowTop: rowTop,
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
        .onOpenURL { url in
            // widget: `stepteller://oggi` apre la Home
            guard url.scheme == "stepteller", url.host == "oggi", screen != .home else { return }
            navigate()
        }
        .task { await store.start() }
        .onAppear { celebrateIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await store.becameActive() }
                else if phase == .background { store.becameInactive() }
            }
            if phase == .active { activeSince = Date(); celebrateIfNeeded() }
        }
        .onChange(of: store.plan.isDone) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.lastUpdate) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.history.refreshedAt) { _, _ in celebrateIfNeeded() }
    }

    private func navigate() {
        withAnimation(.easeInOut(duration: Manga.navDuration)) {
            screen = screen == .home ? .storico : .home
        }
    }

    /// Swipe orizzontale: verso sinistra dalla Home allo Storico, verso destra dallo Storico alla Home.
    /// Basta uno spostamento deciso o un colpo veloce, purché più orizzontale che verticale.
    private func swipe(to target: AppScreen) -> some Gesture {
        DragGesture(minimumDistance: 24).onEnded { v in
            guard screen != target else { return }
            let dx = target == .storico ? -v.translation.width : v.translation.width
            let flick = target == .storico ? -v.predictedEndTranslation.width : v.predictedEndTranslation.width
            guard abs(v.translation.width) > abs(v.translation.height) * 1.5, dx > 70 || flick > 160 else { return }
            navigate()
        }
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
              let read = store.lastUpdate, Calendar.current.isDateInToday(read),
              let history = store.history.refreshedAt, history >= activeSince
        else { return }
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let today = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        guard celebratedDay != today else { return }
        celebratedDay = today
        withAnimation(.easeOut(duration: 0.25)) { celebrating = true }
    }
}
