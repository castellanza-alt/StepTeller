import SwiftUI
import StepTellerCore

/// Home («Oggi»): illustrazione a tutto schermo, passi di oggi, minuti mancanti e il cursore della
/// velocità che scorre sulla strada. Tela 390 × 844 pt del handoff, scalata in larghezza (o in altezza se lo
/// schermo è più basso del riferimento).
struct HomeView: View {
    let size: CGSize
    @Environment(StepsStore.self) private var store
    @Environment(\.manga) private var c
    @State private var minutesWidth: CGFloat = 96
    @State private var doneWidth: CGFloat = 130
    @State private var editing = false
    @State private var editText = ""
    @State private var motion = ParallaxMotion()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Di norma la tela si scala in larghezza; sui telefoni bassi (es. SE, 375 × 667) si adatta
        // all'altezza, così strada e cursore restano sullo schermo (ai lati resta il fondo `paper`).
        let s = min(size.width / Manga.frameWidth, size.height / Manga.frameHeight)
        MangaCanvas(width: Manga.frameWidth * s, height: size.height / s) {
            Board {
                ZStack(alignment: .topLeading) {
                    Image(c.homeArt)
                        .resizable()
                        .frame(width: Manga.artSize.width, height: Manga.artSize.height)
                        .accessibilityHidden(true)
                    ParallaxLeg(image: c.homeLeg, motion: motion)
                }
                .frame(width: Manga.artSize.width, height: Manga.artSize.height, alignment: .topLeading)
                .clipped()
                .at(0, Manga.artTop)
                stepsBlock
                    .manga(rotate: -15, skew: -10, anchor: .topLeading)
                    .at(14, Manga.artTop + 112)
                notices
                    .at(20, Manga.artTop + 286)
                if store.plan.isDone {
                    doneBlock
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { doneWidth = $0 }
                        .at(min(250, Manga.frameWidth - 10 - doneWidth), Manga.artTop + 452)
                } else {
                    minutesBlock
                        .manga(rotate: -5, skew: -9)
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { minutesWidth = $0 }
                        .at(min(290, Manga.frameWidth - 8 - minutesWidth), Manga.artTop + 480)
                }
                if !store.plan.isDone {
                    RoadSpeedSlider(speed: Binding(get: { store.speed }, set: { store.speed = $0 }))
                        .frame(width: Manga.artSize.width, height: Manga.artSize.height)
                        .at(0, Manga.artTop)
                        .transition(.opacity)
                }
            }
            .background(c.paper)
            .animation(.easeInOut(duration: 0.25), value: store.plan.isDone)
        }
        .frame(width: size.width)
        .onAppear { updateMotion() }
        .onDisappear { motion.stop() }
        .onChange(of: scenePhase) { _, _ in updateMotion() }
        .onChange(of: reduceMotion) { _, _ in updateMotion() }
        .alert(L10n.text("home.edit.title"), isPresented: $editing) {
            TextField(L10n.text("home.edit.placeholder"), text: $editText).keyboardType(.numberPad)
            Button(L10n.text("common.save")) { store.setManualSteps(LocalFormat.digits(editText)) }
            Button(L10n.text("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("home.edit.message"))
        }
    }

    /// Parallasse solo con l'app in primo piano e senza «Riduci movimento».
    private func updateMotion() {
        if scenePhase == .active, !reduceMotion { motion.start() } else { motion.stop() }
    }

    // MARK: passi di oggi

    /// «PASSI DI OGGI» / numero / «SU 10.000»: colonna centrata, ruotata −15° e inclinata −10° dall'angolo
    /// in alto a sinistra. Un tocco sul numero apre la correzione manuale.
    private var stepsBlock: some View {
        VStack(spacing: 0) {
            AntonText(L10n.text("home.steps.label"), 27, tracking: 0.01)
            AntonText(LocalFormat.integer(store.steps), 108, lineHeight: 0.92, tracking: -0.035)
                .manga(scaleX: 0.86)
                .contentTransition(.numericText())
                .animation(.snappy, value: store.steps)
            AntonText(L10n.format("home.steps.of", LocalFormat.integer(store.goal)), 19, tracking: 0.02)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editText = store.steps > 0 ? String(store.steps) : ""
            editing = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("home.steps.vo", LocalFormat.integer(store.steps), LocalFormat.integer(store.goal)))
        .accessibilityHint(L10n.text("home.steps.hint.vo"))
        .accessibilityAddTraits(.isButton)
    }

    /// Correzione manuale attiva («USA SALUTE») e avviso quando Salute non dà dati.
    @ViewBuilder private var notices: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.hasOverride {
                Button { Task { await store.useHealth() } } label: {
                    TagText(text: L10n.text("home.useHealth"), size: 15, tracking: 0.06, foreground: c.paper, background: c.red,
                            padding: EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
                }
                .buttonStyle(PressScale())
                .accessibilityHint(L10n.text("home.useHealth.vo"))
            }
            if store.showsNoDataWarning {
                VStack(alignment: .leading, spacing: 6) {
                    TagText(text: L10n.text("home.noData.title"), size: 14, tracking: 0.06, foreground: c.paper, background: c.ink)
                    AntonText(L10n.text("home.noData.path"), 11, tracking: 0.04)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } label: {
                        TagText(text: L10n.text("home.noData.button"), size: 13, tracking: 0.06, foreground: c.ink, background: c.paper, border: c.ink)
                    }
                    .buttonStyle(PressScale())
                }
                .accessibilityElement(children: .combine)
            }
        }
        .manga(rotate: -6, skew: -8, anchor: .topLeading)
    }

    // MARK: minuti mancanti

    private var minutesBlock: some View {
        let p = store.plan
        return VStack(alignment: .leading, spacing: 0) {
            AntonText(L10n.text("home.minutes.1"), 17)
            AntonText(L10n.text("home.minutes.2"), 17)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                AntonText(LocalFormat.integer(p.minutes), 68, lineHeight: 0.95, tracking: -0.02)
                    .contentTransition(.numericText())
                AntonText(L10n.text("home.minutes.unit"), 18)
            }
            .padding(.top, 2)
            AntonText(L10n.format("home.minutes.km", LocalFormat.number(p.km, decimals: 1)), 15, color: c.red).padding(.top, 3)
        }
        .animation(.snappy(duration: 0.2), value: p.minutes)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("home.minutes.vo", "\(p.minutes)", LocalFormat.number(p.speed, decimals: 1),
                                        LocalFormat.number(p.km, decimals: 1)))
    }

    // MARK: obiettivo raggiunto

    /// «OBIETTIVO / RAGGIUNTO / FATTO! / +729 PASSI» in una vignetta storta come quelle dello Storico:
    /// il fondo `paper` stacca il testo da gamba e lacci dell'illustrazione.
    private var doneBlock: some View {
        Vignette(shape: .panelA) {
            VStack(alignment: .leading, spacing: 0) {
                AntonText(L10n.text("home.done.1"), 17, tracking: 0.04)
                AntonText(L10n.text("home.done.2"), 17, tracking: 0.04)
                AntonText(L10n.text("home.done.3"), 68, lineHeight: 0.95, tracking: -0.02, color: c.red).padding(.top, 2)
                if store.steps > store.goal {
                    AntonText(L10n.format("home.done.extra", LocalFormat.integer(store.steps - store.goal)), 15, color: c.red)
                        .padding(.top, 3)
                }
            }
            .manga(skew: -9)
            .padding(.trailing, 4)
        }
        .rotationEffect(.degrees(-5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text("home.done.vo"))
    }
}
