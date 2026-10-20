# NEAT (ex Step Teller) — app iOS nativa

Versione nativa (SwiftUI) di Step Teller, sul telefono col nome **NEAT**, con i passi di oggi letti da Apple Salute.
La web app resta in radice al repository (non toccata).

## Struttura

| Percorso | Contenuto |
|---|---|
| `Sources/StepTellerCore/` | Nucleo (solo Foundation): cadenza e taratura, calcolo, formato e date italiane (test golden), testi del promemoria come dati, logica sorgente passi |
| `Tests/StepTellerCoreTests/` | Test del nucleo (valori golden della web app v4.0) — `swift test` anche su Linux |
| `App/` | App SwiftUI: `RootView` (tema e navigazione), `TopBar`, `Home/` (Home e cursore sulla strada), `Storico/`, `StepsStore`, `HealthKitStepsProvider` |
| `App/Design/` | Stile «Dan Dan Dan»: **token** (`MangaTokens.swift`, unico posto per colori, font, misure), testo Anton, trasformazioni, forme, effetti |
| `App/Fonts/` | `Anton-Regular.ttf` (SIL OFL, licenza accanto) |
| `project.yml` | Progetto XcodeGen (nessun `.xcodeproj` versionato) |
| `scripts/` | `asc.py` (API App Store Connect), `screenshots.sh`, `cataloghi.py` (String Catalog dal foglio), `check_icon.py`, `select_xcode.sh` |
| `localizzazione/` | Foglio delle traduzioni approvate (fonte dei cataloghi), prompt e screenshot usati per tradurre |

Bundle ID `it.castellanza.stepteller` · Team `5E426PLFWN` · iOS 17+.

## Dove si aggiungono i punti di taratura

`Sources/StepTellerCore/CadenceModel.swift`, enum `Calibration` (un solo posto). Esempio per la camminata:
`public static let walk = [CalibrationPoint(speed: 5.0, cadence: 112.0)]`. Con 1 punto il rapporto è costante,
con 2 o più è interpolato e costante oltre gli estremi. Aggiornare poi i test golden se cambiano.

## Stile e tema

Le schermate sono disegnate sulla tela del handoff (390 × 844 pt) e scalate in larghezza (`MangaCanvas`). Colori solo da
`MangaPalette` (`.day` / `.night`) via `@Environment(\.manga)`; `Theme.swift` resta per le Impostazioni.
Il cursore della velocità segue `SpeedTrack.road` (nucleo, con test): tracciato in pixel dell'illustrazione, 3–16 km/h
lineare sulla lunghezza dell'arco. Debug: `-stepteller.themeMode day|night|system|clock`, `-stepteller.debugSteps -1`
(Salute senza dati), `-stepteller.debugScroll 0…1` (Storico già scorso, per gli screenshot).

## Introduzione (primo avvio)

`App/Onboarding/OnboardingView.swift`: quattro pagine (benvenuto, Salute, obiettivo, promemoria). La richiesta di
Salute parte lasciando la sua pagina; quella delle notifiche al tocco su «Inizia», solo con il promemoria acceso.
`StepsStore.start()` parte solo a introduzione conclusa. Chi aveva già l'app non la vede: al primo avvio della
versione nuova, se UserDefaults contiene già una chiave dell'app (obiettivo, storico obiettivi, inizio serie,
velocità, promemoria, taratura, tema) l'introduzione è segnata come fatta (`stepteller.onboarding.done`).
Si rivede da Impostazioni → Informazioni → «Rivedi l'introduzione» (non richiede di nuovo i permessi e non cambia
obiettivo e promemoria se non li si tocca). Debug: `-stepteller.debugOnboarding 1…4` la apre su quella pagina
(solo build Debug; screenshot `intro-*` in `scripts/screenshots.sh`). Con `-stepteller.debugSteps` l'introduzione non
compare, così gli screenshot di Home e Storico restano quelli di prima.

## Lingue

Italiano (lingua di sviluppo) e inglese, spagnolo, francese, tedesco, portoghese (Brasile), giapponese, coreano, cinese
semplificato e tradizionale: l'app segue la lingua del telefono (o quella scelta per NEAT in Impostazioni di iOS).

- **Fonte dei testi**: `localizzazione/NEAT_testi_tradotti.xlsx`, foglio «Testi» (una riga per testo con ID, contesto,
  limite e una colonna per lingua; foglio «Glossario» per i termini). I cataloghi **non si modificano a mano**: si
  correggono le righe del foglio e si rigenerano con `python3 scripts/cataloghi.py` (serve `pip install openpyxl`).
- **Cataloghi**: `App/Localizable.xcstrings` (app), `Shared/Widget.xcstrings` (tabella `Widget`, compilata nell'app e
  nell'estensione), `App/InfoPlist.xcstrings` e `LiveActivity/InfoPlist.xcstrings` (permessi di Salute). Le chiavi
  sono gli ID del foglio, il commento è il contesto. Nel codice: `L10n.text("home.done.1")`,
  `L10n.format("home.done.extra", numero)`, tabella del widget con `table: L10n.widget` (`Shared/Localization.swift`).
- **Segnaposto** `{passi}` → `%@`/`%1$@` nell'ordine di `PARAMS` in `scripts/cataloghi.py` (quello del codice; le
  lingue possono spostarli). Righe `.one`/`.other` → una chiave con plurale. Frasi fatte di più righe (notifica con
  avviso sul Jolly o sulla serie, VoiceOver del widget) → una stringa intera per lingua (`COMPOSED`).
- **Numeri e date**: `LocalFormat` e `HistoryLabels.current`. In italiano restano `ItalianFormat` e
  `HistoryLabels.italian` del nucleo (stessi valori dei test golden: iOS scriverebbe «7200» e «19–25 ottobre»); nelle
  altre lingue `NumberFormatter`, `DateFormatter` e `DateIntervalFormatter` con la lingua del telefono. Il campo dei
  passi accetta qualsiasi separatore.
- **Promemoria**: il nucleo (`ReminderPlanner`) dà il caso e i numeri (`ReminderMessage`), il testo lo compone
  `ReminderScheduler` con il catalogo.
- **Testi lunghi**: le schede dello Storico si rimpiccioliscono fino al 60% se una traduzione non entra
  (`AntonText(…, minScale:)`); in italiano non cambia nulla.
- **Screenshot per lingua**: `scripts/screenshots.sh APP USCITA [lingua] [giorno]` (es. `… build/shots-de de`;
  `giorno` = solo tema giorno).

**Titoli in giapponese, coreano e cinese**: Anton ha solo l'alfabeto latino; i caratteri che gli mancano li
disegna un font OFL spesso, ridotto ai soli caratteri usati: Dela Gothic One (JA), Black Han Sans (KO), Noto Sans SC
Black e Noto Sans TC Black (ZH), in `App/Fonts/*-NEAT.ttf` con la licenza accanto (`*-OFL.txt`). I sottoinsiemi si
rigenerano con `python3 scripts/font_asia.py` (serve `pip install openpyxl fonttools`) **ogni volta che cambiano le
traduzioni del foglio**: lo script prende tutti i testi della lingua dal foglio più quelli che iOS genera nell'app
(date di Impostazioni e record, titoli dei periodi, mesi e iniziali dei giorni dello Storico, numeri), prodotti con gli
stessi formattatori dell'app da `scripts/font_asia/stringhe.swift`, scarica i font interi da google/fonts a un commit
fisso (controllo SHA-256, cache in `build/font_asia/`) e si ferma con errore se un carattere non è coperto. I file
ottenuti sono identici a ogni rigenerazione, quindi un diff vuoto vuol dire che non serviva cambiarli. Nel codice
un solo punto decide il carattere: `TitleFont` in `App/Design/MangaTokens.swift` (usato da `Font.anton`, da
`GlyphText` e dal widget), con la spaziatura delle maiuscole di Anton ridotta a 0,02 em nelle quattro lingue; i
paragrafi dell'introduzione lì usano il grassetto di sistema (`Font.antonText`).

**Aggiungere una lingua**: una colonna nel foglio (titolo come le altre, es. «Olandese (NL)») con tutte le righe;
la coppia colonna → codice (`("Olandese (NL)", "nl")`) in `LANGUAGES` di `scripts/cataloghi.py` (e in
`PLURAL_CATEGORIES` se la lingua non ha le forme one/other); `python3 scripts/cataloghi.py`; `xcodegen generate`
(le lingue del progetto si leggono dai cataloghi); la lingua in `case "$LINGUA"` di `scripts/screenshots.sh`; poi
screenshot e controllo delle lunghezze.

## Salute (HealthKit)

Solo lettura di `stepCount`, `HKStatisticsQuery` `.cumulativeSum` da mezzanotte (deduplica iPhone/Watch),
`HKObserverQuery` in primo piano. Se non arrivano dati (vuoto, negato o errore: iOS non li distingue) l'app mostra
0 passi, fonte «manuale» e l'avviso con il pulsante per le Impostazioni. I passi non vengono mai salvati.
Il fornitore finto (`DebugStepsProvider`) esiste **solo in Debug** per gli screenshot.

Privacy manifest: `App/PrivacyInfo.xcprivacy` e `LiveActivity/PrivacyInfo.xcprivacy` (inclusi da `project.yml`).
Nessun tracciamento, nessun dato raccolto; unica API «required reason» è UserDefaults (CA92.1, 1C8F.1 per
l'App Group `group.it.castellanza.stepteller` condiviso col widget). Se si aggiungono API di quella lista
(date dei file, uptime, spazio su disco, tastiere attive) vanno dichiarate lì.

## Widget

`LiveActivity/WidgetsBundle.swift` (punto di ingresso), `LiveActivity/StepsWidget.swift` (provider e lettura Salute) e
`Shared/StepsWidgetView.swift` (piccolo 170×170, medio 364×170, blocco schermo), nello stile «Dan Dan Dan» con i token
dell'app; arte in `Shared/WidgetAssets.xcassets`.
Obiettivo, taratura, velocità del cursore, serie e Jolly arrivano dall'app via App Group (`Shared/SharedStore.swift`);
i minuti usano lo stesso modello tarato dell'app. Tocco → `stepteller://oggi`. In Debug `WidgetPreviewScreen` mostra i widget
per gli screenshot (`-stepteller.debugWidget 1`).

## Icona

`App/AppIcon.icon` (Icon Composer, Liquid Glass): fondo nero pieno, livello «Suola» (`rosso.svg`, vetro con riflessi) e
livello «Scarpa» (`bianco.svg`), vettoriali ricavati dal disegno scelto da Will (ottobre 2026). Varianti scura, colorata e
trasparente generate da iOS. Anteprima da terminale con `ictool` (dentro Icon Composer.app). `scripts/check_icon.py` la verifica in CI.

## CI

- `.github/workflows/ios-verifica.yml` — su PR e push a `main` o `ia/versione-0.6.2` quando cambia `ios/**`: `swift test` (Linux),
  build simulatore + test + screenshot chiaro/scuro (artefatto `screenshot-simulatore`).
- `.github/workflows/ios-testflight.yml` — con un push su `main` o `ia/versione-0.6.2` il cui messaggio contiene `[apple]` (solo preparazione Apple) o `[testflight]` (build completa); avvio manuale dopo il merge: verifica Apple, firma automatica con
  chiave API, upload, assegnazione al gruppo «Personale». Numero di build `1.<run_number>.<run_attempt>`.

Segreti Actions (solo nomi): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`. Il repository è pubblico: **mai**
chiavi, profili o certificati nel codice.

## Distribuzione

Commit con `[testflight]` sul ramo → build su TestFlight → Will aggiorna dall'app TestFlight. La versione di marketing è in
`project.yml` (`MARKETING_VERSION`).
