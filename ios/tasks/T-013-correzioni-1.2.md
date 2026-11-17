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
