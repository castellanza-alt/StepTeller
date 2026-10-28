import SwiftUI
import StepTellerCore

enum AppScreen { case home, history }

/// Root of the app: theme (day/night), the chosen screen (Home ↔ History with a horizontal transition),
/// the fixed top bar and the goal celebration.
struct RootView: View {
    @Environment(StepsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var systemScheme
    @AppStorage(ThemeMode.storageKey) private var themeModeRaw = ThemeMode.system.rawValue
    @State private var screen: AppScreen
    @State private var showSettings: Bool
    /// Day (yyyy-MM-dd) of the last «Goal reached» celebration: one per day.
    @AppStorage("stepteller.celebratedDay") private var celebratedDay = ""
    @State private var celebrating = false
    /// Last launch (or return to the foreground): the celebration waits for a history reread since then,
    /// otherwise the streak would show today only («1 day in a row»).
    @State private var activeSince = Date()
    /// Introduction: at first launch until completed; afterwards only when asked from Settings.
    @AppStorage(Onboarding.doneKey) private var onboardingDone = false
    @State private var replayingIntro = false
    @State private var introStartPage = 0
    /// Debug only: with fake steps (screenshots) the introduction does not show, unless `debugOnboarding`.
    private let skipIntro: Bool

    init() {
        var s = AppScreen.home
        var sheet = false
        var intro = false
        var introPage = 0
        var skip = false
        #if DEBUG
        let d = UserDefaults.standard
        if d.string(forKey: "stepteller.debugTab") != nil { s = .history }
        sheet = d.object(forKey: "stepteller.debugSheet") != nil
        // Screenshots: `-stepteller.debugOnboarding 1…4` opens the introduction on that page.
        if d.object(forKey: "stepteller.debugOnboarding") != nil {
            intro = true
            introPage = min(max(d.integer(forKey: "stepteller.debugOnboarding"), 1), Onboarding.pageCount) - 1
        } else if ProcessInfo.processInfo.arguments.contains("-stepteller.debugSteps") {
            skip = true                    // also with `-1`, which UserDefaults does not read as a value
        }
        #endif
        _screen = State(initialValue: s)
        _showSettings = State(initialValue: sheet)
        _replayingIntro = State(initialValue: intro)
        _introStartPage = State(initialValue: introPage)
        skipIntro = skip
    }

    private var showsIntro: Bool { (!onboardingDone && !skipIntro) || replayingIntro }

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
                    if !showsIntro {
                    Group {
                        switch screen {
                        case .home:
                            // child gestures (slider on the road) take precedence over the swipe
                            HomeView(size: size)
                                .contentShape(Rectangle())
                                .gesture(swipe(to: .history))
                                .transition(.move(edge: .leading))
                        case .history:
                            // simultaneous, otherwise it blocks vertical scrolling
                            HistoryView(size: size)
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
                }
                .frame(width: size.width, height: size.height)
                .ignoresSafeArea()
            }
            .overlay {
                // outside the full-screen canvas: respects safe areas and keyboard
                if showsIntro {
                    OnboardingView(startPage: introStartPage, isReplay: onboardingDone) {
                        withAnimation(.easeInOut(duration: Manga.navDuration)) {
                            onboardingDone = true
                            replayingIntro = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .environment(\.manga, palette)
            .preferredColorScheme(themeMode == .system ? nil : palette.colorScheme)
            .sheet(isPresented: $showSettings) {
                SettingsSheet(onReplayIntro: {
                    showSettings = false
                    introStartPage = 0
                    withAnimation(.easeInOut(duration: Manga.navDuration)) { replayingIntro = true }
                })
                    .environment(\.manga, palette)
                    .preferredColorScheme(themeMode == .system ? nil : palette.colorScheme)
            }
        }
        .onOpenURL { url in
            // widget: `stepteller://oggi` opens Home
            guard url.scheme == "stepteller", url.host == "oggi", screen != .home else { return }
            navigate()
        }
        // Health, observation and reminders start only once the introduction is done.
        .task(id: showsIntro) { if !showsIntro { await store.start() } }
        .onAppear { celebrateIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await store.becameActive() }
                else if phase == .background { await store.becameInactive() }
            }
            if phase == .active { activeSince = Date(); celebrateIfNeeded() }
        }
        .onChange(of: store.plan.isDone) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.lastUpdate) { _, _ in celebrateIfNeeded() }
        .onChange(of: store.history.refreshedAt) { _, _ in celebrateIfNeeded() }
    }

    private func navigate() {
        withAnimation(.easeInOut(duration: Manga.navDuration)) {
            screen = screen == .home ? .history : .home
        }
    }

    /// Horizontal swipe: leftwards from Home to History, rightwards from History to Home.
    /// A decided move or a quick flick is enough, as long as it is more horizontal than vertical.
    private func swipe(to target: AppScreen) -> some Gesture {
        DragGesture(minimumDistance: 24).onEnded { v in
            guard screen != target else { return }
            let dx = target == .history ? -v.translation.width : v.translation.width
            let flick = target == .history ? -v.predictedEndTranslation.width : v.predictedEndTranslation.width
            guard abs(v.translation.width) > abs(v.translation.height) * 1.5, dx > 70 || flick > 160 else { return }
            navigate()
        }
    }
}

extension RootView {
    /// Celebration at the first launch after reaching the day's goal (only with Health steps).
    private func celebrateIfNeeded() {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "stepteller.debugCelebrate") != nil, !celebrating {
            celebrating = true; return
        }
        #endif
        // only with a read of today: on wake-up the number may still be yesterday's
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
