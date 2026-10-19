import SwiftUI

/// Tab segmentati: celle inclinate −14°, bordo interno 2 pt `ink`; attiva `ink` su `paper` invertito.
/// L'intero gruppo è ruotato −1,5°.
struct MangaTabs<Value: Hashable>: View {
    let items: [(Value, String)]
    @Binding var selection: Value
    var width: CGFloat
    var height: CGFloat
    var fontSize: CGFloat
    var tracking: CGFloat
    var gap: CGFloat
    var rotation: Double = -1.5
    @Environment(\.manga) private var c

    var body: some View {
        HStack(spacing: gap) {
            ForEach(items, id: \.0) { value, label in
                let on = value == selection
                Button { selection = value } label: {
                    AntonText(label, fontSize, tracking: tracking, color: on ? c.paper : c.ink, minScale: 0.6)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .background(on ? c.ink : c.paper)
                        .overlay(Rectangle().strokeBorder(c.ink, lineWidth: 2))
                        .manga(skew: -14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label.capitalized)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .frame(width: width)
        .manga(rotate: rotation)
    }
}

/// Vignetta: bordo `ink` 3 pt ottenuto da due poligoni storti, interno `paper`.
struct Vignette<Content: View>: View {
    let shape: PercentPolygon
    let width: CGFloat
    @ViewBuilder var content: () -> Content
    @Environment(\.manga) private var c

    var body: some View {
        content()
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
            .frame(width: width, alignment: .leading)
            .background(c.paper)
            .clipShape(shape)
            .padding(3)
            .background(c.ink)
            .clipShape(shape)
    }
}

/// Titolo di sezione con la pennellata rossa sotto («I MIEI PASSI», «IL MIO MEGLIO»).
struct BrushTitle: View {
    let text: String
    let brushWidth: CGFloat
    @Environment(\.manga) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            AntonText(text, 60, lineHeight: 0.95, tracking: -0.01)
            SVGShape(MangaPaths.brush, viewBox: MangaPaths.brushBox).fill(c.red)
                .frame(width: brushWidth, height: 16)
        }
        .manga(rotate: -5, skew: -10, anchor: UnitPoint(x: 0, y: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text.capitalized)
        .accessibilityAddTraits(.isHeader)
    }
}
