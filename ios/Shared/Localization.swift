import Foundation
import StepTellerCore

/// Testi tradotti. Le chiavi sono gli ID del foglio `localizzazione/NEAT_testi_tradotti.xlsx`
/// (es. `home.done.extra`); i cataloghi si rigenerano dal foglio con `scripts/cataloghi.py`.
/// Tabelle: `Localizable` (app, `App/Localizable.xcstrings`) e `Widget` (widget, `Shared/Widget.xcstrings`,
/// compilata nell'app e nell'estensione).
enum L10n {
    static let widget = "Widget"

    /// Testo senza parametri.
    static func text(_ key: String, table: String? = nil) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: table)
    }

    /// Testo con parametri (`%@` già formattati, `%lld` per i plurali), nell'ordine del codice: le
    /// traduzioni li spostano con gli indici (`%2$@`).
    static func format(_ key: String, table: String? = nil, _ args: CVarArg...) -> String {
        format(key, table: table, arguments: args)
    }

    static func format(_ key: String, table: String? = nil, arguments: [CVarArg]) -> String {
        String(format: text(key, table: table), locale: Locale.current, arguments: arguments)
    }
}

/// Numeri nella lingua del telefono. In italiano resta il formato di sempre (`ItalianFormat`: «7.200»,
/// «8,3»), perché iOS in italiano non separa le migliaia sotto 10.000; nelle altre lingue decide iOS.
enum LocalFormat {
    static let isItalian = Locale.current.language.languageCode == .italian

    /// `10.000` / `10,000`, `8,3` / `8.3`.
    static func number(_ value: Double, decimals: Int = 0) -> String {
        if isItalian { return ItalianFormat.number(value, decimals: decimals) }
        // stesso arrotondamento di `ItalianFormat` (metà per eccesso), poi solo la scrittura della lingua
        let scale = pow(10.0, Double(decimals))
        let rounded = (value * scale).rounded() / scale
        let text = formatter(decimals).string(from: NSNumber(value: rounded)) ?? ItalianFormat.number(value, decimals: decimals)
        // francese: lo spazio stretto delle migliaia (U+202F) non è in Anton; lo spazio fisso sì
        return text.replacingOccurrences(of: "\u{202F}", with: "\u{00A0}")
    }

    static func integer(_ value: Int) -> String { number(Double(value)) }

    /// Cifre di un numero digitato, con qualsiasi separatore («7.200», «7,200», «7 200» → 7200).
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
