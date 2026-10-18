import SwiftUI
import StepTellerCore

/// Home («Oggi»): illustrazione a tutto schermo, passi di oggi, minuti mancanti e il cursore della
/// velocità che scorre sulla strada. Tela 390 pt del handoff, scalata in larghezza.
struct HomeView: View {
    let size: CGSize
    @Environment(StepsStore.self) private var store
    @Environment(\.manga) private var c
    @State private var minutesWidth: CGFloat = 96
    @State private var editing = false
    @State private var editText = ""

    var body: some View {
        let s = size.width / Manga.frameWidth
        MangaCanvas(width: size.width, height: size.height / s) {
            Board {
                Image(c.homeArt)
                    .resizable()
                    .frame(width: Manga.artSize.width, height: Manga.artSize.height)
                    .accessibilityHidden(true)
                    .at(0, Manga.artTop)
                stepsBlock
                    .manga(rotate: -15, skew: -10, anchor: .topLeading)
                    .at(14, Manga.artTop + 112)
                notices
                    .at(20, Manga.artTop + 286)
                minutesBlock
                    .manga(rotate: -5, skew: -9)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { minutesWidth = $0 }
                    .at(min(290, Manga.frameWidth - 8 - minutesWidth), Manga.artTop + 480)
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
        .alert("Passi di oggi", isPresented: $editing) {
            TextField("Passi", text: $editText).keyboardType(.numberPad)
            Button("Salva") { store.setManualSteps(ItalianFormat.digits(editText)) }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Correggi a mano i passi di oggi. Con «Usa Salute» torni ai dati di Salute.")
        }
    }

    // MARK: passi di oggi

    /// «PASSI DI OGGI» / numero / «SU 10.000»: colonna centrata, ruotata −15° e inclinata −10° dall'angolo
    /// in alto a sinistra. Un tocco sul numero apre la correzione manuale.
    private var stepsBlock: some View {
        VStack(spacing: 0) {
            AntonText("PASSI DI OGGI", 27, tracking: 0.01)
            AntonText(ItalianFormat.integer(store.steps), 108, lineHeight: 0.92, tracking: -0.035)
                .manga(scaleX: 0.86)
                .contentTransition(.numericText())
                .animation(.snappy, value: store.steps)
            AntonText("SU \(ItalianFormat.integer(store.goal))", 19, tracking: 0.02)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editText = store.steps > 0 ? String(store.steps) : ""
            editing = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Passi di oggi: \(ItalianFormat.integer(store.steps)) su \(ItalianFormat.integer(store.goal))")
        .accessibilityHint("Tocca due volte per correggere a mano")
        .accessibilityAddTraits(.isButton)
    }

    /// Correzione manuale attiva («USA SALUTE») e avviso quando Salute non dà dati.
    @ViewBuilder private var notices: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.hasOverride {
                Button { Task { await store.useHealth() } } label: {
                    TagText(text: "USA SALUTE", size: 15, tracking: 0.06, foreground: c.paper, background: c.red,
                            padding: EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
                }
                .buttonStyle(PressScale())
                .accessibilityHint("Torna ai passi letti da Salute")
            }
            if store.showsNoDataWarning {
                VStack(alignment: .leading, spacing: 6) {
                    TagText(text: "NESSUN DATO DA SALUTE", size: 14, tracking: 0.06, foreground: c.paper, background: c.ink)
                    AntonText("SALUTE → CONDIVISIONE → APP → STEP TELLER", 11, tracking: 0.04)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } label: {
                        TagText(text: "APRI IMPOSTAZIONI", size: 13, tracking: 0.06, foreground: c.ink, background: c.paper, border: c.ink)
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
            if p.isDone {
                AntonText("OBIETTIVO", 17)
                AntonText("RAGGIUNTO", 17)
                AntonText("FATTO!", 68, lineHeight: 0.95, tracking: -0.02, color: c.red).padding(.top, 2)
                if store.steps > store.goal {
                    AntonText("+\(ItalianFormat.integer(store.steps - store.goal)) PASSI", 15, color: c.red).padding(.top, 3)
                }
            } else {
                AntonText("MINUTI", 17)
                AntonText("MANCANTI", 17)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    AntonText(ItalianFormat.integer(p.minutes), 68, lineHeight: 0.95, tracking: -0.02)
                        .contentTransition(.numericText())
                    AntonText("min", 18)
                }
                .padding(.top, 2)
                AntonText("≈ \(ItalianFormat.number(p.km, decimals: 1)) KM", 15, color: c.red).padding(.top, 3)
            }
        }
        .animation(.snappy(duration: 0.2), value: p.minutes)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(p.isDone ? "Obiettivo raggiunto"
                            : "Mancano \(p.minutes) minuti a \(ItalianFormat.number(p.speed, decimals: 1)) chilometri orari, circa \(ItalianFormat.number(p.km, decimals: 1)) chilometri")
    }
}
