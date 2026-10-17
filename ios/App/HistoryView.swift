import SwiftUI
import StepTellerCore

/// Pagina «Storico» (unica, a scorrimento): streak e Jolly con il calendario del mese, «I miei passi»
/// (settimana/mese/anno/sempre) e «Il mio meglio» (record). Illustrazioni in alto e in fondo.
struct HistoryView: View {
    @Environment(StepsStore.self) private var store
    @State private var period: HistoryPeriod
    @State private var offset = 0
    @State private var monthOffset = 0
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
                        TrailLine().frame(height: 56).padding(.horizontal, 40)
                        StepsSection(period: $period, offset: $offset)
                            .padding(.horizontal, 22)
                        TrailLine(flipped: true).frame(height: 56).padding(.horizontal, 40)
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
            .overlay(alignment: .bottomLeading) {
                RoundIconButton(label: "Oggi", action: onToday) {
                    Image(systemName: "shoeprints.fill").font(.system(size: 22, weight: .medium))
                }
                .padding(.leading, 22).padding(.bottom, 6)
            }
        }
    }

    // MARK: streak, Jolly e calendario

    private func streakSection(width w: CGFloat) -> some View {
        let s = store.history.streak
        let stats = store.history.stats
        let maxMonth = stats.maxOffset(.month)
        return VStack(spacing: 0) {
            HStack {
                Spacer()
                RoundIconButton(label: "Impostazioni", action: onSettings) { SlidersIcon() }
            }
            .padding(.horizontal, 22).padding(.top, 4)

            HStack(alignment: .center, spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    Image("ArtFiamma").resizable().scaledToFit()
                        .frame(width: 150, height: 150)
                        .opacity(s.streak > 0 ? 1 : 0.35)
                        .accessibilityHidden(true)
                    VStack(alignment: .trailing, spacing: 0) {
                        SketchText("\(s.streak)", size: 104)
                        Text("giorni consecutivi").font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink)
                            .fixedSize()
                            .padding(.horizontal, 6)
                            .paperHalo()
                    }
                    .offset(x: 40, y: 14)
                }
                .frame(width: 170, height: 160, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Streak: \(s.streak) giorni consecutivi")

                Rectangle().fill(Theme.ink.opacity(0.6)).frame(width: 1.5, height: 60).padding(.leading, 14)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: -4) {
                        ForEach(0..<min(max(s.jolly, 0), 3), id: \.self) { _ in JollyGem().frame(width: 34, height: 34) }
                        if s.jolly == 0 { JollyGem(empty: true).frame(width: 34, height: 34) }
                    }
                    Text(s.jolly == 1 ? "1 Jolly disponibile" : "\(s.jolly) Jolly disponibili")
                        .font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Jolly disponibili: \(s.jolly)")
                Spacer(minLength: 0)
            }
            .padding(.leading, 30).padding(.top, 6)

            VStack(spacing: 10) {
                HStack {
                    chevron("chevron.left", "Mese precedente", disabled: monthOffset >= maxMonth) { monthOffset += 1 }
                    Spacer()
                    Text(stats.title(.month, offset: monthOffset).uppercased())
                        .font(.system(size: 19, weight: .semibold)).tracking(0.6).foregroundStyle(Theme.ink)
                    Spacer()
                    chevron("chevron.right", "Mese successivo", disabled: monthOffset == 0) { monthOffset -= 1 }
                }
                CalendarGrid(monthStart: stats.interval(.month, offset: monthOffset).start,
                             mark: { store.history.mark(for: $0) }, today: stats.today)
            }
            .padding(12)
            .paperHalo()
            .frame(width: min(w * 0.68, 300))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 14).padding(.top, 18)
        }
        .padding(.bottom, 30)
        .background(alignment: .top) {
            Image("ArtStoricoAlto").resizable().scaledToFit()
                .frame(width: w)
                .padding(.top, 70)
                .accessibilityHidden(true)
        }
    }

    private func chevron(_ symbol: String, _ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { action() } }) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
                .frame(width: 36, height: 36).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.ink)
        .disabled(disabled).opacity(disabled ? 0.2 : 1)
        .accessibilityLabel(label)
    }

    // MARK: il mio meglio

    private func bestSection(width w: CGFloat) -> some View {
        let r = store.history.stats.personalRecords()
        let longest = store.history.streak.longest
        let entry = bestEntry(r, longest: longest)
        let artHeight = w * 1088 / 1456
        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                SketchTitle("Il mio meglio")
                PillPicker(options: BestKind.allCases.map { ($0, $0.title) }, selection: $best)
            }
            .padding(.horizontal, 22)

            HStack(spacing: 4) {
                Image(systemName: "laurel.leading").font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
                VStack(spacing: 0) {
                    let text = entry?.value ?? "—"
                    SketchText(text, size: SketchFont.fitted(text, base: 76, width: w * 0.48))
                    Text(entry?.unit ?? "nessun dato").font(.system(size: 19, weight: .bold)).foregroundStyle(Theme.ink)
                    Text(entry?.label ?? " ").font(.system(size: 15)).foregroundStyle(Theme.ink.opacity(0.75))
                }
                .frame(minWidth: w * 0.42)
                Image(systemName: "laurel.trailing").font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.map { "Record \(best.title): \($0.value) \($0.unit), \($0.label)" } ?? "Record \(best.title): nessun dato")
            .animation(.easeInOut(duration: 0.2), value: best)

            Image("ArtStoricoBasso").resizable().scaledToFit()
                .frame(width: w, height: artHeight)
                .padding(.top, -artHeight * 0.30)
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
                                           label: "streak più lunga") : nil
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

    var body: some View {
        let stats = store.history.stats
        let summary = stats.summary(period, offset: offset)
        let maxOff = stats.maxOffset(period)
        VStack(alignment: .leading, spacing: 18) {
            SketchTitle("I miei passi")
            PillPicker(options: [(HistoryPeriod.week, "Settimana"), (.month, "Mese"), (.year, "Anno"), (.all, "Sempre")],
                       selection: Binding(get: { period }, set: { period = $0; offset = 0 }))

            HStack {
                if period != .all {
                    navButton("chevron.left", "Periodo precedente", disabled: offset >= maxOff) { offset += 1 }
                }
                Spacer()
                Text(stats.title(period, offset: offset)).font(.system(size: 19, weight: .semibold)).foregroundStyle(Theme.ink)
                Spacer()
                if period != .all {
                    navButton("chevron.right", "Periodo successivo", disabled: offset == 0) { offset -= 1 }
                }
            }
            .padding(.horizontal, 30)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    SwirlBracket().frame(width: 18, height: 72)
                    SketchText(ItalianFormat.integer(summary.steps), size: 82)
                        .minimumScaleFactor(0.5)
                    SwirlBracket().scaleEffect(x: -1).frame(width: 18, height: 72)
                }
                Text("passi").font(.system(size: 19, weight: .bold)).foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Totale: \(ItalianFormat.integer(summary.steps)) passi")

            SketchBarChart(bars: stats.bars(period, offset: offset), period: period)
                .padding(.trailing, 40)
                .overlay(alignment: .topTrailing) {
                    Image("ArtImpronte").resizable().scaledToFit().frame(width: 40)
                        .offset(x: 18, y: -120)
                        .accessibilityHidden(true)
                }

            HStack(alignment: .center, spacing: 12) {
                Spacer()
                Text("Media").font(.system(size: 17, weight: .medium)).foregroundStyle(Theme.ink)
                SketchText(ItalianFormat.integer(summary.averageSteps), size: 44)
                    .overlay { Sparkles().padding(-14) }
                Text("passi al giorno").font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.top, 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Media: \(ItalianFormat.integer(summary.averageSteps)) passi al giorno")
        }
        .animation(.easeInOut(duration: 0.2), value: period)
    }

    private func navButton(_ symbol: String, _ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
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
        SketchText(text, size: 40)
            .transformEffect(CGAffineTransform(a: 1, b: -0.04, c: -0.2, d: 1, tx: 8, ty: 0))
            .padding(.bottom, 6)
            .background(alignment: .bottomLeading) {
                BrushStroke(shape: UnderlineSwash(), width: 3.5)
                    .frame(height: 12)
                    .padding(.trailing, -40).padding(.leading, -6)
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

/// Selettore a pillola: voce scelta in rosso pieno, le altre su fondo bianco separate da righe sottili.
struct PillPicker<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                let selected = option.0 == selection
                Button { withAnimation(.easeInOut(duration: 0.2)) { selection = option.0 } } label: {
                    Text(option.1)
                        .font(.system(size: 14, weight: selected ? .semibold : .regular))
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .foregroundStyle(selected ? Theme.onAccent : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background {
                            if selected {
                                Capsule().fill(Theme.accent).shadow(color: Theme.accent.opacity(0.45), radius: 6, y: 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .leading) {
                    if i > 0 && !selected && options[i - 1].0 != selection {
                        Rectangle().fill(Theme.cardLine).frame(width: 1, height: 42)
                    }
                }
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().strokeBorder(Theme.cardLine, lineWidth: 1))
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

/// Parentesi a ricciolo rosse ai lati del totale.
private struct SwirlBracket: View {
    var body: some View {
        BrushStroke(shape: SwirlShape(), width: 2.6)
    }
}

private struct SwirlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY),
                   control1: CGPoint(x: rect.minX - rect.width * 0.6, y: rect.height * 0.25),
                   control2: CGPoint(x: rect.minX - rect.width * 0.2, y: rect.height * 0.95))
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

/// Sentiero rosso tratteggiato che collega le sezioni.
struct TrailLine: View {
    var flipped = false
    var body: some View {
        TrailShape()
            .stroke(Theme.accent.opacity(0.75), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [9, 6]))
            .scaleEffect(x: flipped ? -1 : 1)
            .accessibilityHidden(true)
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
