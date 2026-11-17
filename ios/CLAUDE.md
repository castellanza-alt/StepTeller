# Note per chi subentra (ios/)

## Team di agenti (dal 17/11/2026) — vale prima delle note sotto
Quattro ruoli come in briciola: **Director** (unico che parla con Will, scrive i compiti, decide le questioni
tecniche, unisce in `main`, chiede le build), **Designer**, **Developer**, **QA**. Memoria del team, da leggere per
prima: `docs/PIANO.md` (stato vero), `docs/DECISIONI.md` (D-001…), `comms/feedback.md` (giudizi di Will), `tasks/`
(un file per compito, con Esito), `comms/qa/` (collaudi), `docs/design/` (specifiche). Dove questa sezione e
`docs/DECISIONI.md` (D-030…D-035) contrastano con il resto, valgono loro: rami `task/` `design/` `qa/`, nessuno unisce
tranne il Director, build solo da `main`. «Chat di coordinamento» in `RILASCIO.md` = Director.

## Note
- Italiano con Will (non programma, lavora da telefono). Prima la conclusione, breve.
- Il modello di calcolo è in `Sources/StepTellerCore`; i valori golden dei test vengono dalla web app v4.0: non cambiarli
  senza motivo. L'interfaccia segue il handoff «Dan Dan Dan» (Home + Storico, giorno/notte): token in `App/Design/MangaTokens.swift`,
  niente colori scritti a mano nelle viste. Jolly ogni 15 giorni (non 14 come nel handoff), minuti dal modello tarato.
- La distribuzione passa da GitHub Actions (`.github/workflows/ios-*.yml`). Da ottobre 2026 c'è anche un Mac con Xcode e simulatori:
  build e screenshot si possono fare in locale. Linux può fare `swift test`.
- Repo pubblico: nessun segreto/profilo/chiave nel repo. Segreti solo `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`.
- Non toccare i file in radice (web app) né il repo `diario-alimentare` (briciola.).
- Streak, Jolly e statistiche sono funzioni pure in `StepTellerCore` (`StreakEngine`, `HistoryStats`, `GoalHistory`): si calcolano dai dati di Salute, non si salvano. Regole in `StreakEngine.swift`.
- Il merge su `main` pubblica anche su Pages: chiederlo a Will, una volta, dopo la sua prova.
- Versioni e registro: `RILASCIO.md`. Ogni PR che tocca il codice aggiunge la sua riga alla sezione in cima di
  `CHANGELOG.md`, che deve essere «in lavorazione» e uguale a `MARKETING_VERSION`; se è chiusa, si apre la versione
  successiva nella stessa PR. La CI (`scripts/registro.py`) rifiuta le PR senza riga. Novità dello store in 10 lingue
  nel foglio `localizzazione/NEAT_novita.xlsx`, italiano approvato da Will prima di tradurre.
- Salute: solo lettura passi, mai scrittura né rete. Il provider finto è solo `#if DEBUG`.
