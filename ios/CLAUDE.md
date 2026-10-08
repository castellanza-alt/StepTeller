# Note per chi subentra (ios/)

- Italiano con Will (non programma, lavora da telefono). Prima la conclusione, breve.
- Il modello di calcolo è in `Sources/StepTellerCore`; i valori golden dei test vengono dalla web app v4.0: non cambiarli
  senza motivo. Le coordinate del tappeto (`TreadmillView`) sono i path SVG originali.
- Nessun Mac: si compila e si distribuisce solo da GitHub Actions (`.github/workflows/ios-*.yml`). Linux può fare `swift test`.
- Repo pubblico: nessun segreto/profilo/chiave nel repo. Segreti solo `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`.
- Non toccare i file in radice (web app) né il repo `diario-alimentare` (briciola.).
- Il merge su `main` pubblica anche su Pages: chiederlo a Will, una volta, dopo la sua prova.
- Salute: solo lettura passi, mai scrittura né rete. Il provider finto è solo `#if DEBUG`.
