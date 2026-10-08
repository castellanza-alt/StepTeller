import SwiftUI

/// Legge i comandi M, L, C, Z (assoluti) di un attributo `d` SVG.
/// Serve a usare **le stesse stringhe** del sorgente web, senza ritrascrivere le coordinate.
extension Path {
    init(svg d: String) {
        self.init()
        var tokens: [String] = []
        var number = ""
        func flush() { if !number.isEmpty { tokens.append(number); number = "" } }
        for ch in d {
            if ch.isLetter { flush(); tokens.append(String(ch)) }
            else if ch == " " || ch == "," { flush() }
            else { number.append(ch) }
        }
        flush()
        var i = 0
        func next() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        while i < tokens.count {
            let cmd = tokens[i]; i += 1
            switch cmd {
            case "M": move(to: CGPoint(x: next(), y: next()))
            case "L": addLine(to: CGPoint(x: next(), y: next()))
            case "C":
                let c1 = CGPoint(x: next(), y: next())
                let c2 = CGPoint(x: next(), y: next())
                let p = CGPoint(x: next(), y: next())
                addCurve(to: p, control1: c1, control2: c2)
            case "Z": closeSubpath()
            default: break
            }
        }
    }
}
