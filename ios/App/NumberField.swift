import SwiftUI
import StepTellerCore

/// Numeric field in the language's format (`10.000`, `10,000`): accepts any separator. Shows `value`; calls
/// `onEdit` only when the user types (not when the value changes because Health updates).
struct NumberField: View {
    let value: Int
    var placeholder = "0"
    /// With 0 shows the placeholder instead of «0» (today's steps).
    var emptyWhenZero = false
    var alignment: TextAlignment = .trailing
    let onEdit: (Int) -> Void
    var isFocused: FocusState<Bool>.Binding

    @State private var text = ""
    @State private var skipNext = false   // a text change made by code is not an edit by the user

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(alignment)
            .focused(isFocused)
            .onAppear { text = format(value) }
            .onChange(of: value) { _, new in
                if !isFocused.wrappedValue { text = format(new) }
            }
            .onChange(of: text) { _, new in
                if skipNext { skipNext = false; return }
                let n = LocalFormat.digits(new)
                let formatted = format(n)
                if formatted != new { text = formatted }
                if isFocused.wrappedValue { onEdit(n) }
            }
            .onChange(of: isFocused.wrappedValue) { _, focused in
                if focused {
                    if !text.isEmpty { skipNext = true; text = "" }   // the new number is typed from scratch
                } else {
                    text = format(value)
                }
            }
    }

    private func format(_ n: Int) -> String {
        n == 0 && emptyWhenZero ? "" : LocalFormat.integer(n)
    }
}
