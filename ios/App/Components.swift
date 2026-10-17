import SwiftUI

/// Etichetta di sezione: 11 pt, semibold, maiuscolo spaziato, colore tenue.
struct SectionLabel: View {
    let text: String
    var tracking: CGFloat = 0.24
    init(_ text: String, tracking: CGFloat = 0.24) { self.text = text; self.tracking = tracking }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold)).tracking(11 * tracking)
            .foregroundStyle(Theme.soft)
    }
}

/// Rombo (Jolly) disegnato come nei mockup; la fiamma (streak) è il simbolo di sistema `flame.fill`.
struct GemShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 12 * s, y: 3 * s))
        p.addLine(to: CGPoint(x: 19 * s, y: 10 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 21 * s))
        p.addLine(to: CGPoint(x: 5 * s, y: 10 * s))
        p.closeSubpath()
        return p
    }
}

/// Icona impostazioni (due cursori).
struct SlidersIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 24
            let st = StrokeStyle(lineWidth: 1.7 * s, lineCap: .round)
            for (a, b, y) in [(4.0, 9.0, 7.0), (18.0, 20.0, 7.0), (4.0, 6.0, 17.0), (11.0, 20.0, 17.0)] {
                var p = Path(); p.move(to: CGPoint(x: a * s, y: y * s)); p.addLine(to: CGPoint(x: b * s, y: y * s))
                ctx.stroke(p, with: .foreground, style: st)
            }
            ctx.stroke(Path(ellipseIn: CGRect(x: (15.5 - 2.3) * s, y: (7 - 2.3) * s, width: 4.6 * s, height: 4.6 * s)), with: .foreground, style: st)
            ctx.stroke(Path(ellipseIn: CGRect(x: (8.5 - 2.3) * s, y: (17 - 2.3) * s, width: 4.6 * s, height: 4.6 * s)), with: .foreground, style: st)
        }
        .frame(width: 24, height: 24)
    }
}

/// Bottone tondo in vetro (Liquid Glass da iOS 26; materiale sfocato sulle versioni precedenti).
struct RoundIconButton<Icon: View>: View {
    let label: String
    let action: () -> Void
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        Button(action: action) {
            icon().foregroundStyle(Theme.ink)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
                .glass(Circle(), interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Vetro di sistema: `glassEffect` da iOS 26, altrimenti materiale sottile con un filo di bordo.
    @ViewBuilder
    func glass<S: Shape>(_ shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
                .overlay(shape.stroke(Theme.cardLine, lineWidth: 0.5))
                .shadow(color: Theme.shadow, radius: 10, y: 4)
        }
    }
}
