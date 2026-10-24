import SwiftUI
import StepTellerCore

/// The only screen of the watch app, «Dan Dan Dan» style in the night palette (the watch screen is dark):
/// streak and Jollies, today's steps with the red shadow, goal, progress bar, minutes and distance left at the
/// speed chosen in the iPhone Home. Drawn for the 41 mm case (176 pt wide) and scaled to the real width.
struct WatchHomeView: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    static let referenceWidth: CGFloat = 176
    private let c = MangaPalette.night

    var body: some View {
        GeometryReader { geo in
            content(data: store.snapshot, k: geo.size.width / Self.referenceWidth, width: geo.size.width)
        }
        .background(c.paper.ignoresSafeArea())
        .environment(\.manga, c)
        .task { await store.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.becameActive() } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func content(data: WidgetSnapshot, k: CGFloat, width: CGFloat) -> some View {
        let inset = 10 * k
        let line = bottomLine(data)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10 * k) {
                counter(.streak, data.streak, k)
                counter(.jolly, data.jolly, k)
            }
            .manga(rotate: -3, skew: -8, anchor: .leading)
            Spacer(minLength: 4 * k)
            stepsBlock(data, k)
                .manga(rotate: -6, skew: -10, anchor: .bottomLeading)
            Spacer(minLength: 8 * k)
            WidgetProgressBar(progress: data.plan?.progress ?? 0, width: width - 2 * inset - 6 * k, height: 8 * k)
                .manga(skew: -20)
            AntonText(line.text, 12 * k, tracking: 0.04, color: line.color, minScale: 0.7)
                .frame(width: width - 2 * inset, alignment: .leading)
                .padding(.top, 6 * k)
        }
        .padding(.horizontal, inset)
        .padding(.bottom, 4 * k)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func counter(_ kind: FlameIcon.Kind, _ value: Int, _ k: CGFloat) -> some View {
        HStack(spacing: 3 * k) {
            FlameIcon(kind: kind).frame(width: 12 * k, height: 15 * k)
            AntonText("\(value)", 15 * k)
        }
    }

    private func stepsBlock(_ data: WidgetSnapshot, _ k: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let text = WidgetText.steps(data.plan)
            ZStack(alignment: .topLeading) {
                AntonText(text, 54 * k, lineHeight: 0.92, tracking: -0.035, color: c.red, minScale: 0.6).offset(x: 3 * k, y: 3 * k)
                AntonText(text, 54 * k, lineHeight: 0.92, tracking: -0.035, minScale: 0.6)
            }
            AntonText(data.plan.map { L10n.format("w.of", table: L10n.widget, LocalFormat.integer($0.goal)) }
                      ?? L10n.text("w.lock.steps", table: L10n.widget), 12 * k, tracking: 0.06)
                .padding(.top, 2 * k)
        }
    }

    /// Under the bar: minutes and distance left, «goal reached» in red, or the Health notice.
    private func bottomLine(_ d: WidgetSnapshot) -> (text: String, color: Color) {
        guard let p = d.plan else { return (L10n.text("w.watch.nodata", table: L10n.widget), c.ink) }
        if p.isDone { return (L10n.text("w.lock.goalDone", table: L10n.widget), c.red) }
        return (L10n.format(d.unit.pick("w.lock.left", "w.lock.left.mi"), table: L10n.widget, "\(p.minutes)",
                            d.unit.distanceText(km: p.km)), c.ink)
    }

    private var accessibilityText: String {
        let data = store.snapshot
        return data.plan == nil ? L10n.text("w.watch.nodata.vo", table: L10n.widget) : WidgetText.summary(data)
    }
}
