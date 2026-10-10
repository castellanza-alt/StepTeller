import SwiftUI
import StepTellerCore

/// Pagina «Oggi»: passi di oggi nell'arco (grafica del widget) e, sotto, quanti minuti di tappeto
/// servono con il selettore di velocità.
struct OggiView: View {
    @Environment(StepsStore.self) private var store
    @FocusState private var stepsFocused: Bool
    let onSettings: () -> Void

    @ScaledMetric(relativeTo: .caption2) private var labelSize: CGFloat = 11

    var body: some View {
        GeometryReader { geo in
            let arc = min(262, geo.size.width * 0.68)
            VStack(spacing: 0) {
                AppHeader(onSettings: onSettings) { chips }
                    .padding(.top, 10)
                Spacer(minLength: 8)
                hero(arc: arc)
                Spacer(minLength: 10)
                if !store.plan.isDone {                 // a obiettivo chiuso la card non serve
                    panel.transition(.opacity)
                }
                Color.clear.frame(height: 112)      // spazio per la barra in basso
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") { stepsFocused = false }
            }
        }
    }

    // MARK: streak e Jolly (solo icona e numero)

    private var chips: some View {
        let s = store.history.streak
        return HStack(spacing: 18) {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill").font(.system(size: 13))
                Text("\(s.streak)").monospacedDigit()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(s.streak > 0 ? Theme.accent : Theme.soft)
            .contentTransition(.numericText())
            .animation(.snappy, value: s.streak)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Streak: \(s.streak) giorni")

            HStack(spacing: 5) {
                GemShape().stroke(Theme.soft, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                    .frame(width: 13, height: 13)
                Text("\(s.jolly)").monospacedDigit()
            }
            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.soft)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Jolly disponibili: \(s.jolly)")
        }
        .padding(.trailing, 8)
    }

    // MARK: passi (arco)

    private func hero(arc: CGFloat) -> some View {
        let p = store.plan
        let numberWidth = arc * 0.74
        let numberSize = fittedNumberSize(ItalianFormat.integer(store.steps), base: arc * 0.29, width: numberWidth)
        return VStack(spacing: 8) {
            ZStack {
                ArcGauge(progress: p.progress)
                    .animation(.spring(duration: 0.9, bounce: 0.15), value: p.progress)
                VStack(spacing: 6) {
                    Text("PASSI DI OGGI").font(.system(size: 11, weight: .semibold)).tracking(11 * 0.3)
                        .foregroundStyle(Theme.soft)
                    NumberField(value: store.steps, placeholder: "0", emptyWhenZero: true, alignment: .center,
                                onEdit: { store.setManualSteps($0) }, isFocused: $stepsFocused)
                        .font(.system(size: numberSize, weight: .ultraLight)).tracking(-numberSize * 0.05).monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .frame(width: numberWidth)
                        .accessibilityLabel("Passi di oggi")
                    Text("su \(ItalianFormat.integer(p.goal))")
                        .font(.system(size: 14)).monospacedDigit().foregroundStyle(Theme.soft)
                }
                .padding(.bottom, arc * 0.07)
            }
            .frame(width: arc, height: arc)
            sourceLine
            if store.showsNoDataWarning { noDataWarning }
        }
    }

    /// Corpo del numero centrale: pieno finché entra nell'arco, poi si riduce (mai troncato).
    private func fittedNumberSize(_ text: String, base: CGFloat, width: CGFloat) -> CGFloat {
        let font = UIFont.monospacedDigitSystemFont(ofSize: base, weight: .ultraLight)
        let measured = (text as NSString).size(withAttributes: [.font: font, .kern: -base * 0.05]).width
        guard measured > 0 else { return base }
        return base * min(1, width * 0.94 / measured)
    }

    /// «da Salute · 21:04» / «manuale · 21:04», con «Usa Salute» quando c'è una sovrascrittura.
    private var sourceLine: some View {
        HStack(spacing: 10) {
            if store.hasOverride {
                Button("Usa Salute") { Task { await store.useHealth() } }
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
            }
            Text(sourceText).font(.system(size: 14)).monospacedDigit().foregroundStyle(Theme.soft)
        }
        .padding(.top, 2)
    }

    private var sourceText: String {
        let origin = store.origin == .health ? "da Salute" : "manuale"
        guard let date = store.lastUpdate else { return origin }
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "HH:mm"
        return "\(origin) · \(f.string(from: date))"
    }

    private var noDataWarning: some View {
        VStack(spacing: 4) {
            Text("Nessun dato da Salute. Controlla Salute → Condivisione → App → Step Teller")
                .font(.system(size: 12)).foregroundStyle(Theme.soft).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Apri Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.accent)
        }
    }

    // MARK: minuti sul tappeto

    private func minutesHeader(_ p: Plan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MINUTI SUL\nTAPPETO")
                .font(.system(size: 10, weight: .semibold)).tracking(2.4)
                .lineSpacing(3).foregroundStyle(Theme.soft)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(ItalianFormat.integer(p.minutes) + "\u{2009}")
                    .font(.system(size: 76, weight: .ultraLight)).tracking(-4.5).monospacedDigit()
                    .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.5)
                Text("min").font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.soft)
            }
        }
    }

    private func sideStat(_ label: String, _ value: String, unit: String?) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label).font(.system(size: 10, weight: .semibold)).tracking(2.4).foregroundStyle(Theme.soft)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 28, weight: .light)).tracking(-0.8).monospacedDigit()
                    .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
                if let unit {
                    Text(unit).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.soft)
                }
            }
        }
    }

    private var panel: some View {
        let p = store.plan
        return VStack(spacing: 12) {
            if store.showsTreadmill {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                        minutesHeader(p)
                        Text("per \(Text(ItalianFormat.integer(p.remaining)).fontWeight(.semibold).foregroundStyle(Theme.ink)) passi · \(ItalianFormat.number(p.km, decimals: 1)) km")
                            .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.soft)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityMinutes(p))
                    Spacer(minLength: 0)
                    TreadmillView(speed: p.speed, moving: true)   // si può nascondere dalle Impostazioni
                        .frame(width: 160)
                        .padding(.trailing, -8)
                }
            } else {
                // Senza tappeto: passi e km a destra, come numeri, al posto della riga piccola.
                HStack(alignment: .bottom, spacing: 12) {
                    minutesHeader(p)
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 14) {
                        sideStat("PASSI MANCANTI", ItalianFormat.integer(p.remaining), unit: nil)
                        sideStat("DISTANZA", ItalianFormat.number(p.km, decimals: 1), unit: "km")
                    }
                    .padding(.bottom, 8)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityMinutes(p))
            }
            Rectangle().fill(Theme.ink.opacity(0.10)).frame(height: 1)
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("VELOCITÀ · \(Text(p.gait.label.uppercased()).foregroundStyle(Theme.accent))")
                        .font(.system(size: labelSize, weight: .semibold)).tracking(labelSize * 0.24)
                        .foregroundStyle(Theme.soft)
                    Spacer(minLength: 16)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(ItalianFormat.number(p.speed, decimals: 1))
                            .font(.system(size: 34, weight: .light)).tracking(-1).monospacedDigit().foregroundStyle(Theme.ink)
                        Text("km/h").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.soft)
                    }
                }
                SpeedDial(speed: Binding(get: { store.speed }, set: { store.speed = $0 }))
            }
        }
        .padding(EdgeInsets(top: 18, leading: 20, bottom: 14, trailing: 20))
        .background(GlassPanelBackground())
    }

    private func accessibilityMinutes(_ p: Plan) -> String {
        return "\(p.minutes) minuti sul tappeto per \(ItalianFormat.integer(p.remaining)) passi, \(ItalianFormat.number(p.km, decimals: 1)) chilometri"
    }
}
