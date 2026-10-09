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
        VStack(alignment: .leading, spacing: 0) {
            periodPicker.padding(.top, 18)
            chart(stats).padding(.top, 26)
            figures(summary).padding(.top, 34)
            if period == .month { calendar(stats).padding(.top, 38) }
            records(stats.personalRecords()).padding(.top, 38)
        }
    }

    /// Periodi come testo: l'attivo in inchiostro con un trattino accent sotto; nessun fondo.
    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach([(HistoryPeriod.week, "Settimana"), (.month, "Mese"), (.year, "Anno"), (.all, "Sempre")], id: \.1) { p, title in
                Button { withAnimation(.easeInOut(duration: 0.2)) { period = p; offset = 0 } } label: {
                    VStack(spacing: 7) {
                        Text(title).font(.system(size: 14, weight: period == p ? .semibold : .regular))
                            .foregroundStyle(period == p ? Theme.ink : Theme.soft)
                        Capsule().fill(period == p ? Theme.accent : .clear).frame(width: 16, height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(period == p ? .isSelected : [])
            }
        }
    }

    private func chart(_ stats: HistoryStats) -> some View {
        let maxOff = stats.maxOffset(period)
        return VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if period != .all {
                    Button { if offset < maxOff { offset += 1 } } label: {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .medium))
                            .frame(width: 26, height: 26).contentShape(Rectangle())
                    }
                    .disabled(offset >= maxOff).opacity(offset >= maxOff ? 0.25 : 0.7)
                    .padding(.leading, -8)
                    .accessibilityLabel("Periodo precedente")
                }
                Text(stats.title(period, offset: offset)).font(.system(size: 15, weight: .medium))
                if period != .all {
                    Button { if offset > 0 { offset -= 1 } } label: {
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium))
                            .frame(width: 26, height: 26).contentShape(Rectangle())
                    }
                    .disabled(offset == 0).opacity(offset == 0 ? 0.25 : 0.7)
                    .accessibilityLabel("Periodo successivo")
                }
                Spacer()
                metricButton("Passi", .steps)
                Text("·").font(.system(size: 12)).foregroundStyle(Theme.faint)
                metricButton("Km", .km)
            }
            .foregroundStyle(Theme.ink)
            BarChartView(bars: stats.bars(period, offset: offset), metric: metric, period: period)
        }
        .animation(.easeInOut(duration: 0.2), value: period)
    }

    private func metricButton(_ title: String, _ value: HistoryMetric) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { metric = value } } label: {
            Text(title).font(.system(size: 13, weight: metric == value ? .semibold : .regular))
                .foregroundStyle(metric == value ? Theme.accent : Theme.soft)
                .padding(.horizontal, 4).padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(metric == value ? .isSelected : [])
    }

    /// Totale in evidenza, poi tre cifre affiancate separate da sottili linee verticali.
    private func figures(_ s: PeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Totale")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(ItalianFormat.integer(s.steps))
                        .font(.system(size: 52, weight: .ultraLight)).tracking(-2.4).monospacedDigit()
                        .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
                    Text("passi").font(.system(size: 15)).foregroundStyle(Theme.soft)
                }
            }
            Hairline()
            HStack(alignment: .top, spacing: 0) {
                figure("Distanza", ItalianFormat.number(s.km, decimals: s.km >= 1000 ? 0 : 1), "km", first: true)
                VLine()
                figure("Media", ItalianFormat.integer(s.averageSteps), "al giorno")
                VLine()
                figure("A obiettivo", ItalianFormat.integer(s.daysAtGoal), "su \(ItalianFormat.integer(s.elapsedDays)) giorni")
            }
        }
    }

    private func figure(_ title: String, _ value: String, _ unit: String, first: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.8).foregroundStyle(Theme.soft)
                .lineLimit(1).minimumScaleFactor(0.8)
            Text(value).font(.system(size: 24, weight: .light)).tracking(-0.6).monospacedDigit()
                .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(unit).font(.system(size: 11)).foregroundStyle(Theme.soft).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, first ? 0 : 14).padding(.trailing, 8)
        .accessibilityElement(children: .combine)
    }

    private func calendar(_ stats: HistoryStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Calendario")
                Spacer()
                CalendarLegend()
            }
            CalendarGrid(monthStart: stats.interval(.month, offset: offset).start,
                         mark: { store.history.mark(for: $0) }, today: stats.today)
        }
    }

    private func records(_ r: PersonalRecords) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Record personali").padding(.bottom, 6)
            recordRow("Giorno", r.day)
            recordRow("Settimana", r.week)
            recordRow("Mese", r.month)
            recordRow("Anno", r.year)
        }
    }

    private func recordRow(_ title: String, _ r: RecordEntry?) -> some View {
        VStack(spacing: 0) {
            Hairline()
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15)).foregroundStyle(Theme.ink)
                    Text(r?.label ?? "—").font(.system(size: 12)).foregroundStyle(Theme.soft)
                }
                Spacer()
                if let r {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ItalianFormat.integer(r.steps)).font(.system(size: 22, weight: .light)).tracking(-0.5)
                            .monospacedDigit().foregroundStyle(Theme.ink)
                        Text("\(ItalianFormat.number(r.km, decimals: r.km >= 1000 ? 0 : 1)) km")
                            .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.soft)
                    }
                }
            }
            .padding(.vertical, 14)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Linea orizzontale sottile: separa senza chiudere in un riquadro.
struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.hair).frame(height: 1) }
}

/// Linea verticale sottile tra cifre affiancate.
private struct VLine: View {
    var body: some View { Rectangle().fill(Theme.hair).frame(width: 1, height: 52) }
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
        VStack(alignment: .leading, spacing: 0) {
            streakHero(s).padding(.top, 24)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabel(monthTitle(stats))
                    Spacer()
                    CalendarLegend()
                }
                CalendarGrid(monthStart: stats.interval(.month).start, mark: { store.history.mark(for: $0) }, today: stats.today)
            }
            .padding(.top, 40)
            VStack(spacing: 0) {
                Hairline()
                row("Streak più lunga") {
                    Text("\(s.longest)").font(.system(size: 20, weight: .light)).foregroundStyle(Theme.ink)
                    + Text(" giorni").font(.system(size: 12)).foregroundColor(Theme.soft)
                }
                Hairline()
                row("Jolly") {
                    Text("maturati ").foregroundColor(Theme.soft)
                    + Text("\(s.jollyEarned)").foregroundColor(Theme.ink)
                    + Text(" · usati ").foregroundColor(Theme.soft)
                    + Text("\(s.jollyUsed)").foregroundColor(Theme.ink)
                    + Text(" · disponibili ").foregroundColor(Theme.soft)
                    + Text("\(s.jolly)").fontWeight(.semibold).foregroundColor(Theme.accent)
                }
                Hairline()
            }
            .padding(.top, 34)
        }
    }

    private func monthTitle(_ stats: HistoryStats) -> String { stats.title(.month) }

    private func row(_ title: String, @ViewBuilder value: () -> Text) -> some View {
        HStack {
            Text(title).font(.system(size: 15)).foregroundStyle(Theme.ink)
            Spacer()
            value().font(.system(size: 13)).monospacedDigit()
        }
        .padding(.vertical, 14)
    }

    private func streakHero(_ s: StreakState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("Streak attuale")
                Spacer()
                if s.streak > 0 && s.streak == s.longest {
                    Text("RECORD PERSONALE").font(.system(size: 10, weight: .semibold)).tracking(1.8)
                        .foregroundStyle(Theme.accent)
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
