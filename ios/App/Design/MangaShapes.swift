import SwiftUI

// MARK: - Tracciati SVG

/// Lettore minimo dei `d` SVG usati nel handoff (M, L, C, Q, Z assoluti).
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var tokens: [String] = []
        var current = ""
        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == "," || ch == " " {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if ch == "-" && !current.isEmpty && current.last != "e" {
                tokens.append(current); current = "-"
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }

        var p = Path()
        var i = 0
        var cmd = "M"
        func num() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        func pt() -> CGPoint { let x = num(); return CGPoint(x: x, y: num()) }
        while i < tokens.count {
            if let c = tokens[i].first, c.isLetter { cmd = tokens[i]; i += 1 }
            switch cmd {
            case "M": p.move(to: pt()); cmd = "L"
            case "L": p.addLine(to: pt())
            case "C": let a = pt(), b = pt(); p.addCurve(to: pt(), control1: a, control2: b)
            case "Q": let a = pt(); p.addQuadCurve(to: pt(), control: a)
            case "Z", "z": p.closeSubpath()
            default: i += 1
            }
        }
        return p
    }
}

/// Forma da un tracciato SVG con il suo viewBox, adattata come `preserveAspectRatio="xMidYMid meet"`.
struct SVGShape: Shape {
    let path: Path
    let viewBox: CGSize

    init(_ d: String, viewBox: CGSize) {
        path = SVGPath.parse(d)
        self.viewBox = viewBox
    }

    init(path: Path, viewBox: CGSize) {
        self.path = path
        self.viewBox = viewBox
    }

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let dx = rect.minX + (rect.width - viewBox.width * s) / 2
        let dy = rect.minY + (rect.height - viewBox.height * s) / 2
        return path.applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy))
    }
}

// MARK: - Forme ricorrenti

enum MangaPaths {
    static let flameBox = CGSize(width: 18, height: 22)
    /// Fiamma (serie / Jolly).
    static let flame = "M9 1 C11 6,17 9,16 15 C15 20,11 21,9 21 C5 21,2 18,2 14 C2 10,5 9,6 5 C8 8,8 10,9 11 C11 8,10 5,9 1Z"
    /// Cuore interno della fiamma.
    static let flameCore = "M9 10.5 C10.5 13,13 14.5,12.5 17 C12 19.5,10.4 20,9 20 C7 20,5.5 18.6,5.6 16.6 C5.7 15,7 14.3,7.3 12.6 C8.2 14,8.4 14.8,8.9 15.2 C9.6 13.8,9.5 12,9 10.5Z"
    /// Pennellata sotto i titoli (viewBox 300 × 18).
    static let brush = "M2 12 Q150 2 298 4 L298 8 Q150 8 2 15Z"
    static let brushBox = CGSize(width: 300, height: 18)

    /// Mini-istogramma del bottone della Home (viewBox 28 × 28): tre barre a parallelogramma.
    static let histogramBars = ["M5 22 L9.5 22 L11.5 13 L7 13 Z", "M12 22 L16.5 22 L19.5 7 L15 7 Z", "M19 22 L23.5 22 L25 16 L20.5 16 Z"]

    /// Impronta (pianta + tallone), centrata in 0,0 prima della rotazione.
    static let footSole = "M0 -10 C3.4 -10,4.4 -6,4 -2.6 C3.7 0.4,2.6 2,0 2 C-2.6 2,-3.7 0.4,-4 -2.6 C-4.4 -6,-3.4 -10,0 -10 Z"
    static let footHeel = "M-3 4.4 C-3 3.6,3 3.6,3 4.4 C3 6.6,1.8 8,0 8 C-1.8 8,-3 6.6,-3 4.4 Z"

    /// Due impronte in diagonale (viewBox 30 × 30), ruotate −35°.
    static var footprints: Path {
        var p = Path()
        let r = CGAffineTransform(rotationAngle: -35 * .pi / 180)
        for (x, y) in [(8.5, 19.0), (20.5, 12.5)] {
            let t = r.concatenating(CGAffineTransform(translationX: x, y: y))
            p.addPath(SVGPath.parse(footSole), transform: t)
            p.addPath(SVGPath.parse(footHeel), transform: t)
        }
        return p
    }
}

/// Poligono con vertici in frazioni del riquadro (come `clip-path: polygon(…%)`).
struct PercentPolygon: InsettableShape {
    let points: [CGPoint]
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var p = Path()
        p.addLines(points.map { CGPoint(x: r.minX + $0.x * r.width, y: r.minY + $0.y * r.height) })
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> PercentPolygon {
        var s = self; s.inset += amount; return s
    }

    /// Vignetta «serie più lunga»: `polygon(0 4%,100% 0,97% 100%,2% 94%)`.
    static let panelA = PercentPolygon(points: [CGPoint(x: 0, y: 0.04), CGPoint(x: 1, y: 0), CGPoint(x: 0.97, y: 1), CGPoint(x: 0.02, y: 0.94)])
    /// Vignetta «prossimo Jolly»: `polygon(2% 0,100% 6%,98% 100%,0 96%)`.
    static let panelB = PercentPolygon(points: [CGPoint(x: 0.02, y: 0), CGPoint(x: 1, y: 0.06), CGPoint(x: 0.98, y: 1), CGPoint(x: 0, y: 0.96)])
    /// Barra dell'istogramma: `polygon(26% 0,100% 0,74% 100%,0 100%)`.
    static let bar = PercentPolygon(points: [CGPoint(x: 0.26, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 0.74, y: 1), CGPoint(x: 0, y: 1)])
}

// MARK: - Icone

/// Fiamma della serie (piena `red`) o del Jolly (`ink` con cuore `red`).
struct FlameIcon: View {
    enum Kind { case streak, jolly }
    let kind: Kind
    @Environment(\.manga) private var c

    var body: some View {
        ZStack {
            SVGShape(MangaPaths.flame, viewBox: MangaPaths.flameBox).fill(kind == .streak ? c.red : c.ink)
            if kind == .jolly {
                SVGShape(MangaPaths.flameCore, viewBox: MangaPaths.flameBox).fill(c.red)
            }
        }
    }
}

/// Icona impostazioni: due linee 22 × 2,4 con cerchietti sfalsati (destra sopra, sinistra sotto).
struct SettingsGlyph: View {
    @Environment(\.manga) private var c
    var body: some View {
        VStack(spacing: 7) {
            line(knobLeading: false)
            line(knobLeading: true)
        }
    }

    private func line(knobLeading: Bool) -> some View {
        RoundedRectangle(cornerRadius: 1.2).fill(c.ink).frame(width: 22, height: 2.4)
            .overlay(alignment: knobLeading ? .leading : .trailing) {
                Circle().fill(c.paper)
                    .overlay(Circle().strokeBorder(c.ink, lineWidth: 2.2))
                    .frame(width: 9, height: 9)
                    .padding(knobLeading ? .leading : .trailing, 3)
            }
    }
}

/// Freccia ‹ o › (14 × 22, tratto 3,2).
struct ChevronGlyph: View {
    let forward: Bool
    @Environment(\.manga) private var c
    var body: some View {
        SVGShape(forward ? "M3 2 L11 11 L3 20" : "M11 2 L3 11 L11 20", viewBox: CGSize(width: 14, height: 22))
            .stroke(c.ink, style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
            .frame(width: 14, height: 22)
    }
}
