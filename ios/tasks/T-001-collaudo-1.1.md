# T-001 Collaudo della 1.1 sul Simulatore
**Assegnato a:** QA **Base:** `main` (il codice è quello della build 1.97.1, `105eac8`) **Stato:** assegnato 17/11/2026

## Perché
La 1.1 (build 1.97.1) è su TestFlight dal 28/10 ma nessuno l'ha collaudata in modo ordinato e William non l'ha ancora
provata. Prima di chiedergli la prova sul telefono serve sapere cosa funziona sul Simulatore e cosa resta da vedere
solo sul telefono, così la sua prova è corta e mirata.

## Cosa fare (ramo `qa/T-001`, worktree `~/Developer/neat-qa`)
1. Compila e avvia la 1.1 sul Simulatore iPhone (provider finto di Salute, solo `#if DEBUG`).
2. Strade da provare, passi numerati da zero, esito per ognuna:
   - Primo avvio: introduzione completa, pagina Salute con la frase nuova («I tuoi dati non lasciano mai il tuo account»).
   - Home e Storico giorno/notte: nessuna traccia dell'inserimento dei passi a mano (tolto in 1.1, D-006).
   - Impostazioni → Backup: «Esporta backup» (nome `NEAT-backup-AAAA-MM-GG.json`, contenuto senza dati di Salute),
     «Importa backup» con conferma e data, file non valido, file di versione più nuova, inizio streak che tiene il più vecchio.
   - Promemoria serale: testo con obiettivo già raggiunto e non raggiunto (dove il Simulatore lo permette).
   - Copia in iCloud: cosa si può vedere sul Simulatore e cosa no (dillo, non inventare).
   - Due lingue oltre all'italiano (inglese e una asiatica) per le schermate nuove: testi tagliati o mancanti.
3. Rapporto in `ios/comms/qa/T-001.md`: esito per strada, una o due catture (fuori dal repo se pesanti), difetti trovati
   con passi per riprodurli, e **l'elenco di cosa William deve provare sul telefono**, in italiano semplice, al massimo
   10 righe (include i percorsi di iOS per spegnere e cancellare la copia in iCloud scritti in `neat/privacy`).
4. PR da `qa/T-001` verso `main` con il solo rapporto; non unirla.

## Riuscita
Ogni strada ha un esito (funziona / difetto / non provabile sul Simulatore). L'elenco per William c'è ed è breve.

## Non fare
Non correggere il codice (i difetti vanno nel rapporto, il Director scrive il compito). Non unire, non cambiare versione
né il CHANGELOG, nessuna build TestFlight, nessuna chiave o credenziale. Non scrivere a William.

## Esito
17/11/2026, QA. Collaudo fatto sul Simulatore (iPhone 17 Pro, iOS 27), rapporto in `comms/qa/T-001.md`.
Funziona: introduzione con la frase nuova, Home/Storico giorno-notte senza passi a mano, Backup (esporta, importa con
conferma e data, file non valido, versione più nuova, inizio streak che tiene il più vecchio), promemoria con obiettivo
non chiuso (arriva, numeri giusti) e chiuso (non arriva), inglese e giapponese. Non provabile sul Simulatore: copia in
iCloud, telefono bloccato, aggiornamento dal widget e in sottofondo. Nessun difetto bloccante; tre minori nel rapporto
(luna sopra l'avviso «Nessun dato» di notte; testo di sistema di Salute che dice ancora «non invia dati fuori dal
telefono»; la build della CI non ha gli entitlement). Elenco di 9 righe per William nel rapporto.
Provato da William: no.
