import SwiftUI
import StepTellerCore

enum StepsMetric { case steps, km }

enum BestTab: CaseIterable { case day, week, month, year, streak }

/// History: streak and Jollies, «I MIEI PASSI» (week · month · year · all) and «IL MIO MEGLIO».
/// 390 × 2020 handoff canvas, scaled to the width; scrolls under the fixed bar.
struct HistoryView: View {
    let size: CGSize
    @Environment(StepsStore.self) private var store
    @Environment(\.manga) private var c

    @State private var tabSteps: HistoryPeriod
    @State private var periodOffset = 0
    @State private var selectedBar: Int?
    @State private var tabBest: BestTab = .day
    @State private var metric: StepsMetric = .steps
    @State private var grow: CGFloat = 1
    @State private var punch: CGFloat = 1
    @State private var jollyWidth: CGFloat = 200
    /// Debug only (screenshots): `-stepteller.debugScroll 0.5` opens the History already scrolled (0 = top, 1 = bottom).
    private let initialAnchor: UnitPoint?

    init(size: CGSize) {
        self.size = size
        var per = HistoryPeriod.week
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "stepteller.debugPeriod") {
        case "month": per = .month
        case "year": per = .year
        case "all": per = .all
        default: break
        }
        #endif
        _tabSteps = State(initialValue: per)
        var anchor: UnitPoint?
        #if DEBUG
        if UserDefaults.standard.object(forKey: "stepteller.debugScroll") != nil {
            anchor = UnitPoint(x: 0.5, y: UserDefaults.standard.double(forKey: "stepteller.debugScroll"))
        }
        #endif
        initialAnchor = anchor
    }

    var body: some View {
        ScrollView {
            MangaCanvas(width: size.width, height: Manga.historyHeight) {
                Board {
                    streakSection
                    stepsSection
                    bestSection
                }
            }
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(initialAnchor)
        .ignoresSafeArea()
        .background(c.paper)
        .onChange(of: tabSteps) { _, _ in periodOffset = 0; selectedBar = nil; replayBars() }
        .onChange(of: periodOffset) { _, _ in selectedBar = nil; replayBars() }
        .onChange(of: metric) { _, _ in selectedBar = nil; replayBars() }
    }

    /// Tab change: the bars regrow from the bottom (light spring) and the big number gets a small «punch».
    private func replayBars() {
        var t = Transaction(); t.disablesAnimations = true
        withTransaction(t) { grow = 0; punch = 1.06 }
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.4, bounce: 0.25)) { grow = 1; punch = 1 }
        }
    }

    // MARK: - Streak and Jollies

    @ViewBuilder private var streakSection: some View {
        let st = store.history.streak
        RaysView(rays: Self.burst)
            .frame(width: 390, height: 520)
            .mask(RadialGradient(stops: [.init(color: .clear, location: 0.25), .init(color: .white, location: 0.55),
                                         .init(color: .white.opacity(0.2), location: 1)],
                                 center: UnitPoint(x: 150.0 / 390, y: 250.0 / 520), startRadius: 0, endRadius: 300))
            .at(0, 0)
        Image(c.hill).resizable().scaledToFit().frame(width: 200)
            .accessibilityHidden(true)
            .at(-10, 560)
        // big flame
        ZStack {
            SVGShape(MangaPaths.flame, viewBox: MangaPaths.flameBox).fill(c.red)
            SVGShape(MangaPaths.flame, viewBox: MangaPaths.flameBox)
                .stroke(c.ink, style: StrokeStyle(lineWidth: 0.55 * 150 / 18, lineJoin: .round))
            SVGShape(MangaPaths.flameCore, viewBox: MangaPaths.flameBox).fill(c.paper)
        }
        .frame(width: 150, height: 184)
        .rotationEffect(.degrees(-12))
        .accessibilityHidden(true)
        .at(30, 138)
        VStack(alignment: .leading, spacing: 0) {
            GlyphText(text: "\(st.streak)", size: 200, lineHeight: 0.86, tracking: -0.04, fill: c.ink,
                      stroke: c.ink, strokeWidth: 2, shadow: (c.red, 7, 7))
            AntonText(L10n.format("st.streak", st.streak), 30, tracking: 0.02)
                .padding(.top, 4 + TitleFont.gap(30)).padding(.leading, 6)
        }
        .manga(rotate: -8, skew: -10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.streak.vo", st.streak))
        .at(112, 118)
        jollyGroup(st.jolly)
            .manga(rotate: -6)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { jollyWidth = $0 }
            .at(min(196, Manga.frameWidth - 8 - jollyWidth), 316 + TitleFont.gap(44))   // under the streak caption, lowered in JA/KO/ZH
        Vignette(shape: .panelA, width: 220) {
            VStack(alignment: .leading, spacing: 2) {
                AntonText(L10n.text("st.longest.title"), 14, tracking: 0.08)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    AntonText("\(st.longest)", 74, lineHeight: 0.95, tracking: -0.03)
                    AntonText(L10n.format("st.days", st.longest), 22, color: c.red)
                }
                .manga(skew: -10)
            }
        }
        .rotationEffect(.degrees(-4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.longest.vo", "\(st.longest)"))
        .at(18, 440)
        Vignette(shape: .panelB, width: 222) {
            VStack(alignment: .leading, spacing: 8) {
                AntonText(L10n.text("st.nextJolly.title"), 14, tracking: 0.08)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    AntonText(L10n.text("st.nextJolly.in"), 15)
                    AntonText("\(st.daysToNextJolly)", 40, lineHeight: 0.9, color: c.red)
                    AntonText(L10n.format("st.days", st.daysToNextJolly), 15)
                }
                .manga(skew: -10)
                HStack(spacing: 3) {
                    ForEach(0..<Manga.jollyTicks, id: \.self) { i in
                        Rectangle().fill(i < st.counter ? c.red : c.paper)
                            .overlay(Rectangle().strokeBorder(c.ink, lineWidth: 1.5))
                            .frame(maxWidth: .infinity).frame(height: 12)
                            .manga(skew: -18)
                    }
                }
                .frame(width: 222 - 32)
            }
        }
        .rotationEffect(.degrees(3))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.nextJolly.vo", "\(st.daysToNextJolly)", "\(st.counter)", "\(Manga.jollyTicks)"))
        .at(150, 590)
    }

    private func jollyGroup(_ jolly: Int) -> some View {
        HStack(spacing: 8) {
            if jolly > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(jolly, 3), id: \.self) { _ in
                        FlameIcon(kind: .jolly).frame(width: 34, height: 42)
                    }
                }
            }
            TagText(text: jolly == 0 ? L10n.text("st.jolly.none") : L10n.format("st.jolly", jolly),
                    size: 15, tracking: 0.04, foreground: c.paper, background: c.ink,
                    padding: EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                .manga(skew: -10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.jolly.vo", "\(jolly)"))
    }

    // MARK: - My steps

    @ViewBuilder private var stepsSection: some View {
        let stats = store.history.stats
        BrushTitle(text: L10n.text("st.steps.title"), brushWidth: 290).at(18, 790)
        MangaTabs(items: [(StepsMetric.steps, L10n.text("st.metric.steps")), (.km, L10n.text("st.metric.km"))], selection: $metric,
                  width: 92, height: 28, fontSize: 13, tracking: 0.04, gap: 3, rotation: -5)
            .at(282, 846)
        MangaTabs(items: [(HistoryPeriod.week, L10n.text("st.tab.week")), (.month, L10n.text("st.tab.month")),
                          (.year, L10n.text("st.tab.year")), (.all, L10n.text("st.tab.all"))],
                  selection: $tabSteps, width: 350, height: 38, fontSize: 16, tracking: 0.04, gap: 4)
            .at(20, 896)
        periodNav(stats).frame(width: 330).at(30, 960)
        RaysView(rays: Self.speedLines).frame(width: 390, height: 200).at(0, 1000)
        bigNumber(stats)
            .frame(width: 390)
            .manga(rotate: -6, skew: -10)
            .scaleEffect(punch)
            .at(0, 1010)
        MangaBarChart(bars: chartBars(stats), goal: metric == .steps ? Double(chartGoal(stats)) : nil,
                      goalLabel: LocalFormat.integer(chartGoal(stats)), selected: $selectedBar, grow: grow)
            .frame(width: 346, height: 230)
            .at(24, 1190)
        secondaryRow(stats)
            .manga(rotate: 4, skew: -10)
            .at(28, 1462)
    }

    private func periodNav(_ stats: HistoryStats) -> some View {
        let maxOff = stats.maxOffset(tabSteps)
        return HStack {
            Button { if periodOffset < maxOff { periodOffset += 1 } } label: {
                ChevronGlyph(forward: false).frame(width: 40, height: 40).contentShape(Rectangle())
            }
            .opacity(periodOffset < maxOff ? 1 : 0.25)
            .accessibilityLabel(L10n.text("st.prev.vo"))
            Spacer(minLength: 0)
            AntonText(stats.title(tabSteps, offset: periodOffset).uppercased(), 22, tracking: 0.03)
                .manga(skew: -10)
            Spacer(minLength: 0)
            Button { if periodOffset > 0 { periodOffset -= 1 } } label: {
                ChevronGlyph(forward: true).frame(width: 40, height: 40).contentShape(Rectangle())
            }
            .opacity(periodOffset > 0 ? 1 : 0.25)
            .accessibilityLabel(L10n.text("st.next.vo"))
        }
        .buttonStyle(.plain)
    }

    /// Big number: week = **sum** of the period; month/year/all = **daily average**.
    private func bigNumber(_ stats: HistoryStats) -> some View {
        let isWeek = tabSteps == .week
        let sum = stats.summary(tabSteps, offset: periodOffset)
        let avg = stats.dailyAverage(tabSteps, offset: periodOffset)
        let text: String
        let label: String
        switch (metric, isWeek) {
        case (.steps, true): text = LocalFormat.integer(sum.steps); label = L10n.text("st.big.steps")
        case (.steps, false): text = LocalFormat.integer(avg.steps); label = L10n.text("st.big.stepsAvg")
        case (.km, true): text = Self.km(sum.km); label = L10n.text("st.big.km")
        case (.km, false): text = Self.km(avg.km); label = L10n.text("st.big.kmAvg")
        }
        let size: CGFloat = [120, 120, 120, 120, 120, 120, 120, 110, 96, 82, 72][min(10, text.count)]
        return VStack(spacing: 0) {
            ZStack {
                AntonText(text, size, lineHeight: 0.9, tracking: -0.04, color: c.red).offset(x: 5, y: 5)
                AntonText(text, size, lineHeight: 0.9, tracking: -0.04)
            }
            TagText(text: label, size: 20, tracking: 0.3, foreground: c.paper, background: c.ink,
                    padding: EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 10))
                .padding(.top, 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.big.vo", text, label.lowercased()))
    }

    /// Week: «MEDIA … AL GIORNO»; other tabs: «TOTALE … NEL PERIODO».
    private func secondaryRow(_ stats: HistoryStats) -> some View {
        let isWeek = tabSteps == .week
        let value: String
        if isWeek {
            let a = stats.dailyAverage(.week, offset: periodOffset)
            value = metric == .steps ? LocalFormat.integer(a.steps) : Self.km(a.km)
        } else {
            let t = stats.summary(tabSteps, offset: periodOffset)
            value = metric == .steps ? LocalFormat.integer(t.steps) : Self.km(t.km)
        }
        let size: CGFloat = isWeek ? 64 : (value.count > 9 ? 40 : 52)
        return HStack(spacing: 10) {
            AntonText(L10n.text(isWeek ? "st.second.avg" : "st.second.total"), 18, tracking: 0.06)
            GlyphText(text: value, size: size, lineHeight: 0.9, tracking: -0.03, fill: c.red, stroke: c.ink, strokeWidth: 1.5)
            VStack(alignment: .leading, spacing: 0) {
                AntonText(L10n.text(metric == .steps ? "st.big.steps" : "st.big.km"), 16, tracking: 0.04)
                AntonText(L10n.text(isWeek ? "st.second.perDay" : "st.second.inPeriod"), 16, tracking: 0.04)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format(isWeek ? (metric == .steps ? "st.second.vo.avgSteps" : "st.second.vo.avgKm")
                                               : (metric == .steps ? "st.second.vo.totSteps" : "st.second.vo.totKm"), value))
    }

    /// Bars of the period. Week: 7 days (future ones empty); current month and year: up to today.
    /// Year and All: daily average of month/year, so the goal applies in every tab.
    private func chartBars(_ stats: HistoryStats) -> [MangaBar] {
        var bars = stats.averageBars(tabSteps, offset: periodOffset)
        if periodOffset == 0 && tabSteps != .week { bars = bars.filter { !$0.isFuture } }
        let goal = store.goal
        return bars.enumerated().map { i, b in
            let target = b.goal > 0 ? b.goal : goal
            let style: MangaBar.Style
            if b.isFuture { style = .future }
            else if b.isCurrent && tabSteps != .all { style = .current }
            else { style = target > 0 && b.steps >= target ? .hit : .miss }
            let showLabel = tabSteps != .month || i % 5 == 0 || i == bars.count - 1
            return MangaBar(id: b.id, label: b.label, showLabel: showLabel,
                            value: metric == .steps ? Double(b.steps) : b.km,
                            display: metric == .steps ? LocalFormat.integer(b.steps) : Self.km(b.km) + " KM",
                            style: style)
        }
    }

    private func chartGoal(_ stats: HistoryStats) -> Int {
        guard tabSteps == .week || tabSteps == .month else { return store.goal }
        return stats.bars(tabSteps, offset: periodOffset).last(where: { !$0.isFuture })?.goal ?? store.goal
    }

    // MARK: - My best

    @ViewBuilder private var bestSection: some View {
        let best = bestValue()
        let size: CGFloat = best.value.count > 7 ? 74 : best.value.count > 6 ? 88 : 104
        BrushTitle(text: L10n.text("st.best.title"), brushWidth: 320).at(18, 1572)
        MangaTabs(items: [(BestTab.day, L10n.text("st.best.tab.day")), (.week, L10n.text("st.best.tab.week")),
                          (.month, L10n.text("st.best.tab.month")), (.year, L10n.text("st.best.tab.year")),
                          (.streak, L10n.text("st.best.tab.streak"))],
                  selection: $tabBest, width: 362, height: 36, fontSize: 13, tracking: 0.03, gap: 3)
            .at(14, 1676)
        Image(c.horizon).resizable().scaledToFit().frame(width: 406)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.45)],
                                 startPoint: .top, endPoint: .bottom))
            .accessibilityHidden(true)
            .at(-8, Manga.historyHeight + 6 - 406 * 330 / 500)
        Canvas { ctx, _ in
            ctx.fill(Self.starOuter, with: .color(c.ink))
            ctx.fill(Self.starInner, with: .color(c.red))
        }
        .frame(width: 390, height: 260)
        .allowsHitTesting(false)
        .at(0, 1720)
        VStack(spacing: 0) {
            GlyphText(text: best.value, size: size, lineHeight: 0.9, tracking: -0.03, fill: c.paper,
                      stroke: c.ink, strokeWidth: 2.5, shadow: (c.ink, 5, 5))
            HStack(spacing: 8) {
                TagText(text: best.unit, size: 18, tracking: 0.14, foreground: c.paper, background: c.ink)
                TagText(text: best.when, size: 18, tracking: 0.06, foreground: c.ink, background: c.paper, border: c.ink)
            }
            .padding(.top, 12)
        }
        .frame(width: 390)
        .manga(rotate: -5, skew: -10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("st.best.vo", best.value, best.unit.lowercased(), best.when.lowercased()))
        .at(0, 1770)
    }

    private func bestValue() -> (value: String, unit: String, when: String) {
        let stats = store.history.stats
        let r = store.history.personalRecords
        func entry(_ e: RecordEntry?) -> (String, String, String) {
            let unit = L10n.text(metric == .steps ? "st.best.unit.steps" : "st.big.km")
            guard let e else { return ("—", unit, L10n.text("st.best.noData")) }
            return (metric == .steps ? LocalFormat.integer(e.steps) : Self.km(e.km), unit, e.label.uppercased())
        }
        switch tabBest {
        case .day: return entry(r.day)
        case .week: return entry(r.week)
        case .month: return entry(r.month)
        case .year: return entry(r.year)
        case .streak:
            let s = store.history.streak
            let when: String
            if let a = s.longestStart, let b = s.longestEnd { when = stats.rangeLabel(from: a, to: b).uppercased() }
            else { when = "—" }
            return ("\(s.longest)", L10n.format("st.best.streak", s.longest), when)
        }
    }

    private static func km(_ v: Double) -> String { LocalFormat.number(v, decimals: v >= 100 ? 0 : 1) }

    // MARK: - Fixed drawings (same seeds as the prototype)

    private static let burst = KineticLines.rays(cx: 150, cy: 250, count: 80, innerMin: 110, innerMax: 170, outer: 520, seed: 5, redEvery: 9)
    private static let speedLines = KineticLines.rays(cx: 195, cy: 100, count: 60, innerMin: 120, innerMax: 160, outer: 330, seed: 9)
    private static let starOuter = KineticLines.star(cx: 195, cy: 118, points: 16, outer: 112, inner: 74, rotation: 0.1)
    private static let starInner = KineticLines.star(cx: 195, cy: 118, points: 16, outer: 98, inner: 64, rotation: 0.1)
}
