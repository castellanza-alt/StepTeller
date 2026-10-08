# Changelog

## 0.5.0 — 8 ottobre 2026
- Nuova struttura: **Oggi** (passi nell'arco, minuti sul tappeto con foto a sinistra, selettore di velocità) e **Storico**
  con selettore Storico | Streak e barra in basso con sfondo sfumato.
- Storico: settimana/mese/anno/sempre (passi o km), totali, media, giorni a obiettivo, calendario del mese,
  record personali (giorno, settimana, mese, anno). Dati da Salute, niente archivio proprio.
- Streak e Jolly: parte da 0 con 3 Jolly al primo avvio; 1 Jolly ogni 15 giorni riusciti; il Jolly si spende da solo
  e salva la streak senza farla crescere (il conto dei 15 giorni riparte da 0). Nessun Jolly se la streak è a 0.
- Obiettivo nelle Impostazioni (default 10.000), vale da oggi; lo storico degli obiettivi è conservato.
- Il promemoria serale avvisa se stasera si usa un Jolly o se la streak si interrompe.
- Ritaglio della foto del tappeto senza l'ombra grigia a terra.

## 0.4.0 — 8 ottobre 2026
- Widget piccolo «Passi di oggi» (tema scuro): arco di 270° con i passi, avanzamento e, nell'apertura, i minuti a piedi
  che mancano stimati a 4 km/h; stato «Fatto» a obiettivo chiuso. Legge Salute direttamente; a telefono bloccato usa
  l'ultimo valore salvato dall'app (App Group `group.it.castellanza.stepteller`, anche per obiettivo e taratura).

## 0.2.0 — 8 ottobre 2026
- Foto del Technogym di Will al posto del disegno, con il nastro animato sopra.
- Taratura automatica da Salute: allenamenti di camminata/corsa degli ultimi 90 giorni (≥ 10 min, scarto degli anomali,
  punti per fascia di velocità). Se non ci sono abbastanza allenamenti resta la taratura manuale in `Calibration`.
- Promemoria serale (default 20:30, modificabile dalla campanella): minuti reali se l'obiettivo non è chiuso,
  aggiornati da Salute anche in background (consegna oraria).
- Permessi Salute estesi: passi, distanza, allenamenti (sempre sola lettura).

## 0.1.0 — 8 ottobre 2026 (prima build, non ancora provata su iPhone)
- App SwiftUI con lo stesso modello della web app v4.0 e lo stesso aspetto (tappeto, orb, pannello in vetro, cursore).
- Passi di oggi da Apple Salute (sola lettura), aggiornamento in primo piano e al cambio di giorno.
- Correzione manuale dei passi con «Usa Salute»; obiettivo e velocità persistiti.
- Nucleo `StepTellerCore` con test golden; CI iOS e distribuzione TestFlight.
