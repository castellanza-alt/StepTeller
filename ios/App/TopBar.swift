import SwiftUI
import StepTellerCore

/// Fixed top bar (never scrolls): red navigation button on the left, streak and Jollies in the middle
/// (Home only), glass settings button on the right.
/// Drawn on the 390 canvas; `rowTop` is the y of the button row (below the real status bar).
struct TopBar: View {
    let screen: AppScreen
    let streak: Int
    let jolly: Int
    let rowTop: CGFloat
    let onNav: () -> Void
    let onSettings: () -> Void
    @Environment(\.manga) private var c

    var body: some View {
        ZStack(alignment: .topLeading) {
            if screen == .history {
                // veil: full paper up to 62%, 85% at 80%, then transparent
                LinearGradient(stops: [.init(color: c.paper, location: 0),
                                       .init(color: c.paper, location: 0.62),
                                       .init(color: c.paper.opacity(0.85), location: 0.8),
                                       .init(color: c.paper.opacity(0), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: rowTop + Manga.topBarHeight - Manga.statusBarHeight)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            HStack(spacing: Manga.barGap) {
                RedNavButton(label: L10n.text(screen == .home ? "top.storico.vo" : "top.home.vo"), action: onNav) {
                    ZStack {
                        if screen == .home { HistogramIcon().transition(.opacity) }
                        else { FootprintsIcon().transition(.opacity) }
                    }
                }
                if screen == .home {
                    streakGroup.transition(.opacity)
                }
                Spacer(minLength: 0)
                GlassButton(action: onSettings)
            }
            .padding(.horizontal, Manga.barPadding)
            .frame(height: Manga.buttonSize)
            .offset(y: rowTop)
        }
        .frame(width: Manga.frameWidth, alignment: .topLeading)
    }

    /// Streak and Jollies: rotated −3°, skewed −8°.
    private var streakGroup: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                FlameIcon(kind: .streak).frame(width: 16, height: 20)
                AntonText("\(streak)", 20)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.format("top.streak.vo", streak))
            HStack(spacing: 5) {
                FlameIcon(kind: .jolly).frame(width: 16, height: 20)
                AntonText("\(jolly)", 20)
                AntonText(L10n.text("top.jolly"), 12, tracking: 0.06)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.format("top.jolly.vo", "\(jolly)"))
        }
        .contentTransition(.numericText())
        .manga(rotate: -3, skew: -8)
    }
}

/// White mini histogram (3 parallelogram bars + baseline), 28 × 28.
struct HistogramIcon: View {
    var body: some View {
        ZStack {
            ForEach(MangaPaths.histogramBars, id: \.self) { d in
                SVGShape(d, viewBox: CGSize(width: 28, height: 28)).fill(MangaPalette.onRed)
            }
            SVGShape("M3 24.6 L25 24.6", viewBox: CGSize(width: 28, height: 28))
                .stroke(MangaPalette.onRed, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
        .frame(width: 28, height: 28)
    }
}

/// Two white footprints on a diagonal, 30 × 30.
struct FootprintsIcon: View {
    var body: some View {
        SVGShape(path: MangaPaths.footprints, viewBox: CGSize(width: 30, height: 30))
            .fill(MangaPalette.onRed)
            .frame(width: 30, height: 30)
    }
}
