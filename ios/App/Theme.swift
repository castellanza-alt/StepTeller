import SwiftUI
import UIKit

/// Palette «carta e matita» (mockup di ottobre 2026): fondo carta, inchiostro quasi nero, rosso pennello.
/// Nessun nero o bianco assoluto; il tema segue il sistema (chiaro/scuro).
enum Theme {
    private static func dynamic(_ light: UInt32, _ lightA: Double = 1,
                                dark: UInt32, _ darkA: Double = 1) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkA)
                                              : UIColor(hex: light, alpha: lightA)
        })
    }

    static let bg = dynamic(0xFAF9F6, dark: 0x121416)
    static let ink = dynamic(0x1C1C1C, dark: 0xECEAE4)
    static let soft = dynamic(0x1C1C1C, 0.58, dark: 0xECEAE4, 0.58)
    static let faint = dynamic(0x1C1C1C, 0.18, dark: 0xECEAE4, 0.18)
    static let hair = dynamic(0x1C1C1C, 0.09, dark: 0xECEAE4, 0.10)
    static let accent = dynamic(0xE0241B, dark: 0xFF4A3D)
    static let accentSoft = dynamic(0xE0241B, 0.14, dark: 0xFF4A3D, 0.18)
    static let onAccent = dynamic(0xFFFFFF, dark: 0xFFFFFF)

    /// Bottoni tondi e controlli a pillola.
    static let card = dynamic(0xFFFFFF, dark: 0x23272A)
    static let cardLine = dynamic(0x1C1C1C, 0.10, dark: 0xFFFFFF, 0.10)
    static let shadow = dynamic(0x1C1C1C, 0.16, dark: 0x000000, 0.55)

    // Riquadri delle Impostazioni
    static let glass = dynamic(0xFFFFFF, 0.85, dark: 0xFFFFFF, 0.05)
    static let glassLine = dynamic(0x1C1C1C, 0.08, dark: 0xFFFFFF, 0.10)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: CGFloat(alpha))
    }
}
