import SwiftUI
import StepTellerCore

/// Campo numerico con formato italiano (`10.000`). Mostra `value`; chiama `onEdit` solo quando
/// è Will a digitare (non quando il valore cambia perché Salute si aggiorna).
struct NumberField: View {
    let value: Int
    var placeholder = "0"
    /// Con 0 mostra il segnaposto invece di «0» (passi di oggi).
    var emptyWhenZero = false
    let onEdit: (Int) -> Void
    var isFocused: FocusState<Bool>.Binding

    @State private var text = ""
    @State private var skipNext = false   // il cambio di testo fatto dal codice non è una modifica di Will

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused(isFocused)
            .onAppear { text = format(value) }
            .onChange(of: value) { _, new in
                if !isFocused.wrappedValue { text = format(new) }
            }
            .onChange(of: text) { _, new in
                if skipNext { skipNext = false; return }
                let n = ItalianFormat.digits(new)
                let formatted = format(n)
                if formatted != new { text = formatted }
                if isFocused.wrappedValue { onEdit(n) }
            }
            .onChange(of: isFocused.wrappedValue) { _, focused in
                if focused {
                    if !text.isEmpty { skipNext = true; text = "" }   // si digita il nuovo numero da zero
                } else {
                    text = format(value)
                }
            }
    }

    private func format(_ n: Int) -> String {
        n == 0 && emptyWhenZero ? "" : ItalianFormat.integer(n)
    }
}
