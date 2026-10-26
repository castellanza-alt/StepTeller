import CoreMotion
import Observation
import SwiftUI

/// Phone tilt for the Home parallax: −1…1 on x and y relative to how the phone is held
/// (the reference slowly follows the position, so with the phone still everything returns to the center).
@MainActor
@Observable
final class ParallaxMotion {
    private(set) var tilt = CGSize.zero

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var base: CMAcceleration?

    /// Gravity change (≈ 9°) that takes the parallax to full travel.
    private static let range = 0.15
    /// How much the reference chases the position at every sample (60 Hz → ~1.5 s).
    private static let follow = 0.012
    /// Motion damping at every sample.
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

/// Shoe and leg above the background: they shift with the tilt (right side down → right,
/// top backwards → up), as if closer to the screen. Only this view redraws
/// at every sample.
struct ParallaxLeg: View {
    let image: String
    let motion: ParallaxMotion

    var body: some View {
        let px = Manga.artPixelSize
        let kx = Manga.artSize.width / px.width, ky = Manga.artSize.height / px.height
        let pad = Manga.legPadding
        Image(image)
            .resizable()
            .frame(width: (px.width + 2 * pad) * kx, height: (px.height + 2 * pad) * ky)
            .offset(x: -pad * kx + motion.tilt.width * Manga.parallaxMax,
                    y: -pad * ky - motion.tilt.height * Manga.parallaxMax)
            .frame(width: Manga.artSize.width, height: Manga.artSize.height, alignment: .topLeading)
            .accessibilityHidden(true)
    }
}
