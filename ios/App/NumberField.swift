import SwiftUI
import StepTellerCore

/// Campo numerico con formato italiano (`10.000`). Mostra `value`; chiama `onEdit` solo quando
/// è Will a digitare (non quando il valore cambia perché Salute si aggiorna).
struct NumberField: View {
    let value: Int
    var placeholder = "0"
    let onEdit: (Int) -> Void
    var focus: FocusState<ContentView.Field?>.Binding
    let field: ContentView.Field

    @State private var text = ""
    @State private var skipNext = false   // il cambio di testo fatto dal codice non è una modifica di Will

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused(focus, equals: field)
            .onAppear { text = format(value) }
            .onChange(of: value) { _, new in
                if focus.wrappedValue != field { text = format(new) }
            }
            .onChange(of: text) { _, new in
                if skipNext { skipNext = false; return }
                let n = ItalianFormat.digits(new)
                let formatted = format(n)
                if formatted != new { text = formatted }
                if focus.wrappedValue == field { onEdit(n) }
            }
            .onChange(of: focus.wrappedValue) { _, new in
                if new == field {
                    if !text.isEmpty { skipNext = true; text = "" }   // si digita il nuovo numero da zero
                } else {
                    text = format(value)
                }
            }
    }

    private func format(_ n: Int) -> String {
        n == 0 && placeholder == "0" && field == .steps ? "" : ItalianFormat.integer(n)
    }
}
