# Step Teller — app iOS nativa

Versione nativa (SwiftUI) di Step Teller, con i passi di oggi letti da Apple Salute.
La web app resta in radice al repository (non toccata).

## Struttura

| Percorso | Contenuto |
|---|---|
| `Sources/StepTellerCore/` | Nucleo (solo Foundation): cadenza e taratura, calcolo, formato italiano, logica sorgente passi |
| `Tests/StepTellerCoreTests/` | Test del nucleo (valori golden della web app v4.0) — `swift test` anche su Linux |
| `App/` | App SwiftUI: `ContentView`, `StepsStore`, `HealthKitStepsProvider`, tappeto, orb, pannello in vetro, cursore |
| `project.yml` | Progetto XcodeGen (nessun `.xcodeproj` versionato) |
| `scripts/` | `asc.py` (API App Store Connect), `screenshots.sh`, `make_icon.py`, `select_xcode.sh` |

Bundle ID `it.castellanza.stepteller` · Team `5E426PLFWN` · iOS 17+.

## Dove si aggiungono i punti di taratura

`Sources/StepTellerCore/CadenceModel.swift`, enum `Calibration` (un solo posto). Esempio per la camminata:
`public static let walk = [CalibrationPoint(speed: 5.0, cadence: 112.0)]`. Con 1 punto il rapporto è costante,
con 2 o più è interpolato e costante oltre gli estremi. Aggiornare poi i test golden se cambiano.

## Salute (HealthKit)

Solo lettura di `stepCount`, `HKStatisticsQuery` `.cumulativeSum` da mezzanotte (deduplica iPhone/Watch),
`HKObserverQuery` in primo piano. Se non arrivano dati (vuoto, negato o errore: iOS non li distingue) l'app mostra
0 passi, fonte «manuale» e l'avviso con il pulsante per le Impostazioni. I passi non vengono mai salvati.
Il fornitore finto (`DebugStepsProvider`) esiste **solo in Debug** per gli screenshot.

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
