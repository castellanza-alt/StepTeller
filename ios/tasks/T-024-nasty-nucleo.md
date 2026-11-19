# T-024 NASTY: situazioni, scelta della battuta e catalogo nel nucleo
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026

## Perché
NASTY è la 1.3 (D-045). Progetto in `docs/design/T-022-nasty-progetto.md` (§2, §4, §6), regole in D-044. La grafica
arriva con T-023: qui si fa solo la logica, senza interfaccia, così non dipende dal Designer.

## Cosa fare (ramo `task/T-024-nasty-nucleo`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Apri la 1.3:** `MARKETING_VERSION` 1.3 e sezione «## 1.3 — in lavorazione» in cima al CHANGELOG (la 1.2 è
   «inviata ad Apple» e non si tocca; regole in `RILASCIO.md`).
2. **Catalogo** in `StepTellerCore`: modello (id, livello, situazione, testo, titolo facoltativo per le notifiche),
   lettura da JSON, e **controllo** (formato, versione, segnaposti ammessi `{passi} {obiettivo} {mancano} {minuti}
   {serie} {jolly} {percento}`, lunghezza massima, livelli e situazioni noti). Un file rifiutato non sostituisce mai
   quello buono. Il catalogo di bordo si genera da `docs/design/T-021-nasty/catalogo/catalogo-approvato.json` con uno
   script in `scripts/`, che produce anche il `battute.json` per il sito; un test verifica che siano allineati.
3. **Situazione** come funzione pura dai soli dati che l'app ha (passi, obiettivo, percentuale, minuti mancanti, ora,
   serie, Jolly, cambio di obiettivo, evento Jolly/serie), con le stesse situazioni del catalogo e soglie scritte
   nel codice e nei test.
4. **Scelta della battuta:** a caso dentro la situazione e il livello, senza ripetere le ultime 20 (memoria passata
   come valore), mai una battuta il cui segnaposto non ha valore; sotto i 50 passi solo battute senza `{passi}`
   (regola di William: mai «zero passi»). Numeri formattati come nel resto dell'app.
5. **Piano delle notifiche roast** come funzione pura: tra le 10 e le 20, orari non fissi, almeno 90 minuti tra due,
   numero secondo livello e manopola (NASTY 4–5, Piccante 1–2; Poche · Normali · Tante), nessuna dopo l'obiettivo
   raggiunto, preferenza per battute senza `{passi}`. Casualità con seme, così i test sono ripetibili.
6. Campi nuovi di impostazioni (livello della voce, frequenza) compatibili con iCloud e Backup vecchi.
7. Test per tutto, `swift test` verde su Linux e Mac, Debug e Release; riga nel CHANGELOG; revisione indipendente;
   PR verso `main`, non unirla.

## Non fare
Niente interfaccia, niente rete (lo scaricamento arriva con il compito dell'app), nessuna build TestFlight. Solo
italiano: nelle altre lingue i livelli Piccante e NASTY non sono disponibili (lo espone il nucleo come dato).
Non scrivere a William.

## Disco
Solo SSD; a fine turno niente acceso.

## Esito
**Fatto, 19/11/2026, Developer.** Ramo `task/T-024-nasty-nucleo`, PR verso `main` non unita. Solo nucleo: nessuna
interfaccia, nessuna rete. Vincoli `ore`/`evento` e catalogo per lingua decisi dal Director durante il compito
(D-046).

- **1.3 aperta:** `MARKETING_VERSION` 1.3, «## 1.3 — in lavorazione» in cima al CHANGELOG; la 1.2 non è toccata.
- **Catalogo per lingua** (`NastyCatalog`, `NastyLibrary` in `StepTellerCore`). Fonti in
  `docs/design/T-021-nasty/catalogo/`: `catalogo-approvato.json` (italiano), `catalogo-approvato.<lingua>.json` (le
  altre, quando arrivano) e `vincoli.json` (ore ed evento per id, uguali in ogni lingua). `scripts/battute.py` genera
  `Sources/StepTellerCore/NastyCatalog+Bordo.swift` e `neat/nasty/<lingua>/battute.json`; `--check` dice se vanno
  rigenerati, un test verifica che fonti, bordo e sito coincidano. Le notifiche «Titolo / testo» diventano `titolo` +
  `testo`. Quando cambia il catalogo si alza `EDIZIONE` nello script.
- **Controllo:** formato `neat-battute`, versione ≤ 1, edizione «AAAA-MM-GG» vera, lingua tra le 10 dell'app, id
  unici, livello (Piccante, NASTY) e situazione noti, ogni situazione con almeno una battuta, testo ≤ 12 parole e ≤ 90
  caratteri, titolo ≤ 4 parole e ≤ 30 caratteri, solo i segnaposti `{passi} {obiettivo} {mancano} {minuti} {serie}
  {jolly} {percento}`, `ore` ben formate, `evento` noto. Le altre lingue contro l'italiano: nessun id in più, e per
  ogni id stessi livello, situazione, segnaposti, presenza del titolo, ore ed evento; una battuta può mancare (lì non
  si dice, mai l'italiano al suo posto). Un file rifiutato o più vecchio non sostituisce quello buono; una lingua
  senza catalogo valido offre solo Normale (`levels(language:)`, `effective`).
- **Situazione** (`NastyMoment.of`), soglie: obiettivo raggiunto → «Quando ce la fai» (evento `record` se è il
  giorno migliore, `doppio` da 2× l'obiettivo); dal 50% → «A metà e quasi»; sotto il 50% «Pochi passi», più dalle
  11:00 «Mattina e pomeriggio» e dalle 18:00 «Sera» (Piccante: «Mattina, pomeriggio, sera»). Cuore, notifiche,
  obiettivo scelto/alzato/abbassato, Jolly usato/finito/guadagnato, serie persa (`{serie}` = serie appena persa),
  in corso, a rischio: dal motivo per cui NEAT parla.
- **Scelta** (`NastyPicker`): a caso tra le battute della situazione e del livello che rispettano ore ed evento e
  hanno tutti i numeri; un numero mancante o non sopra zero toglie la battuta; sotto i 50 passi nessuna battuta con
  `{passi}`; niente ripetizioni delle ultime 20 per livello (`NastyMemory`, solo sul telefono); se sono state viste
  tutte, quella vista da più tempo (nelle notifiche invece nessuna). Numeri con il formato passato dall'app
  (italiano «10.000» di serie).
- **Finestre orarie** (`vincoli.json`, ora locale, estremi compresi): «Sono le/Ore N» da N−1:30 a N:59 (N046, N049,
  N051, N052, N053, N055, N059, N137, P020, P021, P025, P054); «Mezzogiorno» 11:30–12:59 (N045, P019); «Ultima ora»
  19:00–19:59 (N063); «Mattina finita» 12:00–17:59 (N048); «Pomeriggio» 13:00–17:59 (N050); «Sera» 18:00–23:59
  (P022); fine giornata 20:00–23:59 (N060, N064, N065, N066, P024).
- **Notifiche roast** (`RoastPlan`): tra le 10:00 e le 20:00 dell'orologio (anche nei giorni del cambio d'ora),
  almeno 90 minuti tra due e dopo l'ultima consegnata; quante al giorno: NASTY 2–3 · 4–5 · 6–7, Piccante 1 · 1–2 ·
  2–3 (Poche · Normali · Tante); orari e numero dal seme del giorno (stessi orari se si ripianifica), battute di
  «Notifiche» con l'ora di consegna, di preferenza senza `{passi}`, mai due uguali (piuttosto meno notifiche);
  nessuna con obiettivo raggiunto. Identificativi `stepteller.roast.<giorno>.<HHMM>`.
- **Impostazioni:** `voiceLevel` (normale di serie) e `roastFrequency` (normali di serie) in `StepsStore`, in iCloud
  e nel Backup; i file vecchi senza i campi vanno bene e un valore sconosciuto viene ignorato.
- **Verifiche:** `swift test` 146 test verdi (36 nuovi), build Debug e Release ok, revisione indipendente: corretti
  il cambio d'ora e le notifiche ripetute sotto i 50 passi.
- **Per il compito dell'app:** togliere le notifiche `stepteller.roast.` già programmate quando si raggiunge
  l'obiettivo; passare a `NastyPicker`/`RoastPlan` il formato dei numeri della lingua (`LocalFormat.integer`) e la
  localizzazione risolta dell'app a `NastyLibrary.catalog(language:)`.
