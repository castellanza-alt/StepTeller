import SwiftUI

/// Etichetta di sezione delle Impostazioni: 11 pt, semibold, maiuscolo spaziato, colore tenue.
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
