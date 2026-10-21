import SwiftUI
import WidgetKit
import StepTellerCore

/// Data shown by the widget: today's plan (nil = Health unavailable), streak and Jollies from the app,
/// unit chosen in the app (km or miles).
struct WidgetSnapshot {
    let plan: Plan?
    let streak: Int
    let jolly: Int
    let unit: DistanceUnit
}

/// Widget theme: follows the system appearance (light = day, dark = night).
struct WidgetThemed<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().environment(\.manga, scheme == .dark ? .night : .day)
    }
}

/// `paper` background of the current theme.
struct WidgetPaper: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View { (scheme == .dark ? MangaPalette.night : MangaPalette.day).paper }
}

// MARK: - Small (170 × 170)

/// Small widget: fading sole bottom right, streak on top, slanted steps, progress bar.
/// Drawn in the handoff's 170 × 170 space and scaled to the real size.
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

    /// 160 × 160 art bleeding 34 pt bottom right, with a radial mask (78 %, 78 %).
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
            AntonText(data.plan.map { L10n.format("w.of", table: L10n.widget, LocalFormat.integer($0.goal)) }
                      ?? L10n.text("w.openApp", table: L10n.widget), 12, tracking: 0.06)
                .shadow(color: c.paper, radius: 3)
                .padding(.top, 3)
        }
    }
}

// MARK: - Medium (364 × 170)

/// Medium widget: fading board on the left, streak and Jollies top right, steps with a red shadow,
/// minutes and distance left at the speed chosen in Home, progress bar.
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
            AntonText(L10n.text("w.stepsToday", table: L10n.widget), 13, tracking: 0.04)
                .padding(.bottom, TitleFont.gap(13))
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
                    AntonText(L10n.text("w.goal", table: L10n.widget), 13)
                    AntonText(L10n.text("w.done", table: L10n.widget), 24, color: c.red)
                } else {
                    AntonText(L10n.text("w.left", table: L10n.widget), 13)
                    AntonText(LocalFormat.integer(p.minutes), 24, color: c.red)
                    AntonText(L10n.format(data.unit.pick("w.minKm", "w.minMi"), table: L10n.widget,
                                          data.unit.distanceText(km: p.km)), 13)
                }
            } else {
                AntonText(L10n.text("w.openApp", table: L10n.widget), 13)
            }
        }
    }
}

// MARK: - Lock screen (monochrome)

/// Lock screen, circular: ring (30 % track, 6 thick) with the steps in Anton at the center.
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
                AntonText(L10n.text("w.lock.steps", table: L10n.widget), 9, tracking: 0.08, color: .white)
            }
            .manga(skew: -10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plan.map { L10n.format("w.vo.steps", table: L10n.widget, LocalFormat.integer($0.steps), LocalFormat.integer($0.goal)) }
                            ?? L10n.text("w.vo.none.short", table: L10n.widget))
    }
}

/// Lock screen, rectangular: streak, big slanted steps, minutes and distance left.
struct LockRectangular: View {
    let data: WidgetSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                SVGShape(MangaPaths.flame, viewBox: MangaPaths.flameBox).fill(Color.white).frame(width: 10, height: 12)
                AntonText(L10n.format("w.lock.streak", table: L10n.widget, data.streak), 12, tracking: 0.06, color: .white)
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
        guard let p = data.plan else { return L10n.text("w.openApp", table: L10n.widget) }
        if p.isDone { return L10n.text("w.lock.goalDone", table: L10n.widget) }
        return L10n.format(data.unit.pick("w.lock.left", "w.lock.left.mi"), table: L10n.widget, "\(p.minutes)",
                           data.unit.distanceText(km: p.km))
    }
}

// MARK: - Shared pieces

/// Progress bar: `paper` background, 1.5 `ink` border, `red` fill with the same border.
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
    static func steps(_ plan: Plan?) -> String { plan.map { LocalFormat.integer($0.steps) } ?? "—" }

    /// Compact steps for the lock-screen circle: from 10.000 up «10,4K» (suffix from the catalog).
    static func compactSteps(_ plan: Plan?) -> String {
        guard let s = plan?.steps else { return "—" }
        return s >= 10_000 ? LocalFormat.number(Double(s) / 1000, decimals: 1) + L10n.text("w.thousands", table: L10n.widget)
                           : LocalFormat.integer(s)
    }

    /// Whole VoiceOver sentence (one string per language, with parameters).
    static func summary(_ d: WidgetSnapshot) -> String {
        guard let p = d.plan else { return L10n.text("w.vo.none", table: L10n.widget) }
        let steps = LocalFormat.integer(p.steps), goal = LocalFormat.integer(p.goal)
        if p.isDone {
            return L10n.format("w.vo.summary.done", table: L10n.widget, steps, goal, "\(d.streak)", "\(d.jolly)")
        }
        return L10n.format(d.unit.pick("w.vo.summary.left", "w.vo.summary.left.mi"), table: L10n.widget, steps, goal,
                           "\(p.minutes)", d.unit.distanceText(km: p.km), "\(d.streak)", "\(d.jolly)")
    }
}
