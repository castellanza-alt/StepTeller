import CoreMotion
import Observation
import SwiftUI

/// Inclinazione del telefono per la parallasse della Home: −1…1 su x e y rispetto a come lo si tiene
/// (il riferimento segue lentamente la posizione, così a telefono fermo tutto torna al centro).
@MainActor
@Observable
final class ParallaxMotion {
    private(set) var tilt = CGSize.zero

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var base: CMAcceleration?

    /// Variazione di gravità (≈ 9°) che porta la parallasse a fondo corsa.
    private static let range = 0.15
    /// Quanto il riferimento insegue la posizione a ogni campione (60 Hz → ~1,5 s).
    private static let follow = 0.012
    /// Smorzamento del movimento a ogni campione.
    private static let smoothing = 0.18

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let g = motion?.gravity else { return }
            MainActor.assumeIsolated { self.apply(g) }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        base = nil
        tilt = .zero
    }

    private func apply(_ g: CMAcceleration) {
        var b = base ?? g
        b.x += (g.x - b.x) * Self.follow
        b.y += (g.y - b.y) * Self.follow
        base = b
        let x = max(-1, min(1, (g.x - b.x) / Self.range))
        let y = max(-1, min(1, (g.y - b.y) / Self.range))
        tilt = CGSize(width: tilt.width + (x - tilt.width) * Self.smoothing,
                      height: tilt.height + (y - tilt.height) * Self.smoothing)
    }
}

/// Scarpa e gamba sopra lo sfondo: si spostano con l'inclinazione (lato destro giù → a destra,
/// cima indietro → in su), come se stessero più vicine allo schermo. Solo questa vista si ridisegna
/// a ogni campione.
struct ParallaxLeg: View {
    let image: String
    let motion: ParallaxMotion

    var body: some View {
        let kx = Manga.artSize.width / 881, ky = Manga.artSize.height / 1786
        let pad = Manga.legPadding
        Image(image)
            .resizable()
            .frame(width: (881 + 2 * pad) * kx, height: (1786 + 2 * pad) * ky)
            .offset(x: -pad * kx + motion.tilt.width * Manga.parallaxMax,
                    y: -pad * ky - motion.tilt.height * Manga.parallaxMax)
            .frame(width: Manga.artSize.width, height: Manga.artSize.height, alignment: .topLeading)
            .accessibilityHidden(true)
    }
}
