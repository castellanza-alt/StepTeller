# NEAT (ex Step Teller) — app iOS nativa

Versione nativa (SwiftUI) di Step Teller, sul telefono col nome **NEAT**, con i passi di oggi letti da Apple Salute.
La web app resta in radice al repository (non toccata).

## Struttura

| Percorso | Contenuto |
|---|---|
| `Sources/StepTellerCore/` | Nucleo (solo Foundation): cadenza e taratura, calcolo, formato e date italiane (test golden), testi del promemoria come dati, logica sorgente passi |
| `Tests/StepTellerCoreTests/` | Test del nucleo (valori golden della web app v4.0) — `swift test` anche su Linux |
| `App/` | App SwiftUI: `RootView` (tema e navigazione), `TopBar`, `Home/` (Home e cursore sulla strada), `History/` (Storico), `StepsStore`, `HealthKitStepsProvider` |
| `App/Design/` | Stile «Dan Dan Dan»: **token** (`MangaTokens.swift`, unico posto per colori, font, misure), testo Anton, trasformazioni, forme, effetti |
| `App/Fonts/` | `Anton-Regular.ttf` (SIL OFL, licenza accanto) |
| `project.yml` | Progetto XcodeGen (nessun `.xcodeproj` versionato) |
| `scripts/` | `asc.py` e `asc_store.py` (API App Store Connect: TestFlight e scheda dello store), `store_metadata.py` e `store_screenshots.py` (dati della scheda), `screenshots.sh`, `cataloghi.py` (String Catalog dal foglio), `check_icon.py`, `select_xcode.sh` |
| `store/` | Scheda App Store: testi per lingua (`metadata.json`, generato dal foglio), screenshot JPEG, note per il revisore, guida ai passi a mano |
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
(o 2–10 mph) lineare sulla lunghezza dell'arco. Debug: `-stepteller.themeMode day|night|system|clock`, `-stepteller.debugSteps -1`
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
- **Unità di misura**: con il paese del telefono negli USA o nel Regno Unito (`Locale.current.measurementSystem` `.us`
  o `.uk`) distanze in miglia e velocità in mph, altrimenti km e km/h; Impostazioni → «Unità di misura» sceglie
  Automatiche (predefinito), Chilometri o Miglia. **Dentro tutto resta in km/h e km** (calcoli, taratura, App Group,
  test golden): le miglia sono solo visualizzazione (`DistanceUnit` nel nucleo, `Shared/Units.swift`). Il cursore in
  miglia va da 2 a 10 mph a scatti di 0,5 sulla stessa strada; cambiando unità la velocità salvata passa allo scatto
  più vicino (4 km/h → 2,5 mph). Testi in miglia: righe del foglio con «mi» nell'ID (es. `home.minutes.mi`,
  `n.body.mi`); nel codice `unit.pick("home.minutes.km", "home.minutes.mi")`. L'unità arriva al widget via App Group.
  Debug: `-stepteller.units miles|kilometers|automatic`.
- **Promemoria**: il nucleo (`ReminderPlanner`) dà il caso e i numeri (`ReminderMessage`), il testo lo compone
  `ReminderScheduler` con il catalogo.
- **Testi lunghi**: le schede dello Storico si rimpiccioliscono fino al 60% se una traduzione non entra
  (`AntonText(…, minScale:)`); in italiano non cambia nulla.
- **Screenshot per lingua**: `scripts/screenshots.sh APP USCITA [lingua] [giorno]` (es. `… build/shots-de de`;
  `giorno` = solo tema giorno). Un altro paese per la stessa lingua con `NEAT_LOCALE` (es. `NEAT_LOCALE=en_GB … en`:
  inglese britannico, in miglia).

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
Obiettivo, taratura, velocità del cursore, unità di misura, serie e Jolly arrivano dall'app via App Group (`Shared/SharedStore.swift`);
i minuti usano lo stesso modello tarato dell'app. Tocco → `stepteller://oggi`. In Debug `WidgetPreviewScreen` mostra i widget
per gli screenshot (`-stepteller.debugWidget 1`).

## Animazione di apertura

`App/SplashView.swift`, versione «Pestone» scelta da Will (ottobre 2026): sul nero dell'icona la scarpa cade e pesta
(0,24 s: stella rossa al 65% dietro la scarpa, linee cinetiche, `sensoryFeedback` leggero), «NEAT» (`GlyphText`)
sbatte giù con l'ombra rossa, da 0,86 s un taglio rosso a −14° sale e scopre la Home. Durata 1,2 s, `KeyframeTimeline`
(iOS 17) letto da un `TimelineView`. Arte: `rosso.svg` e `bianco.svg` dell'icona copiati nel catalogo
(`SplashSole`, `SplashShoe`, vettoriali), rasterizzati una volta fuori dal thread principale, già all'avvio dell'app. Colori `MangaPalette.icon*`,
misure `Manga.splash*` in `MangaTokens.swift`.

- Sta sopra `RootView` (overlay in `StepTellerApp`): Salute, storico e introduzione partono sotto come prima.
- Solo all'apertura a freddo (lo stato vive quanto il processo); il tempo scorre solo in primo piano. Uscendo
  dall'app durante l'animazione questa si chiude: al ritorno c'è la Home.
- Schermata di avvio fissa: `UILaunchScreen` → `UIColorName` `LaunchBackground` (#0C0C0C, il fondo dell'icona), uguale
  al primo fotogramma. Il tempo parte dopo qualche fotogramma regolare (al massimo 0,6 s di nero): i primi fotogrammi
  disegnano la Home sotto. Un fotogramma lento ferma l'animazione invece di farle saltare un pezzo.
- Un tocco la salta (dissolvenza di 0,15 s). Con «Riduci movimento»: dissolvenza dell'immagine finale, 0,7 s.
- Debug: `-stepteller.skipSplash 1` la toglie, `0` la forza; qualunque opzione `-stepteller.debug…` la toglie da sola
  (screenshot invariati). `-stepteller.splashSlow 3` la rallenta tre volte (video).

## Icona

`App/AppIcon.icon` (Icon Composer, Liquid Glass): fondo nero pieno, livello «Suola» (`rosso.svg`, vetro con riflessi) e
livello «Scarpa» (`bianco.svg`), vettoriali ricavati dal disegno scelto da Will (ottobre 2026). Varianti scura, colorata e
trasparente generate da iOS. Anteprima da terminale con `ictool` (dentro Icon Composer.app). `scripts/check_icon.py` la verifica in CI.

## CI

- `.github/workflows/ios-verifica.yml` — su PR e push a `main` quando cambia `ios/**`: `swift test` (Linux),
  build simulatore + test + screenshot chiaro/scuro (artefatto `screenshot-simulatore`).
- `.github/workflows/ios-testflight.yml` — con un push su `main` il cui messaggio contiene `[apple]` (solo preparazione Apple) o `[testflight]` (build completa); avvio manuale dopo il merge: verifica Apple, firma automatica con
  chiave API, upload, assegnazione al gruppo «Personale». Numero di build `1.<run_number>.<run_attempt>`.

- `.github/workflows/ios-store.yml` — scheda App Store via API con un push su `main` il cui messaggio
  contiene `[store-prova]` (solo lettura: cosa cambierebbe), `[store]` (applica e rilegge) o `[store-invio]` (build 1.0 in
  revisione, solo dopo l'ok di Will). Testi, screenshot e istruzioni in `store/` (`store/README.md`).

Segreti Actions (solo nomi): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`; per la scheda dello store anche
`ASC_REVIEW_FIRST_NAME`, `ASC_REVIEW_LAST_NAME`, `ASC_REVIEW_PHONE`, `ASC_REVIEW_EMAIL`, `ASC_COPYRIGHT`. Il repository è pubblico: **mai**
chiavi, profili o certificati nel codice.

## Distribuzione

Commit con `[testflight]` sul ramo → build su TestFlight → Will aggiorna dall'app TestFlight. La versione di marketing è in
`project.yml` (`MARKETING_VERSION`).
