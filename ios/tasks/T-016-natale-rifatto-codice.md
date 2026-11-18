# T-016 Natale rifatto nell'app (stivale, neve, slitta, Jolly regalo, icona)
**Assegnato a:** Developer **Base:** `main` aggiornato (1aa1c1d) **Stato:** assegnato 18/11/2026 — **urgente**: PR entro
il 24/11, la 1.2 va inviata il prima possibile (obiettivo 1° dicembre, D-040)

## Perché
William ha bocciato il primo Natale (T-004/T-010) e ha approvato il nuovo il 18/11 («Mi piace» sulla tela del Designer).
Regole in D-040 e D-037; la specifica è `ios/docs/design/T-015-natale.md` (sostituisce T-004), asset in
`ios/docs/design/T-015-natale/`.

## Cosa fare (ramo `task/T-016-natale`, worktree `~/Developer/neat-dev`)
1. **Togli le decorazioni di T-010** che la specifica elimina: neve animata (`SnowLayer`), luci (`RoadLights`),
   cappelli (`SeasonAccessory` e simili) in Home, Storico, festa, splash e widget, e la vecchia icona di Natale.
   Resta il meccanismo: `Season`, `SeasonalTheme`, interruttore «Temi stagionali», cambio icona con l'avviso di iOS.
2. **Home di Natale** come da specifica §2: illustrazioni giorno/notte e gamba con lo stivale nella stessa
   `ParallaxLeg`, stessa strada e stesso cursore; «Riduci movimento» come oggi.
3. **Slitta al posto del pomello** (§3): William ha approvato la tela così com'è. Il Director però teme che a misura di
   pomello sia poco leggibile: costruiscila in modo che tornare al pomello sia un cambio di una riga, e allega alla PR
   gli screenshot del Simulatore della slitta a grandezza vera su iPhone piccolo e grande, giorno e notte.
4. **Jolly regalo** (§4, D-040): +1 Jolly alla prima apertura dell'app dal 25/12 00:00 (ora locale) al 6/1 compreso,
   una volta per stagione, ogni anno; indipendente dall'interruttore dei temi. Il fatto «regalo della stagione AAAA
   ricevuto» va salvato (App Group, copia iCloud, Backup: campo nuovo, non rinominare quelli esistenti) così una
   reinstallazione non lo ripete e un ripristino non lo perde. Il Jolly in più deve entrare nel conteggio di
   `StreakEngine` in modo coerente (nel nucleo, con test: regalo prima/dopo la vigilia, il 6/1 e il 7/1, due aperture,
   reinstallazione con e senza iCloud, cambio di fuso, Jolly regalo usato per salvare la serie). Spiega nella PR come
   l'hai integrato. Pop-up «JOLLY IN REGALO!» come da specifica, nella coda dei pop-up di T-011 (ordine nella PR).
   Debug: un argomento per simulare la data.
5. **Icona di Natale** nuova (`T-015-natale/AppIconNatale.icon/`) al posto della vecchia.
6. Testi: i nuovi in italiano dalla specifica, nel catalogo con chiavi nuove, italiano in tutte le lingue (le
   traduzioni le fa il Traduttore dopo l'ok di William); togli le chiavi non più usate.
7. Riga nel CHANGELOG sotto «## 1.2 — in lavorazione».
8. Verifica: `swift test`, compilazione Simulatore Debug e Release, prova con la data simulata (1/12, 24/12 23:59,
   25/12, 6/1, 7/1) e con l'interruttore spento; peso dell'app prima/dopo; revisione indipendente del diff con un
   subagente; PR verso `main` (non bozza), non unirla.

## Aggiunta del 18/11 (D-042, dopo gli screenshot della PR #43)
9. **Slitta un filo più grande** (circa +30–40%, a tuo giudizio guardando gli screenshot), stessa area di tocco o più
   grande, senza coprire «MINUTI MANCANTI», i minuti e i km.
10. **Velocità massima 10 km/h** in tutta l'app (miglia: 6 mph): cursore, strada, nucleo (`SpeedTrack.maxSpeed` e
    dipendenti), test; le velocità salvate più alte vengono riportate a 10. Riga nel CHANGELOG. Nuovi screenshot
    della slitta (SE e 17 Pro Max, giorno e notte, a 5,5 e 10 km/h) nella stessa PR.

## Riuscita
Home natalizia uguale alla tela, nessun resto dei cappellini, Jolly regalo dato una volta sola e mai perso, CI verde,
screenshot nella PR, elenco di cosa si vede solo sul telefono.

## Non fare
Non unire, nessuna build TestFlight, nessun tag `[testflight]`/`[apple]`/`[store]`, nessuna chiave. Salute solo lettura,
niente rete. Nessuna spesa (Higgsfield è del Designer). Non toccare la PR #28 né la radice del repo. Non scrivere a
William.

## Esito
**18/11/2026, Developer.** Fatto sul ramo `task/T-016-natale`, PR https://github.com/castellanza-alt/StepTeller/pull/43 verso `main`, non unita.
- **Tolto il Natale di T-010:**
  - cappelli in Home, Storico, festa, pop-up Jolly e splash;
  - neve che cade, luci, neve ferma in Storico e widget;
  - `SeasonDecor.swift`, `SeasonPalette`, l'imageset `SplashHat` e la vecchia icona.
  
  Restano `Season`, `SeasonalTheme`, l'interruttore e `SeasonIcon`. Le scintille di festa e pop-up tornano rosso e nero.
- **Home di Natale:**
  - `SeasonLook` dà illustrazione e gamba giorno/notte, e `ParallaxLeg` riceve solo il nome dell'immagine;
  - la slitta (`RoadSpeedSlider`, `.sleigh("Slitta")`) segue la direzione della strada (`SpeedTrack.direction` e `pose`, nel nucleo con test);
  - per tornare al pomello basta una riga in `SeasonLook.of`: `slider: .knob`.
- **Jolly regalo:**
  - `JollyGift` nel nucleo: finestra 25/12–6/1 in ora locale, stagione = anno del dicembre, registro `{stagione: giorno}`, unione in cui vince il giorno più vecchio;
  - `StreakEngine.compute(gifts:)` aggiunge 1 Jolly all'inizio del giorno di ricezione, prima di giudicarlo; i regali precedenti all'inizio del conteggio o nel futuro non contano;
  - salvato in UserDefaults (chiave nuova, in iCloud con unione), App Group e Backup (`jollyGifts`);
  - dopo una reinstallazione aspetta la prima sincronizzazione di iCloud, al massimo 15 s;
  - pop-up primo nella coda: regalo → usato → guadagnato → festa.
- **Debug:** `-stepteller.debugNow AAAA-MM-GGTHH:MM` muove tema e regalo. In Debug il registro sta in una chiave a parte, mai in iCloud.
- **Test:** 112 test del nucleo verdi (21 nuovi tra regalo e slitta); compilazione Simulatore Debug e Release ok.
- **Simulatore** (iPhone SE e 17 Pro Max), con le date indicate:
  - 1/12 solo tema;
  - 24/12 23:59 niente regalo;
  - 25/12 pop-up con 4 Jolly;
  - seconda apertura niente;
  - 6/1 pop-up;
  - 7/1 app normale;
  - interruttore spento: pop-up senza tema.
  
  Screenshot in `tasks/T-016/` e `T-016-*.png` nelle note condivise.
- **Peso dell'app** (Release per Simulatore, non assottigliata): da 31,6 a 33,5 MB (+1,9 MB, tutto in `Assets.car`).
- **Revisione indipendente:** corretti i punti trovati:
  - la riga del CHANGELOG mancante;
  - la data simulata che finiva nei dati veri e in iCloud;
  - il pop-up ripetuto se iCloud arriva tardi dopo una reinstallazione;
  - l'ordine nella coda.
- **Da decidere (Director o Designer):**
  - da 13 a 16 km/h la slitta copre la riga «≈ 8,5 KM» sotto i minuti;
  - a 3–4 km/h esce di ≈ 6 pt dal bordo sinistro;
  - la scia resta a sinistra anche quando la slitta va verso sinistra (come da specifica).
- **Scostamento dalla specifica:** con la slitta specchiata il valore sta a sinistra di tutta la slitta (`p.x − 64,4 − 8`), non a `p.x − 27,6 − 8` dove la coprirebbe.
- **Limiti:**
  - il regalo arriva solo dopo una lettura vera di Salute (senza Salute non c'è serie da salvare);
  - senza iCloud né Backup una reinstallazione lo ridà, ma un Backup importato poi lo riporta a uno.
- **Solo sul telefono:**
  - parallasse con i sensori;
  - cambio dell'icona con l'avviso di iOS;
  - aspetto dell'icona chiara, scura e tinta;
  - sincronizzazione iCloud dopo una reinstallazione;
  - tocco e trascinamento della slitta.

**18/11/2026, Developer, punti 9 e 10 (D-042)**, stessa PR #43:
- **Slitta +35%** (`sleighScale` in `RoadSpeedSlider`), area di tocco invariata (20 pt dalla strada).
  - Con la slitta il blocco «minuti mancanti» sale di 46 pt (`SeasonLook.Slider.minutesLift`, 0 con il pomello: tornare al pomello resta una riga). Così a 10 km/h la slitta non copre «MINUTI MANCANTI», i minuti e i km.
  - L'asset @3x è di 276 px, a 124 pt servirebbero 372 px: un poco ingrandito, da rifare più grande se si vede sul telefono.
- **Velocità massima 10 km/h / 6 mph**:
  - nel nucleo, `SpeedTrack.maxSpeed` 10, `DistanceUnit` 2–6 mph, `kmhRange` 3–10;
  - `Plan` limita a 10;
  - test aggiornati: 112 verdi.
  - Una velocità salvata più alta scende a 10:
    - sul telefono si riscrive all'avvio;
    - da iCloud e dal Backup passa da `speed` che arrotonda e salva.
  - `CadenceModel` e `AutoCalibration` (3–12 km/h) restano: gli allenamenti più veloci servono alla curva della corsa.
  - La slitta ora si specchia da ≈ 8,7 km/h.
- **Screenshot nuovi** in `tasks/T-016/`: SE e 17 Pro Max, giorno e notte, a 5,5 e 10 km/h; in più 3 km/h e Home normale a 10 km/h.
- **Da guardare:**
  - a 3 km/h la slitta più grande esce di ≈ 15 pt dal bordo sinistro (entra dalla strada);
  - di notte su SE «MINUTI» sfiora la pelliccia dello stivale.

