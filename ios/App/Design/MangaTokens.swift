import SwiftUI
import CoreText

/// Design tokens of the «Dan Dan Dan» style (Home + History handoff). **The only place** for colors,
/// fonts, sizes and angles: views never write colors by hand.
///
/// Sizes are in points on the 390 × 844 reference frame; the screens draw on this canvas
/// and scale it to the width (`MangaCanvas`).

// MARK: - Theme

enum MangaTheme: String { case day, night }

/// Theme choice in Settings. Default: follows the system (light = day, dark = night).
enum ThemeMode: String, CaseIterable, Identifiable {
    case system, clock, day, night
    var id: String { rawValue }

    static let storageKey = "stepteller.themeMode"
    /// With «Clock»: day from 7:00 to 18:59.
    static let dayHours = 7..<19

    var label: String {
        switch self {
        case .system: L10n.text("set.theme.system")
        case .clock: L10n.text("set.theme.clock")
        case .day: L10n.text("set.theme.day")
        case .night: L10n.text("set.theme.night")
        }
    }

    func resolve(systemScheme: ColorScheme, now: Date, calendar: Calendar = .current) -> MangaTheme {
        switch self {
        case .system: systemScheme == .dark ? .night : .day
        case .clock: Self.dayHours.contains(calendar.component(.hour, from: now)) ? .day : .night
        case .day: .day
        case .night: .night
        }
    }
}

// MARK: - Colors

struct MangaPalette: Equatable {
    let theme: MangaTheme
    /// Background.
    let paper: Color
    /// Text and strokes.
    let ink: Color
    /// The only accent (not customizable: it is painted in the illustrations).
    let red: Color

    /// Radial gradient of the red button and the knob: light → `red` → dark (same in both themes).
    static let redHighlight = Color(hex: 0xFF6A5E)
    static let redDeep = Color(hex: 0xB5140E)
    /// Red button shadow: `rgba(229,35,27,.35)`.
    static let redButtonShadow = Color(hex: 0xE5231B, opacity: 0.35)
    /// Knob glow: `rgba(255,59,48,.45)`.
    static let knobGlow = Color(hex: 0xFF3B30, opacity: 0.45)
    /// Glass button shadow: `rgba(0,0,0,.18)`.
    static let glassShadow = Color.black.opacity(0.18)
    /// Icons inside the red button.
    static let onRed = Color.white

    static let day = MangaPalette(theme: .day, paper: Color(hex: 0xFFFFFF), ink: Color(hex: 0x141414), red: Color(hex: 0xE5231B))
    static let night = MangaPalette(theme: .night, paper: Color(hex: 0x0E1430), ink: Color(hex: 0xE2EAFF), red: Color(hex: 0xFF3B30))

    static func of(_ theme: MangaTheme) -> MangaPalette { theme == .night ? .night : .day }

    var colorScheme: ColorScheme { theme == .night ? .dark : .light }

    // Illustrations (asset catalog)
    var homeArt: String { theme == .night ? "HomeArtNight" : "HomeArtDay" }
    /// Shoe and leg cut out, above `homeArt` for the parallax.
    var homeLeg: String { theme == .night ? "HomeLegNight" : "HomeLegDay" }
    var hill: String { theme == .night ? "HillNight" : "HillDay" }
    var horizon: String { theme == .night ? "HorizonNight" : "HorizonDay" }
}

private struct MangaPaletteKey: EnvironmentKey {
    static let defaultValue = MangaPalette.day
}

extension EnvironmentValues {
    var manga: MangaPalette {
        get { self[MangaPaletteKey.self] }
        set { self[MangaPaletteKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

// MARK: - Sizes

enum Manga {
    /// Reference frame of the handoff.
    static let frameWidth: CGFloat = 390
    static let frameHeight: CGFloat = 844

    // Fixed top bar
    static let statusBarHeight: CGFloat = 50
    static let topBarHeight: CGFloat = 122
    static let barPadding: CGFloat = 18
    static let barGap: CGFloat = 14
    static let buttonSize: CGFloat = 54
    static let navButtonRotation: Double = -6

    // Home illustration: 881 × 1786 px shown at 390 × 790 pt from y = 54.
    static let artTop: CGFloat = 54
    static let artSize = CGSize(width: 390, height: 790)
    /// Pixels of the illustration (and of the `SpeedTrack.road` path).
    static let artPixelSize = CGSize(width: 881, height: 1786)
    /// px → pt (390 / 881).
    static let artScale: CGFloat = artSize.width / artPixelSize.width
    /// Shoe and leg (`homeLeg`): same canvas as the illustration plus 24 px repeated on every side.
    static let legPadding: CGFloat = 24
    /// Maximum shift of shoe and leg when tilting the phone (pt).
    static let parallaxMax: CGFloat = 8

    // Slider
    static let knobSize: CGFloat = 34
    static let knobBorder: CGFloat = 2.5
    static let knobRing: CGFloat = 1.5
    static let knobLabelGap: CGFloat = 14
    /// Beyond this x the value moves to the left of the knob.
    static let knobFlipX: CGFloat = 230
    /// Maximum distance from the path to grab the slider (pt).
    static let trackTouchRadius: CGFloat = 20

    // History
    static let historyHeight: CGFloat = 2020
    static let jollyTicks = 15          // StreakEngine.jollyEvery (decision: 15 like the app, not 14)

    // Animations
    static let navDuration = 0.35
}

// MARK: - Typography

extension Font {
    /// Anton (OFL), the only display font. Fixed size as in the handoff. In Japanese, Korean and Chinese the
    /// characters Anton lacks are drawn by the `TitleFont` font (digits and letters stay Anton).
    static func anton(_ size: CGFloat) -> Font {
        TitleFont.asian == nil ? .custom("Anton-Regular", fixedSize: size) : Font(TitleFont.ctFont(size))
    }

    /// Running text in Anton (introduction paragraphs, control rows). In JA/KO/ZH such a heavy display font
    /// is unreadable in a paragraph: the system bold is used instead.
    static func antonText(_ size: CGFloat) -> Font {
        TitleFont.asian == nil ? .custom("Anton-Regular", fixedSize: size) : .system(size: size, weight: .bold)
    }
}

/// Title typeface by app language: **the single point** deciding it (SwiftUI text and `GlyphText`, app and
/// widget). Anton only has the Latin alphabet; for JA/KO/ZH a heavy OFL font, subset to the characters in use
/// (`scripts/font_asia.py`), cascades after Anton. The other languages stay Anton only.
enum TitleFont {
    /// PostScript name of the Asian font for the app language (`nil` = Anton only).
    static let asian: String? = {
        switch Bundle.main.preferredLocalizations.first {
        case "ja": "DelaGothicOne-Regular"
        case "ko": "BlackHanSans-Regular"
        case "zh-Hans": "NotoSansSC-Black"
        case "zh-Hant": "NotoSansTC-Black"
        default: nil
        }
    }()

    /// Anton with, in JA/KO/ZH, the Asian font in cascade.
    static func ctFont(_ size: CGFloat) -> CTFont {
        guard let asian else { return CTFontCreateWithName("Anton-Regular" as CFString, size, nil) }
        let cascade = [CTFontDescriptorCreateWithNameAndSize(asian as CFString, size)]
        let descriptor = CTFontDescriptorCreateWithAttributes([
            kCTFontNameAttribute: "Anton-Regular",
            kCTFontCascadeListAttribute: cascade,
        ] as CFDictionary)
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }

    /// Tracking (in em) by language: the wide one meant for Anton's capitals spreads ideograms and Korean
    /// characters too far, so in JA/KO/ZH it stops at 0.02 em. The negative one (digits) stays.
    static func tracking(_ em: CGFloat) -> CGFloat { asian == nil ? em : min(em, 0.02) }

    /// Extra space between a caption and a huge number right below it. Anton has a lot of room above its capitals
    /// and its lines are as tall as the size; Asian characters fill the whole square and would touch the
    /// number. In JA/KO/ZH a third of the caption size, elsewhere 0 (layout unchanged).
    static func gap(_ size: CGFloat) -> CGFloat { asian == nil ? 0 : (size * 0.33).rounded() }
}

/// Anton metrics (hhea, per em) to reproduce the CSS `line-height`.
enum AntonMetrics {
    static let ascent: CGFloat = 117.626953125 / 100
    static let descent: CGFloat = 32.91015625 / 100
}
