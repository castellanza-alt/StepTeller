import SwiftUI

/// Tre orb sfumati che derivano lentamente (28/34/40 s, avanti e indietro).
/// Con «Riduci movimento» restano fermi.
struct OrbsBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    orb(Theme.orb1, size: 0.70 * w, center: CGPoint(x: 0.13 * w, y: -0.14 * h + 0.35 * w),
                        progress: Self.progress(t, duration: 28, delay: 0), w: w, h: h)
                    orb(Theme.orb2, size: 0.78 * w, center: CGPoint(x: 0.91 * w, y: 0.30 * h + 0.39 * w),
                        progress: Self.progress(t, duration: 34, delay: 9), w: w, h: h)
                    orb(Theme.orb3, size: 0.60 * w, center: CGPoint(x: 0.20 * w, y: 1.22 * h - 0.30 * w),
                        progress: Self.progress(t, duration: 40, delay: 17), w: w, h: h)
                }
                .frame(width: w, height: h)
            }
        }
        .background(Theme.bg)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Onda triangolare addolcita (equivale a `ease-in-out infinite alternate`).
    private static func progress(_ t: Double, duration: Double, delay: Double) -> Double {
        let u = ((t + delay) / duration).truncatingRemainder(dividingBy: 2)
        let tri = u < 1 ? u : 2 - u
        return tri * tri * (3 - 2 * tri)
    }

    private func orb(_ color: Color, size: CGFloat, center: CGPoint, progress p: Double,
                     w: CGFloat, h: CGFloat) -> some View {
        Circle().fill(color)
            .frame(width: size, height: size)
            .padding(140)                       // spazio perché la sfumatura non venga tagliata
            .blur(radius: 70)
            .drawingGroup()                     // sfumatura calcolata una volta, poi solo spostata
            .scaleEffect(1 + 0.08 * p)
            .position(x: center.x + 0.06 * w * p, y: center.y - 0.04 * h * p)
    }
}
