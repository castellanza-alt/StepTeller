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
| 1.2 | 1.162.1 | inviata ad Apple il 19/11/2026 (10 lingue, Novità 1.2, testi nei riquadri) | no (invio subito per scelta di William) |
| 1.2 | 1.155.2 | su TestFlight dal 18/11/2026 (icona di Natale nuova, Home fino ai bordi, T-019) | no |
| 1.2 | 1.147.2 | su TestFlight dal 18/11/2026 (Natale rifatto, notifiche e pop-up; testi nuovi solo in italiano) | **sì, 18/11** («si va»; icona da rifare, striscia bianca in alto → T-019) |
| 1.1 | 1.97.1 | pubblicata il 18/11/2026 (approvata e uscita da sola nella notte) | **sì, 17/11** («funziona tutto») | copia iCloud, Backup, promemoria, niente passi a mano |
| 1.0 | 1.88.1 | pubblicata sull'App Store il 26/10/2026 | sì | |

## 3. Cosa funziona (1.1 su `main`)
Home + Storico «Dan Dan Dan» giorno/notte, streak e Jolly ogni 15 giorni, taratura, widget, promemoria serale,
miglia/km, 10 lingue, introduzione al primo avvio, copia in iCloud e Backup manuale. Dettaglio in `CHANGELOG.md`.

## 4. Provato davvero sul telefono
| Build | Cosa ha visto William | Data |
|---|---|---|
| 1.88.1 (1.0) | versione pubblicata | 26/10/2026 |
| 1.97.1 (1.1) | «c'è scritto 1.1 e funziona tutto» | 17/11/2026 |

## 5. Aperto
| # | Cosa | Stato | Compito |
|---|---|---|---|
| 4 | 1.1: invio ad Apple (Novità in 10 lingue già pronte, `RILASCIO.md`) | fatto: inviata il 17/11, approvata e pubblicata il 18/11 (rilascio automatico, non manuale: impostazione della scheda «dopo l'approvazione»); tag v1.1 su 8d5ccfb | Director |
| 7 | 1.2 «Natale»: notifica a obiettivo raggiunto, Jolly guadagnato/usato (notifica e pop-up), tema stagionale di Natale con icona, disattivabile (D-036) | notifiche e pop-up approvati da William (18/11), testi italiani da approvare; **Natale bocciato il 18/11 e da rifare** (D-040: stivale, neve, slitta, Jolly regalo, icona, illustrazioni Higgsfield), tutto insieme: invio entro il 1° dicembre a rischio | T-004…T-006, T-014, T-015 |
| 8 | Versione «NASTY» che insulta l'utente, alla Carrot Weather | impostazione decisa (D-044): NEAT personaggio, 3 livelli, tono da roast; T-008 da riscrivere | T-008 |
| 5 | 1.3 (era 1.2, D-036): app per Apple Watch, ramo `ia/1.2-watch` (601c235, 24/10) partito da `74fb221`, prima della 1.1: in conflitto con `main`, provata solo sul Simulatore. Non va in `main` prima che la 1.1 sia pubblicata (`main` = 1.1 per le build) | da riportare su `main` | T-002, T-003 |

Fatto e tolto dall'elenco: la pagina privacy (`neat/privacy`, IT+EN) parla già della copia in iCloud, online dal merge
della 1.1 (28/10, `8d5ccfb`). Rami `ia/1.0.1-promemoria` e `ia/rilascio`, già tutti in `main`, cancellati il 17/11 (ok di William).

## 5b. Compiti
| Compito | Chi | Ramo | Stato |
|---|---|---|---|
| T-001 Collaudo della 1.1 sul Simulatore | QA | `qa/T-001` | fatto, unito 17/11 (#29): nessun difetto bloccante, rapporto in `comms/qa/T-001.md` |
| T-002 Apple Watch riportato su `main` aggiornato | Developer | `task/T-002-watch` | PR #28 in bozza, non si unisce prima della 1.1 pubblicata |
| T-003 Specifica grafica dell'Apple Watch | Designer | `design/T-003-watch` | fatto, unito 17/11 (#27): `docs/design/T-003-watch.md` |
| T-004 Tema stagionale di Natale (specifica e icona) | Designer | `design/T-004-natale` | fatto, unito 17/11 (#30) |
| T-005 Pop-up e testi di obiettivo e Jolly (specifica) | Designer | `design/T-005-popup-jolly` | fatto, unito 17/11 (#31): 22 testi italiani da far approvare a William |
| T-006 Notifiche e pop-up di obiettivo e Jolly | Developer | `task/T-006-notifiche` | fatto, unito 17/11 (#34), apre la 1.2 |
| T-007 Collaudo dell'Apple Watch (PR #28) | QA | `qa/T-007` | fatto, unito 17/11 (#35): funziona, complicazioni non provate |
| T-009 Scheda dello store dopo una versione pubblicata | Developer | `task/T-009-scheda` | fatto, unito 17/11 (#33) |
| T-010 Tema di Natale nell'app | Developer | `task/T-010-natale` | fatto, unito 17/11 (#36) |
| T-011 Pop-up e notifiche nella forma finale | Developer | `task/T-011-popup` | fatto, unito 17/11 (#37); testi italiani da approvare da William |
| T-012 Collaudo della 1.2 sul Simulatore | QA | `qa/T-012` | fatto, unito 17/11 (#38): 3 difetti → T-013 |
| T-013 Correzioni dal collaudo della 1.2 | Developer | `task/T-013-correzioni` | fatto, unito 17/11 (#39) |
| T-014 Glossario e traduzioni in bozza della 1.2 | Traduttore | `lang/T-014-traduzioni-1.2` | PR #41 aperta, in attesa dell'ok di William sui testi italiani |
| T-015 Natale rifatto (specifica, illustrazioni Higgsfield, tela Design) | Designer | `design/T-015-natale` | fatto, unito 18/11 (#42), approvato da William («Mi piace»); 16,5 crediti Higgsfield su 39 |
| T-016 Natale rifatto nell'app, Jolly regalo, 10 km/h (D-042) | Developer | `task/T-016-natale` | fatto, unito 18/11 (#43) |
| T-017 Collaudo del Natale rifatto e dei 10 km/h | QA | `qa/T-017` | fatto, unito 18/11 (#44): icona ingrandita (bloccante) e 6 minori → T-018 |
| T-018 Correzioni dal collaudo del Natale | Developer, Designer (regalo, icona SVG) | `task/T-018-correzioni`, `design/T-018-*` | fatto, unito 18/11 (#45, #46, #47) |
| T-019 Icona di Natale più chiara (3 proposte) e illustrazione fino in cima | Designer, Developer | `design/T-019-icona`, `task/T-019-bordo` | fatto 18/11: bordo #48, icona scelta da William #49 |
| T-020 Nessuna parola fuori dai riquadri, in tutte le lingue | Developer | `task/T-020-riquadri` | fatto 19/11 (#50) |
| T-021 NASTY: carattere di NEAT e catalogo delle battute (D-044) | Director | `docs/design/T-021-nasty/catalogo/` | fatto 19/11: 196 battute approvate da William |
| T-022 NASTY: progetto dell'app prima del codice | Director | `docs/design/T-022-nasty-progetto.md` | approvato da William 19/11 (D-045) |
| T-023 NASTY: il cuore, il fumetto e le schermate nuove | Designer | `design/T-023-nasty` | approvato da William 19/11 (cuori, animazioni), #52 |
| T-024 NASTY: situazioni, scelta della battuta e catalogo nel nucleo | Developer | `task/T-024-nasty-nucleo` | fatto 19/11 (#51) |
| T-025 NASTY: controllo delle battute nelle 9 lingue (riscritte da ChatGPT) | Traduttore | `lang/T-025-nasty` | fatto 19/11 (#53): 73 righe corrette; resa comica non giudicata da madrelingua |
| T-026 NASTY (1.3): privacy, store e testi dell'interfaccia | Director | `docs/design/T-026-nasty-testi.md` | approvato da William 19/11 |
| T-027 NASTY: l'interfaccia (cuore, fumetto, voce, notifiche, catalogo dal sito) | Developer | `task/T-027-nasty-app` | fatto 19/11 (#56); privacy nuova nella #57, da unire alla pubblicazione della 1.3 |
| T-028 NASTY (1.3): testi dell'interfaccia, privacy e store nelle lingue | Traduttore | `lang/T-028-nasty-testi` | fatto 19/11 (#54) |
| T-029 Collaudo della 1.3 (voce di NEAT) | QA | `qa/T-029` | assegnato 19/11 |
| T-030 Screenshot dello store per la 1.3 | Designer | `design/T-030-screenshot` | assegnato 19/11 |
| T-031 Correzioni dal collaudo della 1.3 | Developer | `task/T-031-correzioni` | assegnato 19/11 |
| T-008 Voce «NASTY»: carattere e testi italiani | Designer | `design/T-008-nasty` | fatto, unito 17/11 (#32): William sceglie il personaggio e approva i testi |

## 6. Dove si prova cosa
- **Linux / cloud:** `swift test` del core (`Sources/StepTellerCore`).
- **Mac mini:** Xcode, Simulatore, screenshot (`scripts/screenshots.sh`).
- **Telefono di William:** TestFlight, Salute vera, widget, notifiche, Apple Watch.

## 6b. Team
Tre sessioni, ognuna nel suo worktree: Designer `~/Developer/neat-design`, Developer `~/Developer/neat-dev`,
QA `~/Developer/neat-qa`. Parlano solo con il Director. Modello: Opus 5.5 o più economico, mai Fable (come briciola, D-046 là).

## 7. Documenti che restano validi
`ios/CLAUDE.md`, `RILASCIO.md` (numeri, registro, Novità), `CHANGELOG.md`, `STORE_CHECKLIST.md` (storico 1.0), `store/`, `localizzazione/`.
