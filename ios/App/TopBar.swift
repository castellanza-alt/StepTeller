import SwiftUI
import StepTellerCore

enum AppScreen { case home, storico }

/// Barra superiore fissa (non scorre mai): bottone rosso di navigazione a sinistra, al centro serie e
/// Jolly (Home) o «STORICO» (Storico, quando si è scorso), impostazioni in vetro a destra.
/// Disegnata sulla tela 390; `rowTop` è la y della riga dei bottoni (sotto la status bar reale).
struct TopBar: View {
    let screen: AppScreen
    let streak: Int
    let jolly: Int
    let storicoScrolled: Bool
    let rowTop: CGFloat
    let onNav: () -> Void
    let onSettings: () -> Void
    @Environment(\.manga) private var c

    var body: some View {
        ZStack(alignment: .topLeading) {
            if screen == .storico {
                // velo: paper pieno fino al 62%, 85% all'80%, poi trasparente
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
                RedNavButton(label: screen == .home ? "Storico" : "Torna a oggi", action: onNav) {
                    ZStack {
                        if screen == .home { HistogramIcon().transition(.opacity) }
                        else { FootprintsIcon().transition(.opacity) }
                    }
                }
                ZStack(alignment: .leading) {
                    if screen == .home {
                        streakGroup.transition(.opacity)
                    } else {
                        AntonText("STORICO", 20, tracking: 0.06)
                            .manga(rotate: -3, skew: -10)
                            .opacity(storicoScrolled ? 1 : 0)
                            .animation(.easeInOut(duration: Manga.titleFade), value: storicoScrolled)
                            .accessibilityHidden(!storicoScrolled)
                    }
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

    /// Serie e Jolly: ruotati −3°, inclinati −8°.
    private var streakGroup: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                FlameIcon(kind: .streak).frame(width: 16, height: 20)
                AntonText("\(streak)", 20)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Serie: \(streak) \(streak == 1 ? "giorno" : "giorni")")
            HStack(spacing: 5) {
                FlameIcon(kind: .jolly).frame(width: 16, height: 20)
                AntonText("\(jolly)", 20)
                AntonText("JOLLY", 12, tracking: 0.06)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Jolly disponibili: \(jolly)")
        }
        .contentTransition(.numericText())
        .manga(rotate: -3, skew: -8)
    }
}

/// Mini-istogramma bianco (3 barre parallelogramma + linea di base), 28 × 28.
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

/// Due impronte bianche in diagonale, 30 × 30.
struct FootprintsIcon: View {
    var body: some View {
        SVGShape(path: MangaPaths.footprints, viewBox: CGSize(width: 30, height: 30))
            .fill(MangaPalette.onRed)
            .frame(width: 30, height: 30)
    }
}
