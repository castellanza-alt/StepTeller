import Foundation

/// Formattazione italiana indipendente dalle impostazioni del dispositivo
/// (separatore migliaia «.», decimale «,»). Implementata a mano per dare lo stesso
/// risultato su Linux, macOS e iOS.
public enum ItalianFormat {
    /// `10.000`, `67,5`, `8,3`.
    public static func number(_ value: Double, decimals: Int = 0) -> String {
        let scale = pow(10.0, Double(decimals))
        let rounded = (value * scale).rounded() / scale
        let negative = rounded < 0
        let text = String(format: "%.\(decimals)f", abs(rounded))
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        var integer = String(parts[0])
        var grouped = ""
        while integer.count > 3 {
            grouped = "." + integer.suffix(3) + grouped
            integer = String(integer.dropLast(3))
        }
        var result = integer + grouped
        if decimals > 0, parts.count > 1 { result += "," + parts[1] }
        return (negative ? "-" : "") + result
    }

    public static func integer(_ value: Int) -> String { number(Double(value)) }

    /// Estrae le cifre da un testo digitato (`"7.200"` → 7200).
    public static func digits(_ text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }
}
