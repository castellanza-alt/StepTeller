import SwiftUI
import StepTellerCore

/// Unica schermata dell'app: testata, minuti, tappeto, pannello in vetro, riga finale.
struct ContentView: View {
    enum Field { case goal, steps }

    @Environment(StepsStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focus: Field?

    @ScaledMetric(relativeTo: .caption2) private var labelSize: CGFloat = 11

    var body: some View {
        ZStack {
            OrbsBackground()
            GeometryReader { geo in
                let width = geo.size.width
                VStack(spacing: 0) {
                    header
                    hero(width: width)
                        .padding(.top, min(34, max(18, geo.size.height * 0.04)))
                    stage(width: width)
                    panel
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 18)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
            }
        }
        .task { await store.start() }
        .onChange(of: scenePhase) { _, phase in
            Task {
                if phase == .active { await store.becameActive() }
                else if phase == .background { await store.becameInactive() }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") { focus = nil }
            }
        }
    }

    // MARK: testata

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("STEP TELLER")
                .font(.system(size: 11, weight: .semibold)).tracking(11 * 0.34)
                .foregroundStyle(Theme.soft)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("OBIETTIVO")
                    .font(.system(size: 11, weight: .semibold)).tracking(11 * 0.18)
                    .foregroundStyle(Theme.soft)
                NumberField(value: store.goal, placeholder: "0", onEdit: { store.goal = $0 },
                            focus: $focus, field: .goal)
                    .font(.system(size: 13, weight: .semibold)).tracking(13 * 0.06)
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .frame(width: 64)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(focus == .goal ? Theme.accent : .clear).frame(height: 1)
                    }
                    .accessibilityLabel("Obiettivo passi")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: minuti

    private func hero(width: CGFloat) -> some View {
        let p = store.plan
        let big = min(164, max(108, width * 0.36))
        let doneSize = min(88, max(64, width * 0.19))
        return VStack(spacing: 0) {
            Text(p.isDone ? "OBIETTIVO CHIUSO" : "MINUTI SUL TAPPETO")
                .font(.system(size: 11, weight: .semibold)).tracking(11 * 0.30)
                .foregroundStyle(Theme.soft)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if p.isDone {
                    Text("Fatto")
                        .font(.system(size: doneSize, weight: .light)).tracking(-0.04 * doneSize)
                        .padding(.vertical, doneSize * 0.03)
                } else {
                    Text(ItalianFormat.integer(p.minutes))
                        .font(.system(size: big, weight: .ultraLight)).tracking(-0.06 * big)
                        .padding(.vertical, -big * 0.155)   // interlinea 0,88 come nel CSS
                    Text("min")
                        .font(.system(size: 17, weight: .medium)).tracking(17 * 0.02)
                        .foregroundStyle(Theme.soft)
                }
            }
            .monospacedDigit()
            .foregroundStyle(Theme.ink)
            .lineLimit(1).minimumScaleFactor(0.5)
            .padding(.top, 6)
            sub(p)
                .font(.system(size: 14)).monospacedDigit()
                .foregroundStyle(Theme.soft)
                .padding(.top, 12)
                .frame(minHeight: 18)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroAccessibility(p))
    }

    private func sub(_ p: Plan) -> Text {
        let bold = { (s: String) in Text(s).fontWeight(.semibold).foregroundStyle(Theme.ink) }
        if p.isDone {
            return Text("\(bold(ItalianFormat.integer(p.steps))) su \(ItalianFormat.integer(p.goal))")
        }
        return Text("per \(bold(ItalianFormat.integer(p.remaining))) passi · \(ItalianFormat.number(p.km, decimals: 1)) km · \(ItalianFormat.number(p.cadence)) passi/min")
    }

    private func heroAccessibility(_ p: Plan) -> String {
        if p.isDone {
            return "Obiettivo chiuso: \(ItalianFormat.integer(p.steps)) passi su \(ItalianFormat.integer(p.goal))"
        }
        return "\(p.minutes) minuti sul tappeto per \(ItalianFormat.integer(p.remaining)) passi, "
            + "\(ItalianFormat.number(p.km, decimals: 1)) chilometri, \(ItalianFormat.number(p.cadence)) passi al minuto"
    }

    // MARK: tappeto

    private func stage(width: CGFloat) -> some View {
        let p = store.plan
        return GeometryReader { geo in
            ZStack {
                Ellipse().fill(Theme.accentSoft).opacity(0.7)
                    .frame(width: geo.size.width * 0.70, height: geo.size.height * 0.60)
                    .blur(radius: 40)
                TreadmillView(speed: p.speed, moving: !p.isDone)
                    .frame(width: min(geo.size.width * 0.86, 330))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.top, 8).padding(.bottom, 4)
        .frame(maxHeight: .infinity)
    }

    // MARK: pannello

    private var panel: some View {
        let p = store.plan
        return VStack(spacing: 22) {
            stepsBlock
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("VELOCITÀ · \(Text(p.gait.label.uppercased()).foregroundStyle(Theme.accent))")
                        .font(.system(size: labelSize, weight: .semibold)).tracking(labelSize * 0.24)
                        .foregroundStyle(Theme.soft)
                    Spacer(minLength: 16)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(ItalianFormat.number(p.speed, decimals: 1))
                            .font(.system(size: 38, weight: .light)).tracking(-0.03 * 38)
                            .monospacedDigit().foregroundStyle(Theme.ink)
                        Text("km/h").font(.system(size: 13, weight: .medium)).tracking(13 * 0.02)
                            .foregroundStyle(Theme.soft)
                    }
                }
                SpeedDial(speed: Binding(get: { store.speed }, set: { store.speed = $0 }))
                    .padding(.top, 4)
            }
            .accessibilityElement(children: .contain)
        }
        .padding(EdgeInsets(top: 22, leading: 22, bottom: 18, trailing: 22))
        .background(GlassPanelBackground())
    }

    private var stepsBlock: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("PASSI DI OGGI")
                    .font(.system(size: labelSize, weight: .semibold)).tracking(labelSize * 0.24)
                    .foregroundStyle(Theme.soft)
                NumberField(value: store.steps, placeholder: "0", onEdit: { store.setManualSteps($0) },
                            focus: $focus, field: .steps)
                    .font(.system(size: 38, weight: .light)).tracking(-0.03 * 38)
                    .monospacedDigit().foregroundStyle(Theme.ink)
                    .padding(.bottom, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(focus == .steps ? Theme.accent : Theme.faint).frame(height: 1)
                    }
                    .accessibilityLabel("Passi di oggi")
            }
            sourceLine
            if store.showsNoDataWarning { noDataWarning }
        }
    }

    /// «da Salute · 21:04» / «manuale · 21:04», con «Usa Salute» quando c'è una sovrascrittura.
    private var sourceLine: some View {
        HStack(spacing: 10) {
            if store.hasOverride {
                Button("Usa Salute") { Task { await store.useHealth() } }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            Text(sourceText)
                .font(.system(size: 12)).monospacedDigit()
                .foregroundStyle(Theme.soft)
        }
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
        VStack(alignment: .trailing, spacing: 4) {
            Text("Nessun dato da Salute. Controlla Salute → Condivisione → App → Step Teller")
                .font(.system(size: 12)).foregroundStyle(Theme.soft)
                .multilineTextAlignment(.trailing)
            Button("Apri Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.accent)
        }
    }

    // MARK: riga finale

    private var footer: some View {
        Text((store.plan.gait == .run ? "corsa tarata sulle tue corse · set 2026" : "cammino · curva standard").uppercased())
            .font(.system(size: 10)).tracking(10 * 0.14)
            .foregroundStyle(Theme.faint)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }
}
