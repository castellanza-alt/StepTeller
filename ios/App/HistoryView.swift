import SwiftUI
import StepTellerCore

enum HistorySection { case storico, streak }

/// Pagina «Storico»: selettore Storico | Streak in alto, poi il contenuto scelto.
struct HistoryView: View {
    @Environment(StepsStore.self) private var store
    @State private var section: HistorySection
    @State private var period: HistoryPeriod
    @State private var offset = 0
    @State private var metric: HistoryMetric = .steps
    let onSettings: () -> Void

    init(onSettings: @escaping () -> Void) {
        self.onSettings = onSettings
        var sec = HistorySection.storico
        var per = HistoryPeriod.week
        #if DEBUG
        let d = UserDefaults.standard
        if d.string(forKey: "stepteller.debugTab") == "streak" { sec = .streak }
        switch d.string(forKey: "stepteller.debugPeriod") {
        case "month": per = .month
        case "year": per = .year
        case "all": per = .all
        default: break
        }
        #endif
        _section = State(initialValue: sec)
        _period = State(initialValue: per)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                AppHeader(onSettings: onSettings) { EmptyView() }
                sectionTabs
                if section == .storico {
                    StoricoPage(period: $period, offset: $offset, metric: $metric)
                } else {
                    StreakPage()
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 130)
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    /// Selettore a due titoli con linea sotto quello attivo (diverso dai pulsanti dei periodi).
    private var sectionTabs: some View {
        HStack(alignment: .bottom, spacing: 30) {
            tab("Storico", .storico, icon: nil)
            tab("Streak", .streak, icon: "flame.fill")
            Spacer()
        }
        .padding(.horizontal, 2)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.ink.opacity(0.10)).frame(height: 1) }
    }

    private func tab(_ title: String, _ value: HistorySection, icon: String?) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { section = value } } label: {
            HStack(spacing: 7) {
                if let icon { Image(systemName: icon).font(.system(size: 14)) }
                Text(title).font(.system(size: 24, weight: .light)).tracking(-0.5)
            }
            .foregroundStyle(section == value ? Theme.ink : Theme.ink.opacity(0.40))
            .padding(.top, 4).padding(.bottom, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(section == value ? Theme.accent : .clear).frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(section == value ? .isSelected : [])
    }
}

// MARK: - Storico

struct StoricoPage: View {
    @Environment(StepsStore.self) private var store
    @Binding var period: HistoryPeriod
    @Binding var offset: Int
    @Binding var metric: HistoryMetric

    var body: some View {
        let stats = store.history.stats
        let summary = stats.summary(period, offset: offset)
        VStack(spacing: 10) {
            periodPicker
            chartCard(stats)
            statsGrid(summary)
            if period == .month { calendarCard(stats) }
            recordsCard(stats.personalRecords())
        }
    }

    private func calendarCard(_ stats: HistoryStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel("Calendario")
                Spacer()
                CalendarLegend()
            }
            CalendarGrid(monthStart: stats.interval(.month, offset: offset).start,
                         mark: { store.history.mark(for: $0) }, today: stats.today)
        }
        .glassCard(padding: EdgeInsets(top: 14, leading: 20, bottom: 12, trailing: 20))
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach([(HistoryPeriod.week, "Sett."), (.month, "Mese"), (.year, "Anno"), (.all, "Sempre")], id: \.1) { p, title in
                Button { period = p; offset = 0 } label: {
                    Text(title).font(.system(size: 12, weight: .semibold)).tracking(1.2)
                        .foregroundStyle(period == p ? Theme.accent : Theme.soft)
                        .frame(maxWidth: .infinity).frame(height: 32)
                        .background(Capsule().fill(period == p ? Theme.accentSoft : .clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.ink.opacity(0.06)))
        .overlay(Capsule().strokeBorder(Theme.ink.opacity(0.08), lineWidth: 1))
    }

    private func chartCard(_ stats: HistoryStats) -> some View {
        let maxOff = stats.maxOffset(period)
        return VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                if period != .all {
                    Button { if offset < maxOff { offset += 1 } } label: {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .disabled(offset >= maxOff).opacity(offset >= maxOff ? 0.3 : 1)
                    .accessibilityLabel("Periodo precedente")
                }
                Text(stats.title(period, offset: offset)).font(.system(size: 13, weight: .semibold))
                if period != .all {
                    Button { if offset > 0 { offset -= 1 } } label: {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .disabled(offset == 0).opacity(offset == 0 ? 0.3 : 1)
                    .accessibilityLabel("Periodo successivo")
                }
                Spacer()
                HStack(spacing: 4) {
                    metricButton("Passi", .steps)
                    metricButton("Km", .km)
                }
            }
            .foregroundStyle(Theme.ink)
            BarChartView(bars: stats.bars(period, offset: offset), metric: metric, period: period)
        }
        .glassCard(padding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
        .animation(.easeInOut(duration: 0.2), value: period)
    }

    private func metricButton(_ title: String, _ value: HistoryMetric) -> some View {
        Button { metric = value } label: {
            Text(title).font(.system(size: 11, weight: .semibold)).tracking(1.1)
                .foregroundStyle(metric == value ? Theme.accent : Theme.soft)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(metric == value ? Theme.accentSoft : .clear))
        }
        .buttonStyle(.plain)
    }

    private func statsGrid(_ s: PeriodSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            StatTile(title: "Totale", value: ItalianFormat.integer(s.steps), unit: "passi")
            StatTile(title: "Distanza", value: ItalianFormat.number(s.km, decimals: s.km >= 1000 ? 0 : 1), unit: "km")
            StatTile(title: "Media", value: ItalianFormat.integer(s.averageSteps), unit: "al giorno")
            StatTile(title: "A obiettivo", value: ItalianFormat.integer(s.daysAtGoal),
                     unit: "giorni su \(ItalianFormat.integer(s.elapsedDays))")
        }
    }

    private func recordsCard(_ r: PersonalRecords) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel("Record personali").padding(.bottom, 2)
            recordRow("Giorno", r.day, last: false)
            recordRow("Settimana", r.week, last: false)
            recordRow("Mese", r.month, last: false)
            recordRow("Anno", r.year, last: true)
        }
        .glassCard(padding: EdgeInsets(top: 14, leading: 20, bottom: 4, trailing: 20))
    }

    private func recordRow(_ title: String, _ r: RecordEntry?, last: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(r?.label ?? "—").font(.system(size: 11)).foregroundStyle(Theme.soft)
            }
            Spacer()
            if let r {
                (Text(ItalianFormat.integer(r.steps)).font(.system(size: 18, weight: .light)).foregroundColor(Theme.ink)
                 + Text("  · \(ItalianFormat.number(r.km, decimals: r.km >= 1000 ? 0 : 1)) km").font(.system(size: 12)).foregroundColor(Theme.accent))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { if !last { Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1) } }
    }
}

struct CalendarLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            item(AnyView(Circle().fill(Theme.accent).frame(width: 8, height: 8)), "obiettivo")
            item(AnyView(Circle().strokeBorder(Theme.accent, lineWidth: 1.5).frame(width: 10, height: 10)), "Jolly")
            item(AnyView(Circle().strokeBorder(Theme.ink, lineWidth: 1.5).frame(width: 10, height: 10)), "oggi")
        }
        .font(.system(size: 10)).foregroundStyle(Theme.soft)
    }
    private func item(_ icon: AnyView, _ text: String) -> some View {
        HStack(spacing: 4) { icon; Text(text) }
    }
}

// MARK: - Streak

struct StreakPage: View {
    @Environment(StepsStore.self) private var store

    var body: some View {
        let s = store.history.streak
        let stats = store.history.stats
        VStack(spacing: 10) {
            streakCard(s)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionLabel(monthTitle(stats))
                    Spacer()
                    CalendarLegend()
                }
                CalendarGrid(monthStart: stats.interval(.month).start, mark: { store.history.mark(for: $0) }, today: stats.today)
            }
            .glassCard(padding: EdgeInsets(top: 14, leading: 20, bottom: 12, trailing: 20))
            VStack(spacing: 0) {
                row("Streak più lunga") {
                    Text("\(s.longest)").font(.system(size: 18, weight: .light)).foregroundStyle(Theme.accent)
                    + Text(" giorni").font(.system(size: 12)).foregroundColor(Theme.soft)
                }
                Rectangle().fill(Theme.ink.opacity(0.08)).frame(height: 1)
                row("Jolly") {
                    Text("maturati ").foregroundColor(Theme.ink.opacity(0.62))
                    + Text("\(s.jollyEarned)").fontWeight(.semibold).foregroundColor(Theme.ink)
                    + Text(" · usati ").foregroundColor(Theme.ink.opacity(0.62))
                    + Text("\(s.jollyUsed)").fontWeight(.semibold).foregroundColor(Theme.ink)
                    + Text(" · disponibili ").foregroundColor(Theme.ink.opacity(0.62))
                    + Text("\(s.jolly)").fontWeight(.semibold).foregroundColor(Theme.accent)
                }
            }
            .glassCard(padding: EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
        }
    }

    private func monthTitle(_ stats: HistoryStats) -> String { stats.title(.month) }

    private func row(_ title: String, @ViewBuilder value: () -> Text) -> some View {
        HStack {
            Text(title).font(.system(size: 14)).foregroundStyle(Theme.ink)
            Spacer()
            value().font(.system(size: 13)).monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    private func streakCard(_ s: StreakState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Streak attuale")
                Spacer()
                if s.streak > 0 && s.streak == s.longest {
                    Text("Record personale").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.accent)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accentSoft))
                }
            }
            HStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 10) {
                    Image(systemName: "flame.fill").font(.system(size: 30)).foregroundStyle(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.45), radius: 8).padding(.bottom, 12)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(s.streak)").font(.system(size: 84, weight: .ultraLight)).tracking(-5).monospacedDigit()
                            .foregroundStyle(Theme.ink).lineLimit(1)
                        Text("giorni di fila a obiettivo").font(.system(size: 13)).foregroundStyle(Theme.soft)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 7) {
                    SectionLabel("Jolly")
                    HStack(spacing: 5) {
                        ForEach(0..<min(max(s.jolly, 0), 5), id: \.self) { _ in
                            GemShape().stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, lineJoin: .round)).frame(width: 22, height: 22)
                        }
                        if s.jolly > 5 { Text("+\(s.jolly - 5)").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.accent) }
                    }
                    Text("\(s.jolly) disponibili").font(.system(size: 12)).foregroundStyle(Theme.soft)
                }
            }
            VStack(spacing: 6) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.ink.opacity(0.10))
                        Capsule().fill(Theme.accent).frame(width: g.size.width * CGFloat(s.counter) / CGFloat(StreakEngine.jollyEvery))
                            .shadow(color: Theme.accent.opacity(0.5), radius: 5)
                    }
                }
                .frame(height: 5)
                HStack {
                    Text("Prossimo Jolly tra \(s.daysToNextJolly) \(s.daysToNextJolly == 1 ? "giorno" : "giorni")")
                    Spacer()
                    Text("\(s.counter) / \(StreakEngine.jollyEvery)").monospacedDigit()
                }
                .font(.system(size: 12)).foregroundStyle(Theme.soft)
            }
            statusLine(s)
        }
        .glassCard(padding: EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
    }

    private func statusLine(_ s: StreakState) -> some View {
        let missing = store.plan.remaining
        return Group {
            if s.todayReached {
                Text("Oggi **obiettivo raggiunto**: la streak è \(s.streak).")
            } else if s.todayWouldUseJolly {
                Text("Oggi **in corso** · mancano \(ItalianFormat.integer(missing)) passi. A mezzanotte, senza obiettivo, usi un Jolly (ne restano \(s.jolly - 1)).")
            } else if s.todayWouldBreak {
                Text("Oggi **in corso** · mancano \(ItalianFormat.integer(missing)) passi. Senza Jolly, a mezzanotte la streak si interrompe.")
            } else {
                Text("Oggi **in corso** · mancano \(ItalianFormat.integer(missing)) passi per iniziare la streak.")
            }
        }
        .font(.system(size: 12)).foregroundStyle(Theme.ink.opacity(0.62))
    }
}
