import SwiftUI

// MARK: - Buttons

/// Red primary button: 54 circle, radial gradient, red shadow, thin highlight on top, −6°.
struct RedNavButton<Icon: View>: View {
    let label: String
    let action: () -> Void
    @ViewBuilder var icon: () -> Icon
    @Environment(\.manga) private var c

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(RedGradient.fill(red: c.red, center: UnitPoint(x: 0.34, y: 0.28), size: Manga.buttonSize, mid: 0.52))
                    .shadow(color: MangaPalette.redButtonShadow, radius: 10, y: 8)
                // inset 0 1px 0 rgba(255,255,255,.5)
                Circle().subtracting(Circle().offset(y: 1)).fill(Color.white.opacity(0.5))
                icon()
            }
            .frame(width: Manga.buttonSize, height: Manga.buttonSize)
            .rotationEffect(.degrees(Manga.navButtonRotation))
            .contentShape(Circle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(label)
    }
}

/// Glass settings button: `paper` 72% + blur, inner `ink` border, shadow.
struct GlassButton: View {
    let action: () -> Void
    @Environment(\.manga) private var c

    var body: some View {
        Button(action: action) {
            SettingsGlyph()
                .frame(width: Manga.buttonSize, height: Manga.buttonSize)
                .background(Circle().fill(.ultraThinMaterial))
                .background(Circle().fill(c.paper.opacity(0.72)))
                .overlay(Circle().strokeBorder(c.ink, lineWidth: 1.5))
                .compositingGroup()
                .shadow(color: MangaPalette.glassShadow, radius: 11, y: 8)
                .contentShape(Circle())
        }
        .buttonStyle(PressScale())
        .accessibilityLabel(L10n.text("top.settings.vo"))
    }
}

struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

enum RedGradient {
    /// `radial-gradient(circle at cx cy, #FF6A5E 0, red mid, #B5140E 100%)` (radius to the farthest corner).
    static func fill(red: Color, center: UnitPoint, size: CGFloat, mid: CGFloat) -> RadialGradient {
        let fx = max(center.x, 1 - center.x), fy = max(center.y, 1 - center.y)
        return RadialGradient(stops: [.init(color: MangaPalette.redHighlight, location: 0),
                                      .init(color: red, location: mid),
                                      .init(color: MangaPalette.redDeep, location: 1)],
                              center: center, startRadius: 0, endRadius: size * (fx * fx + fy * fy).squareRoot())
    }
}

// MARK: - Kinetic lines

/// The prototype's pseudo-random generator (`r = (r·9301 + 49297) mod 233280`): same drawing.
struct ProtoRandom {
    var r: Int
    mutating func next() -> Int { r = (r * 9301 + 49297) % 233280; return r }
}

enum KineticLines {
    struct Ray { let points: [CGPoint]; let red: Bool }

    /// Triangular rays from the center (port of the prototype's `lines()`): tip inside, base outside.
    static func rays(cx: CGFloat, cy: CGFloat, count: Int, innerMin: Int, innerMax: Int, outer: CGFloat,
                     seed: Int, redEvery: Int? = nil) -> [Ray] {
        var g = ProtoRandom(r: seed)
        return (0..<count).map { i in
            let r = g.next()
            let a = Double(i) / Double(count) * .pi * 2 + Double(r) / 233280 * 0.08
            let w = 0.4 + Double(r % 9) / 9 * 2.8
            let r0 = Double(innerMin + r % (innerMax - innerMin))
            let x1 = cx + cos(a) * r0, y1 = cy + sin(a) * r0
            let x2 = cx + cos(a) * outer, y2 = cy + sin(a) * outer
            let nx = -sin(a) * w, ny = cos(a) * w
            return Ray(points: [CGPoint(x: x1, y: y1), CGPoint(x: x2 + nx, y: y2 + ny), CGPoint(x: x2 - nx, y: y2 - ny)],
                       red: redEvery.map { i % $0 == 0 } ?? false)
        }
    }

    /// Star burst (port of `star()`): `n` points, 1.5 : 1 ellipse.
    static func star(cx: CGFloat, cy: CGFloat, points n: Int, outer: CGFloat, inner: CGFloat, rotation: Double) -> Path {
        var g = ProtoRandom(r: 3)
        var p = Path()
        for i in 0..<(n * 2) {
            let r = g.next()
            let a = Double(i) / Double(n * 2) * .pi * 2 + rotation
            let rad = i % 2 == 1 ? inner : outer * (0.82 + CGFloat(r % 100) / 100 * 0.3)
            let pt = CGPoint(x: cx + cos(a) * rad * 1.5, y: cy + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Rays drawn in a Canvas.
struct RaysView: View {
    let rays: [KineticLines.Ray]
    @Environment(\.manga) private var c

    var body: some View {
        Canvas { ctx, _ in
            for ray in rays {
                var p = Path(); p.addLines(ray.points); p.closeSubpath()
                ctx.fill(p, with: .color(ray.red ? c.red : c.ink))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Hatching

/// `repeating-linear-gradient(-55deg, color 0 2px, paper 2px period)`.
struct Hatch: View {
    let color: Color
    let period: CGFloat
    var lineWidth: CGFloat = 2
    @Environment(\.manga) private var c

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(c.paper))
            // the gradient runs towards −55° (top left); the lines are perpendicular to it
            let a = -55.0 * .pi / 180
            let dir = CGVector(dx: sin(a), dy: -cos(a))           // gradient direction
            let along = CGVector(dx: -dir.dy, dy: dir.dx)          // line direction
            let diag = (size.width * size.width + size.height * size.height).squareRoot()
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var k = -diag
            while k < diag {
                let o = CGPoint(x: center.x + dir.dx * (k + lineWidth / 2), y: center.y + dir.dy * (k + lineWidth / 2))
                var p = Path()
                p.move(to: CGPoint(x: o.x - along.dx * diag, y: o.y - along.dy * diag))
                p.addLine(to: CGPoint(x: o.x + along.dx * diag, y: o.y + along.dy * diag))
                ctx.stroke(p, with: .color(color), lineWidth: lineWidth)
                k += period
            }
        }
    }
}
