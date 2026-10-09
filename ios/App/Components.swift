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

extension View {
    /// Riquadro in vetro: fill traslucido + bordo chiaro.
    func glassCard(radius: CGFloat = 28, padding: EdgeInsets = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)) -> some View {
        self.padding(padding)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.glass))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1))
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
        .frame(width: 20, height: 20)
    }
}

/// Intestazione comune: marchio a sinistra, (chip) e impostazioni a destra.
struct AppHeader<Trailing: View>: View {
    let onSettings: () -> Void
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(alignment: .center) {
            Text("STEP TELLER")
                .font(.system(size: 11, weight: .semibold)).tracking(11 * 0.34)
                .foregroundStyle(Theme.soft)
            Spacer()
            trailing()
            Button(action: onSettings) {
                SlidersIcon().foregroundStyle(Theme.soft)
                    .frame(width: 44, height: 44)
            }
            .padding(.trailing, -10)
            .accessibilityLabel("Impostazioni")
        }
        .frame(height: 30)
    }
}
