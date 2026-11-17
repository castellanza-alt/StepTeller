# NEAT — piano (stato vero del progetto)

Lo aggiorna solo il **Director**, a ogni unione in `main` e a ogni build. Prima stesura: 17 novembre 2026, ricostruita
da `CHANGELOG.md`, `STORE_CHECKLIST.md` e dalle chat precedenti (ora archiviate). Verificata dal Director il 17/11/2026
(git, PR, CI, pagine `neat/`): corretti i punti 2, 3 e 6 della sezione 5, aggiunti i compiti T-001…T-003.

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
| 1 | 1.1: prova di William su TestFlight (promemoria, Backup, copia in iCloud, Home senza passi a mano) | in attesa di William | T-001 prepara l'elenco |
| 2 | 1.1: percorsi di iOS per spegnere e cancellare la copia in iCloud scritti nella privacy, da verificare sul telefono | in attesa di William | T-001 |
| 3 | 1.1: classificazione per età. La 1.0 è 4+ (William, 21/10: «no» a salute e benessere, che dava 9+); da confermare per la 1.1 | in attesa di William | — |
| 4 | 1.1: invio ad Apple (Novità in 10 lingue già pronte, `RILASCIO.md`) | dopo 1–3, Director | — |
| 5 | 1.2: app per Apple Watch, ramo `ia/1.2-watch` (601c235, 24/10) partito da `74fb221`, prima della 1.1: in conflitto con `main`, provata solo sul Simulatore. Non va in `main` prima che la 1.1 sia pubblicata (`main` = 1.1 per le build) | da riportare su `main` | T-002, T-003 |
| 6 | Rami vecchi: `ia/1.0.1-promemoria` è identico a `main` (105eac8), `ia/rilascio` è tutto in `main` (PR #26 chiusa): si possono cancellare | in attesa dell'ok di William | — |

Fatto e tolto dall'elenco: la pagina privacy (`neat/privacy`, IT+EN) parla già della copia in iCloud, online dal merge
della 1.1 (28/10, `8d5ccfb`).

## 5b. Compiti
| Compito | Chi | Ramo | Stato |
|---|---|---|---|
| T-001 Collaudo della 1.1 sul Simulatore | QA | `qa/T-001` | assegnato 17/11 |
| T-002 Apple Watch riportato su `main` aggiornato | Developer | `task/T-002-watch` | assegnato 17/11 |
| T-003 Specifica grafica dell'Apple Watch | Designer | `design/T-003-watch` | assegnato 17/11 |

## 6. Dove si prova cosa
- **Linux / cloud:** `swift test` del core (`Sources/StepTellerCore`).
- **Mac mini:** Xcode, Simulatore, screenshot (`scripts/screenshots.sh`).
- **Telefono di William:** TestFlight, Salute vera, widget, notifiche, Apple Watch.

## 6b. Team
Tre sessioni, ognuna nel suo worktree: Designer `~/Developer/neat-design`, Developer `~/Developer/neat-dev`,
QA `~/Developer/neat-qa`. Parlano solo con il Director. Modello: Opus 5.5 o più economico, mai Fable (come briciola, D-046 là).

## 7. Documenti che restano validi
`ios/CLAUDE.md`, `RILASCIO.md` (numeri, registro, Novità), `CHANGELOG.md`, `STORE_CHECKLIST.md` (storico 1.0), `store/`, `localizzazione/`.
