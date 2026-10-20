import SwiftUI
import CoreText

/// Design token dello stile «Dan Dan Dan» (handoff Home + Storico). **Unico posto** per colori,
/// font, misure e angoli: le viste non scrivono colori a mano.
///
/// Le misure sono in punti sul frame di riferimento 390 × 844; le schermate disegnano su questa tela
/// e la scalano in larghezza (`MangaCanvas`).

// MARK: - Tema

enum MangaTheme: String { case day, night }

/// Scelta del tema nelle Impostazioni. Predefinito: segue il sistema (chiaro = giorno, scuro = notte).
enum ThemeMode: String, CaseIterable, Identifiable {
    case system, clock, day, night
    var id: String { rawValue }

    static let storageKey = "stepteller.themeMode"
    /// Con «Orario»: giorno dalle 7:00 alle 18:59.
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

// MARK: - Colori

struct MangaPalette: Equatable {
    let theme: MangaTheme
    /// Sfondo.
    let paper: Color
    /// Testo e tratti.
    let ink: Color
    /// Unico accento (non personalizzabile: è dipinto nelle illustrazioni).
    let red: Color

    /// Gradiente radiale di bottone rosso e pallino: chiaro → `red` → scuro (uguale nei due temi).
    static let redHighlight = Color(hex: 0xFF6A5E)
    static let redDeep = Color(hex: 0xB5140E)
    /// Ombra del bottone rosso: `rgba(229,35,27,.35)`.
    static let redButtonShadow = Color(hex: 0xE5231B, opacity: 0.35)
    /// Alone del pallino: `rgba(255,59,48,.45)`.
    static let knobGlow = Color(hex: 0xFF3B30, opacity: 0.45)
    /// Ombra del bottone in vetro: `rgba(0,0,0,.18)`.
    static let glassShadow = Color.black.opacity(0.18)
    /// Icone dentro il bottone rosso.
    static let onRed = Color.white

    static let day = MangaPalette(theme: .day, paper: Color(hex: 0xFFFFFF), ink: Color(hex: 0x141414), red: Color(hex: 0xE5231B))
    static let night = MangaPalette(theme: .night, paper: Color(hex: 0x0E1430), ink: Color(hex: 0xE2EAFF), red: Color(hex: 0xFF3B30))

    static func of(_ theme: MangaTheme) -> MangaPalette { theme == .night ? .night : .day }

    var colorScheme: ColorScheme { theme == .night ? .dark : .light }

    // Illustrazioni (asset catalog)
    var homeArt: String { theme == .night ? "HomeArtNight" : "HomeArtDay" }
    /// Scarpa e gamba scontornate, sopra `homeArt` per la parallasse.
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

// MARK: - Misure

enum Manga {
    /// Frame di riferimento del handoff.
    static let frameWidth: CGFloat = 390
    static let frameHeight: CGFloat = 844

    // Barra superiore fissa
    static let statusBarHeight: CGFloat = 50
    static let topBarHeight: CGFloat = 122
    static let barPadding: CGFloat = 18
    static let barGap: CGFloat = 14
    static let buttonSize: CGFloat = 54
    static let navButtonRotation: Double = -6

    // Illustrazione della Home: 881 × 1786 px mostrata a 390 × 790 pt da y = 54.
    static let artTop: CGFloat = 54
    static let artSize = CGSize(width: 390, height: 790)
    /// Pixel dell'illustrazione (e del tracciato `SpeedTrack.road`).
    static let artPixelSize = CGSize(width: 881, height: 1786)
    /// px → pt (390 / 881).
    static let artScale: CGFloat = artSize.width / artPixelSize.width
    /// Scarpa e gamba (`homeLeg`): stessa tela dell'illustrazione più 24 px ripetuti su ogni lato.
    static let legPadding: CGFloat = 24
    /// Spostamento massimo di scarpa e gamba inclinando il telefono (pt).
    static let parallaxMax: CGFloat = 8

    // Cursore
    static let knobSize: CGFloat = 34
    static let knobBorder: CGFloat = 2.5
    static let knobRing: CGFloat = 1.5
    static let knobLabelGap: CGFloat = 14
    /// Oltre questa x il valore passa a sinistra del pallino.
    static let knobFlipX: CGFloat = 230
    /// Distanza massima dal tracciato per prendere il cursore (pt).
    static let trackTouchRadius: CGFloat = 20

    // Storico
    static let historyHeight: CGFloat = 2020
    static let jollyTicks = 15          // StreakEngine.jollyEvery (decisione: 15 come l'app, non 14)

    // Animazioni
    static let navDuration = 0.35
}

// MARK: - Tipografia

extension Font {
    /// Anton (OFL), unico font display. Corpo fisso come nel handoff. In giapponese, coreano e cinese i caratteri
    /// che Anton non ha li disegna il font di `TitleFont` (cifre e lettere restano Anton).
    static func anton(_ size: CGFloat) -> Font {
        TitleFont.asian == nil ? .custom("Anton-Regular", fixedSize: size) : Font(TitleFont.ctFont(size))
    }

    /// Testo corrente in Anton (paragrafi dell'introduzione, righe dei controlli). In JA/KO/ZH un font da titolo
    /// così spesso non si legge in un paragrafo: si usa il grassetto di sistema.
    static func antonText(_ size: CGFloat) -> Font {
        TitleFont.asian == nil ? .custom("Anton-Regular", fixedSize: size) : .system(size: size, weight: .bold)
    }
}

/// Carattere dei titoli secondo la lingua dell'app: **unico punto** che lo decide (testo SwiftUI e `GlyphText`, app e
/// widget). Anton ha solo l'alfabeto latino; per JA/KO/ZH un font OFL spesso, ridotto ai caratteri usati
/// (`scripts/font_asia.py`), entra in cascata dopo Anton. Le altre lingue restano solo Anton.
enum TitleFont {
    /// Nome PostScript del font asiatico per la lingua dell'app (`nil` = solo Anton).
    static let asian: String? = {
        switch Bundle.main.preferredLocalizations.first {
        case "ja": "DelaGothicOne-Regular"
        case "ko": "BlackHanSans-Regular"
        case "zh-Hans": "NotoSansSC-Black"
        case "zh-Hant": "NotoSansTC-Black"
        default: nil
        }
    }()

    /// Anton con, in JA/KO/ZH, il font asiatico in cascata.
    static func ctFont(_ size: CGFloat) -> CTFont {
        guard let asian else { return CTFontCreateWithName("Anton-Regular" as CFString, size, nil) }
        let cascade = [CTFontDescriptorCreateWithNameAndSize(asian as CFString, size)]
        let descriptor = CTFontDescriptorCreateWithAttributes([
            kCTFontNameAttribute: "Anton-Regular",
            kCTFontCascadeListAttribute: cascade,
        ] as CFDictionary)
        return CTFontCreateWithFontDescriptor(descriptor, size, nil)
    }

    /// Spaziatura (in em) per la lingua: quella larga pensata per le maiuscole di Anton separa troppo gli ideogrammi
    /// e i caratteri coreani, quindi in JA/KO/ZH si ferma a 0,02 em. Quella negativa (cifre) resta.
    static func tracking(_ em: CGFloat) -> CGFloat { asian == nil ? em : min(em, 0.02) }

    /// Spazio in più tra una scritta e un numero gigante attaccato. Anton ha molto spazio sopra le maiuscole e
    /// le righe sono alte quanto il corpo; i caratteri asiatici riempiono tutto il quadrato e finirebbero sul
    /// numero. In JA/KO/ZH un terzo del corpo della scritta, altrove 0 (layout invariato).
    static func gap(_ size: CGFloat) -> CGFloat { asian == nil ? 0 : (size * 0.33).rounded() }
}

/// Metriche di Anton (hhea, per em) per riprodurre il `line-height` del CSS.
enum AntonMetrics {
    static let ascent: CGFloat = 117.626953125 / 100
    static let descent: CGFloat = 32.91015625 / 100
}
