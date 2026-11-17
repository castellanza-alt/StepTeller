# NEAT — piano (stato vero del progetto)

Lo aggiorna solo il **Director**, a ogni unione in `main` e a ogni build. Prima stesura: 17 novembre 2026, ricostruita
da `CHANGELOG.md`, `STORE_CHECKLIST.md` e dalle chat precedenti (ora archiviate). Il Director la verifica al primo avvio.

## 1. Cos'è
NEAT («ogni passo conta») è l'app iPhone nativa (SwiftUI) nata dalla web app Step Teller: legge i passi da Apple Salute
(solo lettura) e dice quanti minuti di tappeto servono per l'obiettivo. Repo pubblico `castellanza-alt/StepTeller`,
cartella `ios/`; la radice è la web app su GitHub Pages e non si tocca. Bundle ID `it.castellanza.stepteller`.

## 2. Ultima build
| Versione | Build | Stato | Provata da William | Note |
|---|---|---|---|---|
| 1.1 | 1.97.1 | su TestFlight (28/10/2026) | **da confermare** | copia iCloud, Backup, promemoria, niente passi a mano |
| 1.0 | 1.88.1 | pubblicata sull'App Store il 26/10/2026 | sì | |

## 3. Cosa funziona (1.1 su `main`)
Home + Storico «Dan Dan Dan» giorno/notte, streak e Jolly ogni 15 giorni, taratura, widget, promemoria serale,
miglia/km, 10 lingue, introduzione al primo avvio, copia in iCloud e Backup manuale. Dettaglio in `CHANGELOG.md`.

## 4. Provato davvero sul telefono
| Build | Cosa ha visto William | Data |
|---|---|---|
| 1.88.1 (1.0) | versione pubblicata | 26/10/2026 |
| 1.97.1 (1.1) | da chiedere a William | — |

## 5. Aperto
| # | Cosa | Stato | Compito |
|---|---|---|---|
| 1 | 1.1: prova di William su TestFlight, ok ai testi italiani del Backup, conferma traduzioni | in attesa di William | — |
| 2 | 1.1: pagina privacy (`neat/privacy`) da aggiornare con la copia in iCloud prima dell'invio | da fare | da scrivere |
| 3 | 1.1: classificazione per età in App Store Connect (4+ o 9+) | in attesa di William | — |
| 4 | 1.1: invio ad Apple (Novità in 10 lingue, `RILASCIO.md`) | dopo 1–3 | da scrivere |
| 5 | 1.2: app per Apple Watch sul ramo `ia/1.2-watch` (601c235), provata solo sul Simulatore | non unita | da scrivere |
| 6 | Rami vecchi da riordinare (`ia/1.0.1-promemoria`, `ia/rilascio` con PR #26) | da verificare | — |

## 6. Dove si prova cosa
- **Linux / cloud:** `swift test` del core (`Sources/StepTellerCore`).
- **Mac mini:** Xcode, Simulatore, screenshot (`scripts/screenshots.sh`).
- **Telefono di William:** TestFlight, Salute vera, widget, notifiche, Apple Watch.

## 7. Documenti che restano validi
`ios/CLAUDE.md`, `RILASCIO.md` (numeri, registro, Novità), `CHANGELOG.md`, `STORE_CHECKLIST.md` (storico 1.0), `store/`, `localizzazione/`.
