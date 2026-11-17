# T-013 Correzioni dal collaudo della 1.2
**Assegnato a:** Developer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026 — urgente, prima della build per William

## Perché
Il collaudo T-012 (`comms/qa/T-012.md`, difetti 1–3) ha trovato tre problemi nella 1.2.

## Cosa fare (ramo `task/T-013-correzioni`)
1. **Festa dopo il pop-up Jolly** (difetto 1, media): dopo «OK» sull'ultimo pop-up della coda deve partire la festa
   dell'obiettivo se è dovuta (ordine usato → guadagnato → festa, T-005 §1.1). Riproduci con gli argomenti del
   rapporto; aggiungi un test se la coda è nel nucleo o in una parte testabile.
2. **Titolo dei pop-up tagliato in alto** (difetto 2): «JOLLY GUADAGNATO!»/«JOLLY USATO» ruotati non devono uscire dalla
   vignetta. Decisione del Director: aumenta il margine superiore interno della vignetta quanto basta (non cambiare
   rotazione né corpo del testo); verifica anche in giapponese e con il testo più lungo tra le lingue in bozza.
3. **Avviso dell'icona sopra la festa** (difetto 3): l'avviso di iOS per il cambio icona parte solo quando non c'è
   nessuna festa o pop-up in corso (alla loro chiusura, + 0,6 s), anche a fine introduzione.
4. Verifiche come in T-011, revisione indipendente, riga nella sezione 1.2 del CHANGELOG, PR verso `main`, non unirla.

## Non fare
Non unire, nessuna build, nessun tag, nessuna chiave. Non scrivere a William.

## Esito
17/11/2026, Developer. PR verso `main` dal ramo `task/T-013-correzioni` (link nel riepilogo al Director), non unita.
- **Difetto 1 (festa dopo il pop-up):** dopo «OK» sull'ultimo pop-up la festa parte se dovuta, senza ripetere i
  controlli di tempo (la lettura che ha messo in coda i pop-up vale anche per lei). Non sono riuscito a riprodurre il
  tocco vero sul Simulatore: con `-stepteller.debugPopupClose 2` (nuovo, chiude il pop-up da solo) la sequenza è
  pop-up → 0,3 s → festa. La coda vive in `RootView` (SwiftUI), non nel nucleo: niente test automatico.
- **Difetto 2 (titolo tagliato):** 16 pt di margine sopra il titolo dentro la vignetta, rotazione e corpo invariati;
  verificato in italiano e giapponese (le altre lingue sono ancora l'italiano in bozza).
- **Difetto 3 (avviso dell'icona sopra la festa):** l'avviso parte solo a schermo libero (nessuna festa né pop-up in
  corso o in coda) da 0,6 s, dopo il controllo degli eventi della stessa attivazione (ripiego 20 s), dopo lo splash,
  al ritorno in primo piano e a fine introduzione. Verificato con `-stepteller.debugIcon 1`: pop-up → festa →
  Home → avviso.
- **Provato:** `swift test` 92/92, compilazione Debug e Release, Simulatore. Revisione indipendente: corretti lo
  stato dell'app letto da una copia vecchia della vista, il ripiego troppo corto e l'istante della richiesta.
- **Da allineare (Designer):** T-004 §6 («dopo lo splash + 0,6 s») e T-005 §1.2 (16 pt sopra il titolo).
- **Solo sul telefono:** il tocco vero su «OK» seguito dalla festa.
