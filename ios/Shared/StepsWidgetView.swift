import SwiftUI
import WidgetKit
import StepTellerCore

/// Dati mostrati dal widget: piano di oggi (nil = Salute non disponibile), serie e Jolly dall'app.
struct WidgetSnapshot {
    let plan: Plan?
    let streak: Int
    let jolly: Int
}

/// Tema del widget: segue l'aspetto del sistema (chiaro = giorno, scuro = notte).
struct WidgetThemed<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().environment(\.manga, scheme == .dark ? .night : .day)
    }
}

/// Sfondo `paper` del tema corrente.
struct WidgetPaper: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View { (scheme == .dark ? MangaPalette.night : MangaPalette.day).paper }
}

// MARK: - Piccolo (170 × 170)

/// Widget piccolo: suola in basso a destra che sfuma, serie in alto, passi inclinati, barra di avanzamento.
/// Disegnato nello spazio 170 × 170 del handoff e scalato alla misura reale.
struct WidgetSmallView: View {
    let data: WidgetSnapshot
    @Environment(\.manga) private var c

    var body: some View {
        GeometryReader { geo in
            Board {
                art
                streakTag.manga(rotate: -4).at(14, 14)
                steps.manga(rotate: -10, skew: -10, anchor: .topLeading).at(10, 40)
                WidgetProgressBar(progress: data.plan?.progress ?? 0, width: 92, height: 9)
                    .manga(skew: -20)
                    .at(14, 170 - 16 - 9)
            }
            .frame(width: 170, height: 170)
            .scaleEffect(geo.size.width / 170, anchor: .topLeading)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetText.summary(data))
    }

    /// Arte 160 × 160 sbordante di 34 pt in basso a destra, con maschera radiale (78 %, 78 %).
    private var art: some View {
        Image(c.theme == .night ? "WidgetSmallNight" : "WidgetSmallDay")
            .resizable()
            .frame(width: 160, height: 160)
            .mask(RadialGradient(stops: [.init(color: .black, location: 0.3), .init(color: .clear, location: 0.68)],
                                 center: UnitPoint(x: 0.78, y: 0.78), startRadius: 0, endRadius: 160 * 0.78 * 2.squareRoot()))
            .at(170 - 160 + 34, 170 - 160 + 34)
    }

    private var streakTag: some View {
        HStack(spacing: 4) {
            FlameIcon(kind: .streak).frame(width: 13, height: 16)
            AntonText("\(data.streak)", 16)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 0) {
            AntonText(WidgetText.steps(data.plan), 50, lineHeight: 0.9, tracking: -0.035)
                .shadow(color: c.paper, radius: 3).shadow(color: c.paper, radius: 6)
            AntonText(data.plan.map { "SU \(ItalianFormat.integer($0.goal))" } ?? "APRI L'APP", 12, tracking: 0.06)
                .shadow(color: c.paper, radius: 3)
                .padding(.top, 3)
        }
    }
}

// MARK: - Medio (364 × 170)

/// Widget medio: tavola a sinistra che sfuma, serie e Jolly in alto a destra, passi con ombra rossa,
/// minuti e km che mancano alla velocità scelta in Home, barra di avanzamento.
struct WidgetMediumView: View {
    let data: WidgetSnapshot
    @Environment(\.manga) private var c

    var body: some View {
        GeometryReader { geo in
            Board {
                Image(c.theme == .night ? "WidgetMediumNight" : "WidgetMediumDay")
                    .resizable()
                    .frame(width: 364, height: 170)
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0.32), .init(color: .clear, location: 0.58)],
                                         startPoint: .leading, endPoint: .trailing))
                    .at(-60, 0)
                counters
                    .manga(rotate: -3, skew: -8)
                    .frame(width: 364 - 28, alignment: .trailing)
                    .at(14, 14)
                stepsBlock.manga(rotate: -8, skew: -10, anchor: .topLeading).at(168, 34)
                remaining.manga(rotate: -4, skew: -9).at(184, 122)
                WidgetProgressBar(progress: data.plan?.progress ?? 0, width: 160, height: 7)
                    .manga(rotate: -1.5, skew: -20)
                    .at(188, 170 - 14 - 7)
            }
            .frame(width: 364, height: 170)
            .scaleEffect(geo.size.width / 364, anchor: .topLeading)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetText.summary(data))
    }

    private var counters: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                FlameIcon(kind: .streak).frame(width: 12, height: 15)
                AntonText("\(data.streak)", 15)
            }
            HStack(spacing: 3) {
                FlameIcon(kind: .jolly).frame(width: 12, height: 15)
                AntonText("\(data.jolly)", 15)
            }
        }
    }

    private var stepsBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            AntonText("PASSI DI OGGI", 13, tracking: 0.04)
            let text = WidgetText.steps(data.plan)
            ZStack(alignment: .topLeading) {
                AntonText(text, 64, lineHeight: 0.92, tracking: -0.035, color: c.red).offset(x: 4, y: 4)
                AntonText(text, 64, lineHeight: 0.92, tracking: -0.035)
            }
        }
    }

    @ViewBuilder private var remaining: some View {
        HStack(alignment: .lastTextBaseline, spacing: 5) {
            if let p = data.plan {
                if p.isDone {
                    AntonText("OBIETTIVO", 13)
                    AntonText("FATTO!", 24, color: c.red)
                } else {
                    AntonText("MANCANO", 13)
                    AntonText(ItalianFormat.integer(p.minutes), 24, color: c.red)
                    AntonText("MIN · \(ItalianFormat.number(p.km, decimals: 1)) KM", 13)
                }
            } else {
                AntonText("APRI L'APP", 13)
            }
        }
    }
}

// MARK: - Blocco schermo (monocromatici)

/// Blocco schermo, tondo: anello (traccia 30 %, spessore 6) con i passi in Anton al centro.
struct LockCircular: View {
    let plan: Plan?
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle().inset(by: 3).stroke(Color.white.opacity(0.3), lineWidth: 6)
            Circle().inset(by: 3).trim(from: 0, to: min(1, plan?.progress ?? 0))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
            VStack(spacing: 2) {
                AntonText(WidgetText.compactSteps(plan), 19, tracking: -0.02, color: .white)
                    .minimumScaleFactor(0.6)
                AntonText("PASSI", 9, tracking: 0.08, color: .white)
            }
            .manga(skew: -10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plan.map { "\(ItalianFormat.integer($0.steps)) passi su \(ItalianFormat.integer($0.goal))" } ?? "Passi non disponibili")
    }
}

/// Blocco schermo, rettangolare: serie, passi grandi inclinati, minuti e km che mancano.
struct LockRectangular: View {
    let data: WidgetSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                SVGShape(MangaPaths.flame, viewBox: MangaPaths.flameBox).fill(Color.white).frame(width: 10, height: 12)
                AntonText(data.streak == 1 ? "1 GIORNO DI FILA" : "\(data.streak) GIORNI DI FILA", 12, tracking: 0.06, color: .white)
            }
            .widgetAccentable()
            AntonText(WidgetText.steps(data.plan), 30, lineHeight: 0.95, tracking: -0.03, color: .white)
                .manga(skew: -10, anchor: .bottomLeading)
            AntonText(line, 12, tracking: 0.04, color: .white).opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WidgetText.summary(data))
    }

    private var line: String {
        guard let p = data.plan else { return "APRI L'APP" }
        if p.isDone { return "OBIETTIVO RAGGIUNTO" }
        return "ANCORA \(p.minutes) MIN · \(ItalianFormat.number(p.km, decimals: 1)) KM"
    }
}

// MARK: - Pezzi comuni

/// Barra di avanzamento: fondo `paper`, bordo 1,5 `ink`, riempimento `red` con lo stesso bordo.
struct WidgetProgressBar: View {
    let progress: Double
    let width: CGFloat
    let height: CGFloat
    @Environment(\.manga) private var c

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(c.paper)
            Rectangle().fill(c.red)
                .overlay(Rectangle().strokeBorder(c.ink, lineWidth: 1.5))
                .frame(width: width * CGFloat(min(1, max(0, progress))))
        }
        .frame(width: width, height: height)
        .overlay(Rectangle().strokeBorder(c.ink, lineWidth: 1.5))
    }
}

enum WidgetText {
    static func steps(_ plan: Plan?) -> String { plan.map { ItalianFormat.integer($0.steps) } ?? "—" }

    /// Passi compatti per il tondo del blocco schermo: da 10.000 in su «10,4K».
    static func compactSteps(_ plan: Plan?) -> String {
        guard let s = plan?.steps else { return "—" }
        return s >= 10_000 ? ItalianFormat.number(Double(s) / 1000, decimals: 1) + "K" : ItalianFormat.integer(s)
    }

    static func summary(_ d: WidgetSnapshot) -> String {
        guard let p = d.plan else { return "Passi non disponibili: apri l'app" }
        var s = "\(ItalianFormat.integer(p.steps)) passi su \(ItalianFormat.integer(p.goal))"
        if p.isDone { s += ", obiettivo raggiunto" }
        else { s += ", mancano \(p.minutes) minuti, \(ItalianFormat.number(p.km, decimals: 1)) chilometri" }
        return s + ". Serie: \(d.streak) giorni, Jolly: \(d.jolly)"
    }
}
