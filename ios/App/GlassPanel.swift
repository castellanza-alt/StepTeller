import SwiftUI

/// Pannello in vetro: fill traslucido + bordo chiaro + filetto luminoso in alto.
/// Dietro ci sono già gli orb sfumati (blur 70), quindi una sfocatura aggiuntiva non si vedrebbe:
/// niente `Material`, che in chiaro aggiungerebbe una velatura non presente nella web app.
/// L'ombra è disegnata solo **fuori** dal pannello (come `box-shadow`), altrimenti
/// trasparirebbe sotto il vetro.
struct GlassPanelBackground: View {
    private let radius: CGFloat = 28

    var body: some View {
        ZStack(alignment: .top) {
            Canvas { ctx, size in
                let pad: CGFloat = 80
                let inner = CGRect(x: pad, y: pad, width: size.width - 2 * pad, height: size.height - 2 * pad)
                let shape = Path(roundedRect: inner, cornerRadius: radius)
                var outside = Path(CGRect(origin: .zero, size: size))
                outside.addPath(shape)
                var c = ctx
                c.clip(to: outside, style: FillStyle(eoFill: true))
                c.addFilter(.shadow(color: Theme.glassShadow, radius: 25, x: 0, y: 20))
                c.fill(shape, with: .color(.black))
            }
            .padding(-80)
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Theme.glass)
            RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.glassLine, lineWidth: 1)
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Theme.glassLine, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, radius)
                .padding(.top, 1)
        }
    }
}
