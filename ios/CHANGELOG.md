# Changelog

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
