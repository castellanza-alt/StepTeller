import SwiftUI
import StepTellerCore

enum AppTab { case oggi, storico }

/// Radice dell'app: sfondo con gli orb, la pagina scelta e, in basso, la barra Oggi | Storico.
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
            OrbsBackground()
            Group {
                switch tab {
                case .oggi: OggiView(onSettings: { showSettings = true })
                case .storico: HistoryView(onSettings: { showSettings = true })
                }
            }
            VStack {
                Spacer()
                BottomBar(tab: $tab)
            }
            .ignoresSafeArea(edges: .bottom)
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
        .sheet(isPresented: $showSettings) { SettingsSheet() }
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

/// Barra in basso: il contenuto che scorre sotto sfuma e si sfoca prima di arrivare al selettore,
/// che ha uno sfondo pieno (mai sovrapposizioni).
struct BottomBar: View {
    @Binding var tab: AppTab

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle().fill(.regularMaterial)
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.5)],
                                     startPoint: .top, endPoint: .bottom))
            LinearGradient(stops: [.init(color: Theme.bg.opacity(0), location: 0),
                                   .init(color: Theme.bg.opacity(0.88), location: 0.5),
                                   .init(color: Theme.bg.opacity(0.96), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            HStack(spacing: 0) {
                item("OGGI", .oggi)
                item("STORICO", .storico)
            }
            .padding(4)
            .background(Capsule().fill(Theme.pill))
            .overlay(Capsule().strokeBorder(Theme.pillLine, lineWidth: 1))
            .padding(.top, 34)
        }
        .frame(height: 124)
    }

    private func item(_ title: String, _ value: AppTab) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { tab = value } } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold)).tracking(2.4)
                .foregroundStyle(tab == value ? Theme.accent : Theme.soft)
                .frame(width: 112, height: 40)
                .background(Capsule().fill(tab == value ? Theme.accentSoft : .clear))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title.capitalized)
        .accessibilityAddTraits(tab == value ? .isSelected : [])
    }
}
