# Note per chi subentra (ios/)

- Italiano con Will (non programma, lavora da telefono). Prima la conclusione, breve.
- Il modello di calcolo è in `Sources/StepTellerCore`; i valori golden dei test vengono dalla web app v4.0: non cambiarli
  senza motivo. Il tappeto (`TreadmillView`) è la foto del Technogym di Will (PNG senza sfondo) con il nastro animato sopra.
- Ora c'è un Mac (Mac mini M4, Xcode 27, repo in `~/Developer/StepTeller`). La distribuzione resta su GitHub Actions
  (`.github/workflows/ios-*.yml`); in locale si genera, compila e testa (da `ios/`, `.xcodeproj` e `build/` sono ignorati da git):
  - Generare il progetto: `xcodegen generate`
  - Compilare sul simulatore: `xcodebuild -project StepTeller.xcodeproj -scheme StepTeller -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
  - Testare il nucleo: `swift test`
  - Aprire in Xcode: `open StepTeller.xcodeproj`
- Repo pubblico: nessun segreto/profilo/chiave nel repo. Segreti solo `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`.
- Non toccare i file in radice (web app) né il repo `diario-alimentare` (briciola.).
- Streak, Jolly e statistiche sono funzioni pure in `StepTellerCore` (`StreakEngine`, `HistoryStats`, `GoalHistory`): si calcolano dai dati di Salute, non si salvano. Regole in `StreakEngine.swift`.
- Il merge su `main` pubblica anche su Pages: chiederlo a Will, una volta, dopo la sua prova.
- Salute: solo lettura passi, mai scrittura né rete. Il provider finto è solo `#if DEBUG`.

## Pubblicazione su TestFlight (dal Mac)

- Quando Will scrive "pubblica", fai tutto da solo con `bash scripts/pubblica.sh` (da `ios/`): test sul simulatore,
  numero di build +1 in `project.yml` (`CURRENT_PROJECT_VERSION`), Archive Release, upload su App Store Connect con
  `xcodebuild -exportArchive` (destination `upload`), attesa dell'elaborazione Apple e assegnazione al gruppo TestFlight
  «Personale» (`scripts/asc.py distribute`). Se l'app è cambiata, prima alza `MARKETING_VERSION` e aggiorna `CHANGELOG.md`.
- Prima di pubblicare i test devono passare: se falliscono (lo script si ferma da solo), fermati e spiega a Will il
  problema in parole semplici. Niente upload.
- Dopo un upload riuscito: commit (compreso il nuovo numero di build) e push sul ramo `ios-nativa`, con messaggio
  chiaro tipo `ios 0.5.5 (build 3): <cosa cambia>`. Senza `[testflight]`/`[apple]` nel messaggio, altrimenti riparte
  anche la pipeline di GitHub. Mai merge su `main` senza chiederlo a Will.
- Mai chiavi, certificati, profili o password nel repo (è pubblico). La chiave App Store Connect sta solo in
  `~/.appstoreconnect/`: `config` (`ASC_KEY_ID=…`, `ASC_ISSUER_ID=…`), `private_keys/AuthKey_<ID>.p8`, e `venv/` per asc.py.
  Il certificato di firma lo crea Xcode via API nel portachiavi del Mac. Lo step `certs` della pipeline GitHub revoca i
  certificati «Created via API»; se lo fa, al giro dopo Xcode ne crea uno nuovo.
- Alla fine scrivi a Will solo: versione pubblicata, cosa cambia, e "tra pochi minuti arriva su TestFlight".
