import SwiftUI
import StepTellerCore

/// Una barra dell'istogramma dello Storico.
struct MangaBar: Identifiable, Equatable {
    enum Style { case hit, miss, current, future }
    let id: Int
    let label: String
    let showLabel: Bool
    let value: Double
    let display: String
    let style: Style
}

/// Istogramma a parallelogrammi (handoff, punto 9): rosso pieno = obiettivo raggiunto, tratteggio
/// `ink` = mancato, tratteggio rosso = oggi / periodo in corso. Linea tratteggiata all'obiettivo.
/// Tocco su una barra: mostra/nasconde il valore.
struct MangaBarChart: View {
    let bars: [MangaBar]
    /// Obiettivo (nella stessa unità delle barre); nil = niente linea.
    let goal: Double?
    let goalLabel: String
    @Binding var selected: Int?
    /// 0 → 1: crescita dal basso al cambio di tab.
    let grow: CGFloat
    @Environment(\.manga) private var c

    var body: some View {
        let n = max(bars.count, 1)
        let gap: CGFloat = n > 20 ? 2 : n > 8 ? 4 : 8
        let labelSize: CGFloat = n > 20 ? 11 : n > 8 ? 13 : 18
        let maxValue = max(bars.map(\.value).max() ?? 0, goal ?? 0, 1) * 1.1
        VStack(spacing: 8) {
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: gap) {
                        ForEach(bars) { b in
                            bar(b, height: h * CGFloat(b.value / maxValue) * grow)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .contentShape(Rectangle())
                                .onTapGesture { selected = selected == b.id ? nil : b.id }
                                .zIndex(selected == b.id ? 1 : 0)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(L10n.format("st.chart.bar.vo", b.label, b.display))
                        }
                    }
                    if let goal, goal > 0 {
                        let y = h * (1 - CGFloat(goal / maxValue))
                        Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y)) }
                            .stroke(c.ink, style: StrokeStyle(lineWidth: 2.5, dash: [7.5, 7.5]))
                            .allowsHitTesting(false)
                        AntonText(goalLabel, 13, tracking: 0.04)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(c.paper)
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .offset(y: -(h - y) - 5)
                            .allowsHitTesting(false)
                            .accessibilityLabel(L10n.format("st.chart.goal.vo", goalLabel))
                    }
                    tooltips(heights: bars.map { h * CGFloat($0.value / maxValue) * grow }, gap: gap)
                }
            }
            .overlay(alignment: .bottom) { Rectangle().fill(c.ink).frame(height: 3).offset(y: 3) }
            .padding(.bottom, 3)
            HStack(spacing: gap) {
                ForEach(bars) { b in
                    AntonText(b.showLabel ? b.label : " ", labelSize,
                              color: b.style == .current ? c.red : c.ink.opacity(b.style == .future ? 0.35 : 1))
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
        }
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    @ViewBuilder private func bar(_ b: MangaBar, height: CGFloat) -> some View {
        ZStack {
            if b.style != .future && height > 0.5 {
                PercentPolygon.bar.fill(c.ink)
                fill(b.style)
                    .clipShape(PercentPolygon.bar)
                    .padding(EdgeInsets(top: 2.5, leading: 3, bottom: 2.5, trailing: 3))
            }
        }
        .frame(height: max(0, height))
    }

    /// Valore della barra toccata: tag rosso 6 pt sopra la barra, sopra anche alla linea dell'obiettivo.
    private func tooltips(heights: [CGFloat], gap: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: gap) {
            ForEach(Array(bars.enumerated()), id: \.element.id) { i, b in
                Color.clear
                    .frame(height: heights[i])
                    .overlay(alignment: .top) {
                        if selected == b.id {
                            TagText(text: b.display, size: 13, foreground: c.paper, background: c.red,
                                    padding: EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
                                .fixedSize()
                                .offset(y: -(13 + 6 + 6))
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .zIndex(selected == b.id ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder private func fill(_ style: MangaBar.Style) -> some View {
        switch style {
        case .hit: c.red
        case .current: Hatch(color: c.red, period: 6)
        case .miss, .future: Hatch(color: c.ink, period: 5)
        }
    }
}
