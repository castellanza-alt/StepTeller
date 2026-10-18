# Step Teller — app iOS nativa

Versione nativa (SwiftUI) di Step Teller, con i passi di oggi letti da Apple Salute.
La web app resta in radice al repository (non toccata).

## Struttura

| Percorso | Contenuto |
|---|---|
| `Sources/StepTellerCore/` | Nucleo (solo Foundation): cadenza e taratura, calcolo, formato italiano, logica sorgente passi |
| `Tests/StepTellerCoreTests/` | Test del nucleo (valori golden della web app v4.0) — `swift test` anche su Linux |
| `App/` | App SwiftUI: `RootView` (tema e navigazione), `TopBar`, `Home/` (Home e cursore sulla strada), `Storico/`, `StepsStore`, `HealthKitStepsProvider` |
| `App/Design/` | Stile «Dan Dan Dan»: **token** (`MangaTokens.swift`, unico posto per colori, font, misure), testo Anton, trasformazioni, forme, effetti |
| `App/Fonts/` | `Anton-Regular.ttf` (SIL OFL, licenza accanto) |
| `project.yml` | Progetto XcodeGen (nessun `.xcodeproj` versionato) |
| `scripts/` | `asc.py` (API App Store Connect), `screenshots.sh`, `check_icon.py`, `select_xcode.sh` |

Bundle ID `it.castellanza.stepteller` · Team `5E426PLFWN` · iOS 17+.

## Dove si aggiungono i punti di taratura

`Sources/StepTellerCore/CadenceModel.swift`, enum `Calibration` (un solo posto). Esempio per la camminata:
`public static let walk = [CalibrationPoint(speed: 5.0, cadence: 112.0)]`. Con 1 punto il rapporto è costante,
con 2 o più è interpolato e costante oltre gli estremi. Aggiornare poi i test golden se cambiano.

## Stile e tema

Le schermate sono disegnate sulla tela del handoff (390 × 844 pt) e scalate in larghezza (`MangaCanvas`). Colori solo da
`MangaPalette` (`.day` / `.night`) via `@Environment(\.manga)`; `Theme.swift` resta per Impostazioni, widget e Live Activity.
Il cursore della velocità segue `SpeedTrack.road` (nucleo, con test): tracciato in pixel dell'illustrazione, 3–16 km/h
lineare sulla lunghezza dell'arco. Debug: `-stepteller.themeMode day|night|system|clock`, `-stepteller.debugSteps -1`
(Salute senza dati).

## Salute (HealthKit)

Solo lettura di `stepCount`, `HKStatisticsQuery` `.cumulativeSum` da mezzanotte (deduplica iPhone/Watch),
`HKObserverQuery` in primo piano. Se non arrivano dati (vuoto, negato o errore: iOS non li distingue) l'app mostra
0 passi, fonte «manuale» e l'avviso con il pulsante per le Impostazioni. I passi non vengono mai salvati.
Il fornitore finto (`DebugStepsProvider`) esiste **solo in Debug** per gli screenshot.

## Widget

`LiveActivity/StepsWidget.swift` (provider e lettura Salute) e `Shared/StepsWidgetView.swift` (piccolo 170×170, medio
364×170, blocco schermo), nello stile «Dan Dan Dan» con i token dell'app; arte in `Shared/WidgetAssets.xcassets`.
Obiettivo, taratura, velocità del cursore, serie e Jolly arrivano dall'app via App Group (`Shared/SharedStore.swift`);
i minuti usano lo stesso modello tarato dell'app. Tocco → `stepteller://oggi`. In Debug `WidgetPreviewScreen` mostra i widget
per gli screenshot (`-stepteller.debugWidget 1`).

## Icona

`App/AppIcon.icon` (Icon Composer, Liquid Glass): livelli scarpa (PNG ritagliato), pennellata e raggi (SVG), varianti
giorno/notte. Anteprima da terminale con `ictool` (dentro Icon Composer.app). `scripts/check_icon.py` la verifica in CI.

## CI

- `.github/workflows/ios-verifica.yml` — su PR e push a `ios-nativa` quando cambia `ios/**`: `swift test` (Linux),
  build simulatore + test + screenshot chiaro/scuro (artefatto `screenshot-simulatore`).
- `.github/workflows/ios-testflight.yml` — con un push su `ios-nativa` il cui messaggio contiene `[apple]` (solo preparazione Apple) o `[testflight]` (build completa); avvio manuale dopo il merge: verifica Apple, firma automatica con
  chiave API, upload, assegnazione al gruppo «Personale». Numero di build `1.<run_number>.<run_attempt>`.

Segreti Actions (solo nomi): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`. Il repository è pubblico: **mai**
chiavi, profili o certificati nel codice.

## Distribuzione

Commit con `[testflight]` sul ramo → build su TestFlight → Will aggiorna dall'app TestFlight. La versione di marketing è in
`project.yml` (`MARKETING_VERSION`).
