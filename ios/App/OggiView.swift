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
                panel
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

    // MARK: chip streak e Jolly

    private var chips: some View {
        let s = store.history.streak
        return HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill").font(.system(size: 12))
                Text("\(s.streak)").monospacedDigit()
            }
            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(Theme.accentSoft))
            .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.22), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Streak: \(s.streak) giorni")

            HStack(spacing: 5) {
                GemShape().stroke(Theme.ink.opacity(0.8), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                    .frame(width: 12, height: 12)
                Text("\(s.jolly)").monospacedDigit()
            }
            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink.opacity(0.8))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(Theme.ink.opacity(0.07)))
            .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.12), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Jolly disponibili: \(s.jolly)")
        }
    }

    // MARK: passi (arco)

    private func hero(arc: CGFloat) -> some View {
        let p = store.plan
        return VStack(spacing: 8) {
            ZStack {
                ArcGauge(progress: p.progress, done: p.isDone)
                VStack(spacing: 6) {
                    Text("PASSI DI OGGI").font(.system(size: 11, weight: .semibold)).tracking(11 * 0.3)
                        .foregroundStyle(Theme.soft)
                    NumberField(value: store.steps, placeholder: "0", emptyWhenZero: true,
                                onEdit: { store.setManualSteps($0) }, isFocused: $stepsFocused)
                        .font(.system(size: arc * 0.29, weight: .ultraLight)).tracking(-arc * 0.29 * 0.05).monospacedDigit()
                        .foregroundStyle(Theme.ink)
                        .frame(width: arc * 0.78)
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

    private var panel: some View {
        let p = store.plan
        return VStack(spacing: 12) {
            HStack(spacing: 6) {
                TreadmillView(speed: p.speed, moving: !p.isDone)
                    .frame(width: 160)
                    .padding(.leading, -8)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(p.isDone ? "OBIETTIVO\nCHIUSO" : "MINUTI SUL\nTAPPETO")
                        .font(.system(size: 10, weight: .semibold)).tracking(2.4)
                        .multilineTextAlignment(.trailing).lineSpacing(3).foregroundStyle(Theme.soft)
                    if p.isDone {
                        Text("Fatto").font(.system(size: 54, weight: .light)).tracking(-2.2).foregroundStyle(Theme.ink)
                        Text("\(Text(ItalianFormat.integer(p.steps)).fontWeight(.semibold).foregroundStyle(Theme.ink)) su \(ItalianFormat.integer(p.goal))")
                            .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.soft)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(ItalianFormat.integer(p.minutes) + "\u{2009}")
                                .font(.system(size: 76, weight: .ultraLight)).tracking(-4.5).monospacedDigit()
                                .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.5)
                            Text("min").font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.soft)
                        }
                        Text("per \(Text(ItalianFormat.integer(p.remaining)).fontWeight(.semibold).foregroundStyle(Theme.ink)) passi · \(ItalianFormat.number(p.km, decimals: 1)) km")
                            .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.soft)
                    }
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
        if p.isDone { return "Obiettivo chiuso: \(ItalianFormat.integer(p.steps)) passi su \(ItalianFormat.integer(p.goal))" }
        return "\(p.minutes) minuti sul tappeto per \(ItalianFormat.integer(p.remaining)) passi, \(ItalianFormat.number(p.km, decimals: 1)) chilometri"
    }
}
