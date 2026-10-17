import SwiftUI
import UIKit

// Stile «carta e matita»: numeri condensati con tratteggio, pennellata rossa, linea a matita.
// Condiviso tra app e widget (il font Anton è in Shared/Fonts, licenza OFL).

extension Font {
    /// Anton (condensato pesante) a corpo fisso: i numeri grandi non seguono il testo dinamico.
    static func anton(_ size: CGFloat) -> Font { .custom("Anton-Regular", fixedSize: size) }
}

enum SketchFont {
    static func uiFont(_ size: CGFloat) -> UIFont {
        UIFont(name: "Anton-Regular", size: size) ?? .systemFont(ofSize: size, weight: .black)
    }

    /// Corpo che fa entrare `text` in `width` partendo da `base` (mai più grande di `base`).
    static func fitted(_ text: String, base: CGFloat, width: CGFloat) -> CGFloat {
        let measured = (text as NSString).size(withAttributes: [.font: uiFont(base)]).width
        guard measured > 0 else { return base }
        return base * min(1, width / measured)
    }
}

/// Numero o titolo in Anton con tratteggio a matita dentro e un'ombra di ripasso spostata.
struct SketchText: View {
    let text: String
    let size: CGFloat
    var color: Color = Theme.ink
    var paper: Color = Theme.bg

    init(_ text: String, size: CGFloat, color: Color = Theme.ink, paper: Color = Theme.bg) {
        self.text = text; self.size = size; self.color = color; self.paper = paper
    }

    var body: some View {
        let t = Text(text).font(.anton(size)).lineLimit(1)
        t.foregroundStyle(color)
            .background(t.foregroundStyle(color.opacity(0.22)).offset(x: size * 0.025, y: size * 0.018))
            .overlay {
                Hatch(spacing: max(2.2, size / 22))
                    .stroke(paper.opacity(0.55), lineWidth: max(0.6, size / 70))
                    .mask(t)
            }
    }
}

/// Righe oblique parallele (60°) che riempiono il riquadro.
struct Hatch: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let run = rect.height * 0.58
        var x = rect.minX - run
        while x < rect.maxX {
            p.move(to: CGPoint(x: x, y: rect.maxY))
            p.addLine(to: CGPoint(x: x + run, y: rect.minY))
            x += spacing
        }
        return p
    }
}

/// Curva morbida (Catmull-Rom) per punti normalizzati 0…1 nel riquadro.
enum SmoothCurve {
    static func path(_ points: [CGPoint], in rect: CGRect) -> Path {
        let pts = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(pts.count - 1, i + 2)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            p.addCurve(to: p2, control1: c1, control2: c2)
        }
        return p
    }

    /// Punti lungo la curva (per il cursore sulla strada): `steps` per tratto.
    static func samples(_ points: [CGPoint], in rect: CGRect, steps: Int = 24) -> [CGPoint] {
        let pts = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        guard pts.count > 1 else { return pts }
        var out: [CGPoint] = []
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(pts.count - 1, i + 2)]
            for k in 0..<steps {
                let t = CGFloat(k) / CGFloat(steps), t2 = t * t, t3 = t2 * t
                func f(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
                    0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
                }
                out.append(CGPoint(x: f(p0.x, p1.x, p2.x, p3.x), y: f(p0.y, p1.y, p2.y, p3.y)))
            }
        }
        out.append(pts[pts.count - 1])
        return out
    }
}

/// Pennellata rossa: tratto pieno, setole più chiare e qualche pelo fuori linea.
struct BrushStroke<S: Shape>: View {
    let shape: S
    var width: CGFloat = 12
    var color: Color = Theme.accent
    var paper: Color = Theme.bg

    var body: some View {
        ZStack {
            shape.stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: width * 0.22, lineCap: .round))
                .offset(x: -width * 0.55, y: width * 0.5)
            shape.stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            shape.stroke(color.opacity(0.9), style: StrokeStyle(lineWidth: width * 0.5, lineCap: .round,
                                                                dash: [width * 3, width * 0.7, width * 6, width * 0.5]))
                .offset(x: width * 0.32, y: -width * 0.32)
            // setole: righe chiare sottili lungo il tratto
            shape.stroke(paper.opacity(0.42), style: StrokeStyle(lineWidth: max(0.6, width * 0.08), lineCap: .butt,
                                                                 dash: [width * 5, width * 1.6, width * 2, width * 2.4]))
                .offset(x: -width * 0.16, y: width * 0.14)
            shape.stroke(paper.opacity(0.30), style: StrokeStyle(lineWidth: max(0.5, width * 0.06), lineCap: .butt,
                                                                 dash: [width * 2.5, width * 3, width * 7, width]))
                .offset(x: width * 0.2, y: -width * 0.05)
        }
    }
}

/// Linea a matita: tratto principale spezzato e un ripasso più leggero spostato.
struct PencilStroke<S: Shape>: View {
    let shape: S
    var width: CGFloat = 1.6
    var color: Color = Theme.ink

    var body: some View {
        ZStack {
            shape.stroke(color.opacity(0.78), style: StrokeStyle(lineWidth: width, lineCap: .round,
                                                                 dash: [width * 14, width * 1.6, width * 5, width * 1.2]))
            shape.stroke(color.opacity(0.32), style: StrokeStyle(lineWidth: width * 0.55, lineCap: .round,
                                                                 dash: [width * 9, width * 2.5]))
                .offset(x: width * 1.1, y: -width * 0.8)
        }
    }
}

/// Anello aperto dei passi (come nel mockup): parte in basso a sinistra, gira in alto e scende a destra.
struct GaugeLoop: Shape {
    static let points: [CGPoint] = [
        CGPoint(x: 0.27, y: 0.98), CGPoint(x: 0.16, y: 0.80), CGPoint(x: 0.04, y: 0.56), CGPoint(x: 0.02, y: 0.33),
        CGPoint(x: 0.10, y: 0.11), CGPoint(x: 0.33, y: 0.01), CGPoint(x: 0.62, y: 0.04), CGPoint(x: 0.81, y: 0.16),
        CGPoint(x: 0.94, y: 0.36), CGPoint(x: 0.98, y: 0.58), CGPoint(x: 0.95, y: 0.78), CGPoint(x: 0.87, y: 0.94),
    ]

    func path(in rect: CGRect) -> Path { SmoothCurve.path(Self.points, in: rect) }
}

/// Avanzamento dei passi sull'anello: pennellata rossa fino a `progress`, matita per il resto,
/// pallino rosso in cima. Si anima cambiando `progress`.
struct BrushGauge: View {
    let progress: Double
    var width: CGFloat = 13
    var paper: Color = Theme.bg

    var body: some View {
        let p = min(1, max(0, progress))
        ZStack {
            PencilStroke(shape: GaugeLoop().trim(from: p, to: 1), width: max(1.2, width * 0.13))
            BrushStroke(shape: GaugeLoop().trim(from: 0, to: p), width: width, paper: paper)
            GaugeKnob(progress: p, size: width * 1.55)
        }
    }
}

/// Pallino rosso con contorno a matita, sul punto `progress` dell'anello.
private struct GaugeKnob: View, Animatable {
    var progress: Double
    let size: CGFloat
    var animatableData: Double { get { progress } set { progress = newValue } }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let point = GaugeLoop().path(in: rect).trimmedPath(from: 0, to: max(0.0001, progress)).currentPoint ?? .zero
            RoadDot(size: size).position(point)
        }
    }
}

/// Pallino rosso «inchiostrato» (anello dei passi e cursore della velocità).
struct RoadDot: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().fill(Theme.accent)
            Circle().fill(RadialGradient(colors: [.white.opacity(0.55), .clear], center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: size * 0.45))
            Circle().strokeBorder(Theme.ink.opacity(0.55), lineWidth: max(1, size * 0.06))
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.accent.opacity(0.55), radius: size * 0.35)
    }
}
