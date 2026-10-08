import StepTellerCore

/// Scorciatoie di formattazione usate dalle viste.
enum ItalianFormatBridge {
    static func speed(_ v: Double) -> String { ItalianFormat.number(v, decimals: 1) }
}
