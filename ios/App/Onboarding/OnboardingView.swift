import SwiftUI
import StepTellerCore

/// Stato dell'introduzione al primo avvio (UserDefaults).
enum Onboarding {
    static let doneKey = "stepteller.onboarding.done"
    /// Permesso di Salute già chiesto (dall'introduzione o, per chi aveva già l'app, dal vecchio avvio).
    static let healthAskedKey = "stepteller.onboarding.healthAsked"
    static let pageCount = 4

    /// Chiavi che l'app salva da sempre: se ce n'è almeno una, l'app era già installata.
    private static let existingUserKeys = [
        "stepteller.goal", "stepteller.goalHistory", "stepteller.streak.start", "stepteller.speed",
        "stepteller.reminder.on", "stepteller.reminder.minutes", "stepteller.calibration.v1",
        ThemeMode.storageKey, "stepteller.celebratedDay",
    ]

    /// Da chiamare all'avvio **prima** di creare `StepsStore` (che salva subito l'inizio della serie).
    /// La prima volta decide una volta per tutte: utente esistente → introduzione già fatta, senza mostrarla.
    /// Guarda solo i valori salvati, non gli argomenti di avvio.
    static func resolveAtLaunch(_ defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: doneKey) == nil else { return }
        let saved = Bundle.main.bundleIdentifier.flatMap { defaults.persistentDomain(forName: $0) } ?? [:]
        let existing = existingUserKeys.contains { saved[$0] != nil }
        defaults.set(existing, forKey: doneKey)
        if existing { defaults.set(true, forKey: healthAskedKey) }
    }
}

/// Introduzione: benvenuto, Salute, obiettivo, promemoria. Le richieste di sistema partono qui, al
/// momento giusto; obiettivo e promemoria si salvano solo se l'utente li cambia.
struct OnboardingView: View {
    let isReplay: Bool
    let onFinish: () -> Void

    @Environment(StepsStore.self) private var store
    @Environment(\.manga) private var c
    @AppStorage(Onboarding.healthAskedKey) private var healthAsked = false
    @State private var page: Int
    @State private var goal = 10_000
    @State private var reminderOn = true
    @State private var reminderMinutes = 20 * 60 + 30
    @State private var loaded = false
    @State private var finishing = false
    @FocusState private var goalFocused: Bool

    init(startPage: Int = 0, isReplay: Bool, onFinish: @escaping () -> Void) {
        self.isReplay = isReplay
        self.onFinish = onFinish
        _page = State(initialValue: min(max(startPage, 0), Onboarding.pageCount - 1))
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 700
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome(compact).tag(0)
                    health(compact).tag(1)
                    goalPage(compact).tag(2)
                    reminder(compact).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(16, geo.safeAreaInsets.bottom > 0 ? 4 : 16))
            }
        }
        .background(c.paper.ignoresSafeArea())
        .onAppear {
            guard !loaded else { return }
            loaded = true
            goal = store.goal
            reminderOn = store.reminderEnabled
            reminderMinutes = store.reminderMinutes
        }
        .onChange(of: page) { old, new in
            goalFocused = false
            // Salute: si chiede lasciando la sua pagina, con «Continua» o con uno swipe.
            if old == 1, new > 1 { askHealthIfNeeded() }
        }
    }

    // MARK: - Pagine

    private func welcome(_ compact: Bool) -> some View {
        PageLayout(compact: compact) {
            WelcomeArt()
        } content: {
            Kicker(L10n.text("intro.1.kicker"))
            GlyphText(text: "NEAT", size: compact ? 84 : 110, lineHeight: 0.9, tracking: -0.02, fill: c.ink,
                      stroke: c.ink, strokeWidth: 2, shadow: (c.red, 6, 6))
                .manga(rotate: -5, skew: -10, anchor: UnitPoint(x: 0, y: 0.5))
                .accessibilityAddTraits(.isHeader)
            Text(L10n.text("intro.1.p1")).modifier(Paragraph())
            Text(L10n.text("intro.1.p2")).modifier(Paragraph())
        }
    }

    private func health(_ compact: Bool) -> some View {
        PageLayout(compact: compact) {
            Image(c.hill).resizable().scaledToFit().accessibilityHidden(true)
        } content: {
            Kicker(L10n.text("intro.2.kicker"))
            TitleText(L10n.text("intro.2.title"), compact: compact)
            Text(L10n.text("intro.2.p1")).modifier(Paragraph())
            Text(L10n.text("intro.2.p2")).modifier(Paragraph())
            Text(L10n.text("intro.2.note")).modifier(Paragraph(note: true))
        }
    }

    private func goalPage(_ compact: Bool) -> some View {
        PageLayout(compact: compact) {
            GoalBurst(goal: goal)
        } content: {
            Kicker(L10n.text("intro.3.kicker"))
            TitleText(L10n.text("intro.3.title"), compact: compact)
            goalControl
            Text(L10n.text("intro.3.note")).modifier(Paragraph(note: true))
        }
    }

    private func reminder(_ compact: Bool) -> some View {
        PageLayout(compact: compact) {
            Image(c.horizon).resizable().scaledToFit().accessibilityHidden(true)
        } content: {
            Kicker(L10n.text("intro.4.kicker"))
            TitleText(L10n.text("intro.4.title"), compact: compact)
            Text(L10n.text("intro.4.p1")).modifier(Paragraph())
            reminderControl
        }
    }

    // MARK: - Controlli

    private var goalControl: some View {
        HStack {
            stepButton("minus", L10n.text("goal.minus.vo")) { goal = max(500, goal - 500) }
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                NumberField(value: goal, placeholder: "0", onEdit: { goal = $0 }, isFocused: $goalFocused)
                    .font(.anton(44)).monospacedDigit().foregroundStyle(c.ink).fixedSize()
                    .accessibilityLabel(Text(L10n.text("goal.field.vo")))
                Text(L10n.text("goal.unit")).font(.antonText(18)).foregroundStyle(c.ink.opacity(0.6))
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 8)
            stepButton("plus", L10n.text("goal.plus.vo")) { goal += 500 }
        }
        .padding(.vertical, 6)
    }

    private func stepButton(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .heavy)).foregroundStyle(c.ink)
                .frame(width: 48, height: 48)
                .background(Circle().fill(c.paper))
                .overlay(Circle().strokeBorder(c.ink, lineWidth: 2.5))
                .contentShape(Circle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(label)
    }

    private var reminderControl: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $reminderOn) {
                Text(L10n.text("reminder.toggle")).font(.antonText(20)).foregroundStyle(c.ink)
            }
            .tint(c.red)
            .padding(.vertical, 8)
            Rectangle().fill(c.ink.opacity(0.15)).frame(height: 1.5)
            DatePicker(selection: .reminderTime($reminderMinutes), displayedComponents: .hourAndMinute) {
                Text(L10n.text("reminder.time")).font(.antonText(20)).foregroundStyle(c.ink)
            }
            .tint(c.red)
            .disabled(!reminderOn).opacity(reminderOn ? 1 : 0.4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Barra in basso

    private var isLast: Bool { page == Onboarding.pageCount - 1 }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            PageDots(count: Onboarding.pageCount, current: page)
            Spacer()
            Button(action: next) {
                AntonText(L10n.text(isLast ? "intro.start" : "intro.next"), 22, tracking: 0.08,
                          color: MangaPalette.onRed)
                    .padding(.horizontal, 30).padding(.vertical, 14)
                    .background(PercentPolygon.button.fill(RedGradient.fill(red: c.red, center: UnitPoint(x: 0.3, y: 0.2),
                                                                             size: 160, mid: 0.5)))
                    .shadow(color: MangaPalette.redButtonShadow, radius: 10, y: 8)
                    .rotationEffect(.degrees(-3))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScale())
            .disabled(finishing)
            .accessibilityLabel(Text(L10n.text(isLast ? "intro.start.vo" : "intro.next.vo")))
        }
        .frame(height: 76)
    }

    private func next() {
        goalFocused = false
        if isLast {
            finish()
        } else {
            withAnimation(.easeInOut(duration: Manga.navDuration)) { page += 1 }
        }
    }

    // MARK: - Permessi e salvataggio

    private func askHealthIfNeeded() {
        guard !healthAsked else { return }
        healthAsked = true
        Task { await store.requestHealthAccess() }
    }

    private func finish() {
        guard !finishing else { return }
        finishing = true
        Task {
            // Salute non chiesta se si è arrivati qui senza passare dalla sua pagina (es. debug).
            if !healthAsked { healthAsked = true; await store.requestHealthAccess() }
            // Notifiche: solo con il promemoria acceso, e iOS non le richiede se sono già state chieste.
            if reminderOn { await store.requestReminderPermission() }
            // Si salva solo ciò che è cambiato: rivedere l'introduzione non tocca obiettivo e promemoria.
            if goal != store.goal { store.goal = max(500, goal) }
            if reminderMinutes != store.reminderMinutes { store.reminderMinutes = reminderMinutes }
            if reminderOn != store.reminderEnabled { store.reminderEnabled = reminderOn }
            onFinish()
        }
    }
}

// MARK: - Impaginazione

/// Illustrazione in alto (altezza flessibile) e testo sotto, allineato a sinistra.
private struct PageLayout<Art: View, Content: View>: View {
    let compact: Bool
    @ViewBuilder var art: () -> Art
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            art()
                .frame(maxWidth: .infinity, minHeight: 90, maxHeight: compact ? 190 : 300)
                .clipped()
                .padding(.top, compact ? 8 : 24)
            Spacer(minLength: compact ? 8 : 16).frame(maxHeight: 28)
            VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                content()
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
        }
    }
}

/// Etichetta rossa sopra il titolo.
private struct Kicker: View {
    let text: String
    init(_ text: String) { self.text = text }
    @Environment(\.manga) private var c
    var body: some View {
        TagText(text: text, size: 15, tracking: 0.14, foreground: MangaPalette.onRed, background: c.red)
            .manga(rotate: -3, skew: -10)
    }
}

/// Titolo Anton su più righe, inclinato come quelli dello Storico.
private struct TitleText: View {
    let text: String
    let compact: Bool
    init(_ text: String, compact: Bool) { self.text = text; self.compact = compact }
    @Environment(\.manga) private var c
    var body: some View {
        Text(text)
            .font(.anton(compact ? 34 : 42))
            .foregroundStyle(c.ink)
            .lineSpacing(-4)
            .fixedSize(horizontal: false, vertical: true)
            .manga(rotate: -3, skew: -8, anchor: UnitPoint(x: 0, y: 0.5))
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Paragrafo in Anton (testo normale o nota più tenue).
private struct Paragraph: ViewModifier {
    var note = false
    @Environment(\.manga) private var c
    func body(content: Content) -> some View {
        content.font(.antonText(note ? 15 : 17)).tracking(0.4).lineSpacing(note ? 2 : 3)
            .foregroundStyle(note ? c.ink.opacity(0.6) : c.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Indicatore di pagina: parallelogrammi, quello attuale rosso e più lungo.
private struct PageDots: View {
    let count: Int
    let current: Int
    @Environment(\.manga) private var c
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                PercentPolygon.bar.fill(i == current ? c.red : c.ink.opacity(0.22))
                    .frame(width: i == current ? 26 : 12, height: 10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.format("intro.page.vo", "\(current + 1)", "\(count)")))
    }
}

// MARK: - Illustrazioni

/// Strada e scarpa della Home (sfondo + livello della gamba), ritagliate sulla parte bassa.
private struct WelcomeArt: View {
    @Environment(\.manga) private var c
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let px = Manga.artPixelSize, pad = Manga.legPadding
            let artH = w * px.height / px.width
            let legW = w * (px.width + 2 * pad) / px.width
            ZStack(alignment: .topLeading) {
                Image(c.homeArt).resizable().frame(width: w, height: artH)
                Image(c.homeLeg).resizable().frame(width: legW, height: legW * (px.height + 2 * pad) / (px.width + 2 * pad))
                    .offset(x: -w * pad / px.width, y: -w * pad / px.width)
            }
            // si mostra la zona della scarpa (circa dal 48% al 92% dell'illustrazione)
            .offset(y: -(artH * 0.70 - g.size.height / 2))
            .frame(width: w, height: g.size.height, alignment: .topLeading)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Obiettivo nell'esplosione a stella, come nella festa.
private struct GoalBurst: View {
    let goal: Int
    @Environment(\.manga) private var c
    var body: some View {
        ZStack {
            RaysView(rays: Self.rays)
                .mask(RadialGradient(stops: [.init(color: .clear, location: 0.3), .init(color: .white, location: 0.6)],
                                     center: .center, startRadius: 0, endRadius: 220))
            KineticLines.star(cx: 160, cy: 90, points: 16, outer: 92, inner: 62, rotation: 0.1).fill(c.ink)
                .frame(width: 320, height: 180)
            KineticLines.star(cx: 160, cy: 90, points: 16, outer: 80, inner: 52, rotation: 0.1).fill(c.red)
                .frame(width: 320, height: 180)
            GlyphText(text: LocalFormat.integer(goal), size: 72, lineHeight: 0.9, tracking: -0.03, fill: c.paper,
                      stroke: c.ink, strokeWidth: 2.5, shadow: (c.ink, 4, 4))
                .manga(rotate: -5, skew: -10)
        }
        .frame(width: 390, height: 300)
        .scaleEffect(0.8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private static let rays = KineticLines.rays(cx: 195, cy: 150, count: 70, innerMin: 110, innerMax: 150, outer: 320, seed: 11, redEvery: 7)
}

extension PercentPolygon {
    /// Bottone dell'introduzione: parallelogramma leggermente storto.
    static let button = PercentPolygon(points: [CGPoint(x: 0.05, y: 0), CGPoint(x: 1, y: 0.06), CGPoint(x: 0.95, y: 1), CGPoint(x: 0, y: 0.94)])
}
