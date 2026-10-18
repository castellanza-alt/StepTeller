# Note per chi subentra (ios/)

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
- Salute: solo lettura passi, mai scrittura né rete. Il provider finto è solo `#if DEBUG`.
