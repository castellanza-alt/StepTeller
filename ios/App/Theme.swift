import SwiftUI
import UIKit

/// Palette of the Settings sheet (the only screen outside the «Dan Dan Dan» style): ported from the
/// CSS tokens of the web app. No absolute black or white; follows the system appearance (light/dark).
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
    static let accent = dynamic(0x2E7F73, dark: 0x8CCBBF)

    static let glass = dynamic(0xFFFFFF, 0.42, dark: 0xFFFFFF, 0.05)
    static let glassLine = dynamic(0xFFFFFF, 0.80, dark: 0xFFFFFF, 0.12)
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: CGFloat(alpha))
    }
}
