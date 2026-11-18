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

## Riuscita
Home natalizia uguale alla tela, nessun resto dei cappellini, Jolly regalo dato una volta sola e mai perso, CI verde,
screenshot nella PR, elenco di cosa si vede solo sul telefono.

## Non fare
Non unire, nessuna build TestFlight, nessun tag `[testflight]`/`[apple]`/`[store]`, nessuna chiave. Salute solo lettura,
niente rete. Nessuna spesa (Higgsfield è del Designer). Non toccare la PR #28 né la radice del repo. Non scrivere a
William.

## Esito
