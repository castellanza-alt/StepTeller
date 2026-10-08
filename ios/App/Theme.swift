import SwiftUI
import UIKit

/// Palette di Step Teller (porta fedelmente i token CSS della v4.0 web).
/// Nessun nero o bianco assoluto; il tema segue il sistema (chiaro/scuro).
enum Theme {
    private static func dynamic(_ light: UInt32, _ lightA: Double = 1,
                                dark: UInt32, _ darkA: Double = 1) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkA)
                                              : UIColor(hex: light, alpha: lightA)
        })
    }

    static let bg = dynamic(0xEFEDE8, dark: 0x121517)
    static let ink = dynamic(0x1E2022, dark: 0xE4E2DC)
    static let soft = dynamic(0x1E2022, 0.50, dark: 0xE4E2DC, 0.52)
    static let faint = dynamic(0x1E2022, 0.16, dark: 0xE4E2DC, 0.16)
    static let hair = dynamic(0x1E2022, 0.08, dark: 0xE4E2DC, 0.08)
    static let accent = dynamic(0x2E7F73, dark: 0x8CCBBF)
    static let accentSoft = dynamic(0x2E7F73, 0.16, dark: 0x8CCBBF, 0.16)

    static let orb1 = dynamic(0xFFFFFF, 0.95, dark: 0x3C6E68, 0.45)
    static let orb2 = dynamic(0xB2DCD2, 0.75, dark: 0x484278, 0.40)
    static let orb3 = dynamic(0xD6CEEC, 0.55, dark: 0x785A46, 0.22)

    static let glass = dynamic(0xFFFFFF, 0.42, dark: 0xFFFFFF, 0.05)
    static let glassLine = dynamic(0xFFFFFF, 0.80, dark: 0xFFFFFF, 0.12)
    static let glassShadow = dynamic(0x1E2828, 0.08, dark: 0x000000, 0.35)

    // Barra in basso e riquadri pieni
    static let pill = dynamic(0xFFFFFF, 0.70, dark: 0x1E2326)
    static let pillLine = dynamic(0x1E2022, 0.08, dark: 0xFFFFFF, 0.08)
    static let onAccent = dynamic(0xFFFFFF, dark: 0x0E1113)

    // Tappeto
    static let mFrame = dynamic(0x2A2C2E, dark: 0xD6D4CE)
    static let mFrame2 = dynamic(0x4A4D50, dark: 0x9A9893)
    static let mBelt = dynamic(0x3B3E41, dark: 0xB9B7B1)
    static let mSoft = dynamic(0x1E2022, 0.30, dark: 0xE4E2DC, 0.34)
    static let mShadow = dynamic(0x1E2022, 0.18, dark: 0x000000, 0.50)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: CGFloat(alpha))
    }
}
