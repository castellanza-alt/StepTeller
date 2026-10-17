import SwiftUI
import StepTellerCore

/// Pagina «Storico» (unica, a scorrimento) come nel mockup: fiamma con i giorni consecutivi e Jolly sopra
/// la collina, sentiero rosso, «I miei passi» (settimana/mese/anno/sempre) e «Il mio meglio» (record)
/// sopra il paesaggio. Scorrendo verso destra si torna a Oggi.
struct HistoryView: View {
    @Environment(StepsStore.self) private var store
    @State private var period: HistoryPeriod
    @State private var offset = 0
    @State private var best: BestKind = .day
    let onSettings: () -> Void
    let onToday: () -> Void

    init(onSettings: @escaping () -> Void, onToday: @escaping () -> Void) {
        self.onSettings = onSettings
        self.onToday = onToday
        var per = HistoryPeriod.week
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "stepteller.debugPeriod") {
        case "month": per = .month
        case "year": per = .year
        case "all": per = .all
        default: break
        }
        #endif
        _period = State(initialValue: per)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        streakSection(width: w)
                        TrailLine().frame(height: 70).padding(.leading, w * 0.1).padding(.trailing, w * 0.12)
                            .padding(.top, -26)
                        StepsSection(period: $period, offset: $offset, width: w)
                        TrailLine(flipped: true).frame(height: 64).padding(.horizontal, w * 0.12)
                        bestSection(width: w).id("fondo")
                    }
                }
                .scrollIndicators(.hidden)
                #if DEBUG
                .onAppear {     // solo screenshot: `-stepteller.debugScroll 1` mostra il fondo della pagina
                    if UserDefaults.standard.object(forKey: "stepteller.debugScroll") != nil {
                        reader.scrollTo("fondo", anchor: .bottom)
                    }
                }
                #endif
            }
            .ignoresSafeArea(edges: .bottom)
            // scorrere verso destra riporta a Oggi
            .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { g in
                if g.translation.width > 60, abs(g.translation.width) > abs(g.translation.height) * 1.5 { onToday() }
            })
            .overlay(alignment: .bottomLeading) {
                RoundIconButton(label: "Oggi", action: onToday) {
                    Image(systemName: "shoeprints.fill").font(.system(size: 22, weight: .medium))
                }
                .padding(.leading, 22).padding(.bottom, 6)
            }
        }
    }

    // MARK: streak e Jolly

    private func streakSection(width w: CGFloat) -> some View {
        let h = store.history
        let streak = h.shownStreak
        let jolly = h.shownJolly
        let s = h.streak
        let artWidth = w * 0.86
        return VStack(spacing: 0) {
            HStack {
                Spacer()
                RoundIconButton(label: "Impostazioni", action: onSettings) { SlidersIcon() }
            }
            .padding(.horizontal, 22).padding(.top, 4)

            // fiamma con il numero sopra, poi i Jolly
            HStack(alignment: .center, spacing: 14) {
                ZStack(alignment: .leading) {
                    Image("ArtFiamma").resizable().scaledToFit()
                        .frame(width: 150, height: 150)
                        .opacity(streak > 0 ? 1 : 0.35)
                        .offset(x: -18, y: -6)
                        .accessibilityHidden(true)
                    VStack(alignment: .trailing, spacing: -4) {
                        SketchText("\(streak)", size: 112)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: streak)
                        Text("giorni consecutivi").font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink)
                            .fixedSize()
                    }
                    .padding(.leading, 46)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Streak: \(streak) giorni consecutivi")

                Rectangle().fill(Theme.ink.opacity(0.7)).frame(width: 1.5, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: -6) {
                        ForEach(0..<min(max(jolly, 0), 3), id: \.self) { _ in JollyGem().frame(width: 34, height: 34) }
                        if jolly == 0 { JollyGem(empty: true).frame(width: 34, height: 34) }
                    }
                    Text(jolly == 1 ? "1 Jolly\ndisponibile" : "\(jolly) Jolly\ndisponibili")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink)
                        .fixedSize()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Jolly disponibili: \(jolly)")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)

            // collina a sinistra; nel vuoto a destra il record della streak e il prossimo Jolly
            ZStack(alignment: .topTrailing) {
                Image("ArtStoricoAlto").resizable().scaledToFit()
                    .frame(width: artWidth)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 18) {
                    note(title: "La mia serie più lunga") {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            SketchText("\(max(s.longest, streak))", size: 40)
                            Text("giorni").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                        }
                    }
                    note(title: "Prossimo Jolly") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.daysToNextJolly == 1 ? "tra 1 giorno" : "tra \(s.daysToNextJolly) giorni")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                            JollyProgress(value: s.counter, total: StreakEngine.jollyEvery).frame(width: 130, height: 10)
                        }
                    }
                }
                .padding(.trailing, 26).padding(.top, artWidth * 0.30)
            }
            .padding(.top, -34)
        }
    }

    private func note<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(1.6)
                .foregroundStyle(Theme.ink.opacity(0.7))
            content()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .glass(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: il mio meglio

    private func bestSection(width w: CGFloat) -> some View {
        let r = store.history.stats.personalRecords()
        let entry = bestEntry(r, longest: store.history.streak.longest)
        let artHeight = w * 1088 / 1456
        let text = entry?.value ?? "—"
        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                SketchTitle("Il mio meglio")
                PillPicker(options: BestKind.allCases.map { ($0, $0.title) }, selection: $best)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 0) {
                Image(systemName: "laurel.leading").font(.system(size: 88, weight: .light))
                    .foregroundStyle(Theme.accent)
                VStack(spacing: 0) {
                    SketchText(text, size: SketchFont.fitted(text, base: 70, width: w * 0.46))
                        .contentTransition(.numericText())
                    Text(entry?.unit ?? "nessun dato").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(entry?.label ?? " ").font(.system(size: 15)).foregroundStyle(Theme.ink.opacity(0.8))
                }
                .frame(minWidth: w * 0.46)
                Image(systemName: "laurel.trailing").font(.system(size: 88, weight: .light))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 20)
            .animation(.snappy, value: best)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.map { "Record \(best.title): \($0.value) \($0.unit), \($0.label)" } ?? "Record \(best.title): nessun dato")

            Image("ArtStoricoBasso").resizable().scaledToFit()
                .frame(width: w, height: artHeight)
                .padding(.top, -artHeight * 0.32)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension HistoryView {
    private struct BestEntry {
        let value: String
        let unit: String
        let label: String
    }

    private func bestEntry(_ r: PersonalRecords, longest: Int) -> BestEntry? {
        func steps(_ e: RecordEntry?) -> BestEntry? {
            e.map { BestEntry(value: ItalianFormat.integer($0.steps), unit: "passi", label: $0.label) }
        }
        switch best {
        case .day: return steps(r.day)
        case .week: return steps(r.week)
        case .month: return steps(r.month)
        case .year: return steps(r.year)
        case .streak:
            return longest > 0 ? BestEntry(value: "\(longest)", unit: longest == 1 ? "giorno" : "giorni",
                                           label: "serie più lunga") : nil
        }
    }
}

enum BestKind: CaseIterable, Hashable {
    case day, week, month, year, streak
    var title: String {
        switch self {
        case .day: "Giorno"
        case .week: "Settimana"
        case .month: "Mese"
        case .year: "Anno"
        case .streak: "Serie"
        }
    }
}

// MARK: - I miei passi

struct StepsSection: View {
    @Environment(StepsStore.self) private var store
    @Binding var period: HistoryPeriod
    @Binding var offset: Int
    let width: CGFloat

    var body: some View {
        let stats = store.history.stats
        let summary = stats.summary(period, offset: offset)
        let maxOff = stats.maxOffset(period)
        let total = ItalianFormat.integer(summary.steps)
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 18) {
                SketchTitle("I miei passi")
                PillPicker(options: [(HistoryPeriod.week, "Settimana"), (.month, "Mese"), (.year, "Anno"), (.all, "Sempre")],
                           selection: Binding(get: { period }, set: { period = $0; offset = 0 }))
                    .padding(.horizontal, width * 0.06)
            }
            .padding(.horizontal, 24)

            HStack {
                navButton("chevron.left", "Periodo precedente", disabled: period == .all || offset >= maxOff) { offset += 1 }
                Spacer()
                Text(stats.title(period, offset: offset)).font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Spacer()
                navButton("chevron.right", "Periodo successivo", disabled: period == .all || offset == 0) { offset -= 1 }
            }
            .padding(.horizontal, width * 0.18)
            .animation(.snappy, value: offset)

            ZStack(alignment: .trailing) {
                VStack(spacing: 0) {
                    SketchText(total, size: SketchFont.fitted(total, base: 78, width: width * 0.6))
                        .contentTransition(.numericText())
                        .animation(.snappy, value: summary.steps)
                        .padding(.horizontal, 22).padding(.vertical, 2)
                        .background(ScribbleOval().padding(.horizontal, -6))
                    Text("passi").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Totale: \(total) passi")

                Image("ArtImpronte").resizable().scaledToFit().frame(width: 38)
                    .padding(.trailing, 14)
                    .offset(y: 70)
                    .accessibilityHidden(true)
            }

            SketchBarChart(bars: stats.bars(period, offset: offset), period: period)
                .padding(.leading, 22).padding(.trailing, width * 0.16)

            HStack(alignment: .center, spacing: 12) {
                Spacer()
                Text("Media").font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.ink)
                SketchText(ItalianFormat.integer(summary.averageSteps), size: 44)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: summary.averageSteps)
                    .overlay { Sparkles().padding(-14) }
                Text("passi al giorno").font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.top, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Media: \(ItalianFormat.integer(summary.averageSteps)) passi al giorno")
        }
        .animation(.easeInOut(duration: 0.25), value: period)
    }

    private func navButton(_ symbol: String, _ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
                .frame(width: 36, height: 36).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
        .disabled(disabled).opacity(disabled ? 0.2 : 1)
        .accessibilityLabel(label)
    }
}

// MARK: - Componenti

/// Titolo di sezione in Anton inclinato con pennellata rossa sotto.
struct SketchTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        SketchText(text, size: 36)
            .transformEffect(CGAffineTransform(a: 1, b: -0.035, c: -0.2, d: 1, tx: 8, ty: 0))
            .padding(.bottom, 4)
            .background(alignment: .bottomLeading) {
                BrushStroke(shape: UnderlineSwash(), width: 3.2)
                    .frame(height: 10)
                    .padding(.trailing, -30).padding(.leading, -10)
                    .offset(y: 8)
            }
            .accessibilityAddTraits(.isHeader)
    }
}

/// Sottolineatura a pennello leggermente curva.
private struct UnderlineSwash: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                   control1: CGPoint(x: rect.width * 0.35, y: rect.minY - 2),
                   control2: CGPoint(x: rect.width * 0.7, y: rect.minY + 4))
        return p
    }
}

/// Selettore a pillola in vetro: la voce scelta è una capsula rossa che scivola sulla nuova voce.
struct PillPicker<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.0 == selection
                Button { withAnimation(.spring(duration: 0.35, bounce: 0.2)) { selection = option.0 } } label: {
                    Text(option.1)
                        .font(.system(size: 14, weight: selected ? .semibold : .regular))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .foregroundStyle(selected ? Theme.onAccent : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(LinearGradient(colors: [Theme.accent.opacity(0.85), Theme.accent],
                                                         startPoint: .top, endPoint: .bottom))
                                    .shadow(color: Theme.accent.opacity(0.4), radius: 6, y: 2)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .glass(Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Jolly: rombo rosso lucido.
struct JollyGem: View {
    var empty = false
    var body: some View {
        ZStack {
            DiamondShape().fill(empty ? AnyShapeStyle(Theme.faint)
                                      : AnyShapeStyle(LinearGradient(colors: [Theme.accent.opacity(0.75), Theme.accent],
                                                                     startPoint: .topLeading, endPoint: .bottomTrailing)))
            DiamondShape().stroke(empty ? Theme.soft : Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            DiamondShape().inset(by: 9).fill(.white.opacity(empty ? 0 : 0.35))
        }
        .shadow(color: Theme.accent.opacity(empty ? 0 : 0.35), radius: 4, y: 2)
    }
}

/// Rombo con gli angoli arrotondati (quadrato ruotato).
struct DiamondShape: InsettableShape {
    var inset: CGFloat = 0
    func inset(by amount: CGFloat) -> DiamondShape { DiamondShape(inset: inset + amount) }
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p.strokedPath(StrokeStyle(lineWidth: max(0, r.width * 0.16), lineJoin: .round)).union(p)
    }
}

/// Avanzamento verso il prossimo Jolly: tacche a matita, piene in rosso fin dove si è arrivati.
private struct JollyProgress: View {
    let value: Int
    let total: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                Capsule().fill(i < value ? Theme.accent : Theme.ink.opacity(0.18))
            }
        }
        .animation(.snappy, value: value)
    }
}

/// Ovale rosso a pennello attorno al totale (due mezze passate, come nel mockup).
private struct ScribbleOval: View {
    var body: some View {
        ZStack {
            BrushStroke(shape: OvalArc(from: 100, to: 255), width: 2.6)
            BrushStroke(shape: OvalArc(from: -75, to: 70), width: 2.6)
            BrushStroke(shape: OvalArc(from: 200, to: 300), width: 1.4).offset(x: 4, y: -3).opacity(0.7)
        }
        .allowsHitTesting(false)
    }
}

private struct OvalArc: Shape {
    let from: Double
    let to: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 40
        for i in 0...steps {
            let a = (from + (to - from) * Double(i) / Double(steps)) * .pi / 180
            let pt = CGPoint(x: rect.midX + rect.width / 2 * cos(a), y: rect.midY + rect.height / 2 * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

/// Trattini rossi a raggiera attorno a un numero.
private struct Sparkles: View {
    var body: some View {
        Canvas { ctx, size in
            let marks: [(CGFloat, CGFloat, Double)] = [(0.02, 0.22, -150), (-0.02, 0.5, 180), (0.02, 0.78, 150),
                                                       (0.98, 0.22, -30), (1.02, 0.5, 0), (0.98, 0.78, 30)]
            for (x, y, deg) in marks {
                let a = deg * .pi / 180
                let start = CGPoint(x: x * size.width, y: y * size.height)
                var p = Path()
                p.move(to: start)
                p.addLine(to: CGPoint(x: start.x + cos(a) * 9, y: start.y + sin(a) * 9))
                ctx.stroke(p, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Sentiero rosso tratteggiato che collega le sezioni; i trattini scorrono piano (fermi con «Riduci movimento»).
struct TrailLine: View {
    var flipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        TrailShape()
            .stroke(Theme.accent.opacity(0.8), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [9, 6], dashPhase: phase))
            .scaleEffect(x: flipped ? -1 : 1)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { phase = -15 }
            }
    }
}

private struct TrailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                   control1: CGPoint(x: rect.width * 0.8, y: rect.minY - rect.height * 0.2),
                   control2: CGPoint(x: rect.width * 0.2, y: rect.maxY + rect.height * 0.2))
        return p
    }
}
