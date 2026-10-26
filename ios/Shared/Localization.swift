import Foundation
import StepTellerCore

/// Translated texts. Keys are the IDs of the sheet `localizzazione/NEAT_testi_tradotti.xlsx`
/// (e.g. `home.done.extra`); the catalogs are regenerated from the sheet with `scripts/cataloghi.py`.
/// Tables: `Localizable` (app, `App/Localizable.xcstrings`) and `Widget` (widget, `Shared/Widget.xcstrings`,
/// compiled into both the app and the extension).
enum L10n {
    static let widget = "Widget"

    /// Text without parameters.
    static func text(_ key: String, table: String? = nil) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: table)
    }

    /// Text with parameters (`%@` already formatted, `%lld` for plurals) in code order: translations
    /// reorder them with indices (`%2$@`).
    static func format(_ key: String, table: String? = nil, _ args: CVarArg...) -> String {
        format(key, table: table, arguments: args)
    }

    static func format(_ key: String, table: String? = nil, arguments: [CVarArg]) -> String {
        String(format: text(key, table: table), locale: Locale.current, arguments: arguments)
    }
}

/// Numbers in the phone's language. Italian keeps the usual format (`ItalianFormat`: «7.200», «8,3»),
/// because iOS in Italian does not group thousands below 10.000; the other languages follow iOS.
enum LocalFormat {
    static let isItalian = Locale.current.language.languageCode == .italian

    /// `10.000` / `10,000`, `8,3` / `8.3`.
    static func number(_ value: Double, decimals: Int = 0) -> String {
        if isItalian { return ItalianFormat.number(value, decimals: decimals) }
        // same rounding as `ItalianFormat` (half up), then only the language's spelling
        let scale = pow(10.0, Double(decimals))
        let rounded = (value * scale).rounded() / scale
        let text = formatter(decimals).string(from: NSNumber(value: rounded)) ?? ItalianFormat.number(value, decimals: decimals)
        // French: the narrow no-break space for thousands (U+202F) is not in Anton; the no-break space is
        return text.replacingOccurrences(of: "\u{202F}", with: "\u{00A0}")
    }

    static func integer(_ value: Int) -> String { number(Double(value)) }

    /// Digits of a typed number, any separator («7.200», «7,200», «7 200» → 7200).
    static func digits(_ text: String) -> Int {
        Int(text.compactMap(\.wholeNumberValue).map(String.init).joined()) ?? 0
    }

    private static let formatters = [0, 1].map { decimals -> NumberFormatter in
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        f.roundingMode = .halfUp
        return f
    }

    private static func formatter(_ decimals: Int) -> NumberFormatter { formatters[min(max(decimals, 0), 1)] }
}
