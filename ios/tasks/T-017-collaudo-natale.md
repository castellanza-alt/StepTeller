# T-017 Collaudo del Natale rifatto e della velocità a 10 km/h
**Assegnato a:** QA **Base:** `main` 52a9b39 **Stato:** assegnato 18/11/2026 — urgente

## Perché
In `main` c'è il Natale rifatto (T-016, specifica `docs/design/T-015-natale.md`, D-040) e la velocità massima a
10 km/h (D-042). Il primo Natale (T-004/T-010) è stato bocciato da William per com'era fatto, non per difetti: questa
volta il collaudo guarda anche **com'è**, non solo se funziona. Dopo il collaudo parte la build TestFlight per William.

## Cosa fare (ramo `qa/T-017`, worktree `/Volumes/SSD/Developer/neat-qa`)
1. **Natale, a confronto con la tela** (https://claude.ai/artifact/SZPn4ouqgQdfiDUA7DtZRY, approvata da William) e
   con la specifica: Home giorno e notte, gamba-stivale con parallasse, slitta (leggibile, si trascina bene, non copre
   testi a nessuna velocità da 3 a 10 km/h), «MINUTI MANCANTI» leggibile, «Riduci movimento», interruttore spento,
   icona (cambio, ritorno a fine periodo, avviso di iOS non sopra pop-up o festa). Segnala anche ciò che è brutto o
   storto, con lo screenshot: nessun resto dei cappellini, delle luci o della neve animata in Home, Storico, festa,
   splash, widget.
2. **Jolly regalo** con `-stepteller.debugNow`: 24/12 23:59 niente; 25/12 pop-up e +1 Jolly; seconda apertura
   niente; prima apertura il 3/1 sì; 6/1 sì; 7/1 no; coda con altri pop-up (regalo → usato → guadagnato → festa);
   temi spenti: regalo sì, tema no.
3. **Velocità a 10 km/h** fuori stagione: cursore e strada fino a 10 (miglia 6 mph), minuti coerenti, una velocità
   salvata più alta (Backup vecchio con 15 km/h) scende a 10.
4. Non regressioni della 1.2 (notifiche, pop-up Jolly, Impostazioni) e della 1.1 (Backup, introduzione).
5. Rapporto `ios/comms/qa/T-017.md` con: esito, difetti (bloccanti o no), screenshot, elenco breve di cosa William deve
   provare sul telefono. PR col solo rapporto, non unirla.

## Disco (regola di William, 18/11)
Si lavora solo sull'SSD: screenshot e video pesanti in `/Volumes/SSD/Temp/NEAT/` quando esiste (altrimenti nella tua
cartella di lavoro sull'SSD), cancellati a fine compito. A fine turno nessuna registrazione, simulatore o processo
acceso.

## Non fare
Non correggere il codice, non unire, nessuna build TestFlight, nessuna chiave. Non scrivere a William.

## Esito
**18/11/2026, QA.** Collaudo sul Simulatore (iPhone 17 Pro e SE), rapporto `comms/qa/T-017.md` con 18 screenshot in
`comms/qa/T-017/`, ramo `qa/T-017`.
- **Funziona**:
  - Natale come la tela;
  - Jolly regalo con tutte le date;
  - coda regalo → usato/guadagnato → festa;
  - temi spenti: regalo sì, tema no;
  - «Riduci movimento»;
  - velocità a 10 km/h e 6 mph;
  - Backup con 15 km/h che scende a 10;
  - 112 test del nucleo.
- **Bloccante per il Natale**: l'icona con lo stivale esce ingrandita, cioè solo un pezzo di suola. Causa probabile: i
  PNG da 2048 px al posto degli SVG.
- **Medio**: sull'SE, di giorno, si vedono le bande laterali.
- **Minori**:
  - conti dei Jolly nella coda;
  - pomello che a 10 km/h copre «≈ km»;
  - «SALUTE» sulla luna di notte;
  - bordo quadrato del regalo;
  - slitta fuori dal bordo a 3 km/h.
- Provato da William: no.
