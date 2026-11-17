# T-007 Collaudo dell'Apple Watch (PR #28)
**Assegnato a:** QA **Base:** ramo `task/T-002-watch` (PR #28) **Stato:** assegnato 17/11/2026

## Perché
L'app per Apple Watch è riportata sulla 1.1 (T-002) ma l'ha vista solo il Developer. Uscirà con la 1.3 (D-036) e la sua
grafica cambierà con la specifica T-003; prima conviene sapere se i dati e le complicazioni funzionano.

## Cosa fare (ramo `qa/T-007`, worktree `~/Developer/neat-qa`)
1. Compila `origin/task/T-002-watch` (in sola lettura, nel tuo worktree) e avvialo su iPhone + Apple Watch abbinati nel
   Simulatore.
2. Strade: arrivo dei dati dal telefono (obiettivo, velocità, unità, serie, Jolly, taratura) e loro aggiornamento;
   orologio con il telefono lontano; passi letti da Salute sull'orologio; «OBIETTIVO RAGGIUNTO»; le quattro
   complicazioni; 41/45/49 mm; italiano e una lingua asiatica; nessun dato di Salute in viaggio tra i due.
3. Rapporto `ios/comms/qa/T-007.md` come T-001, con cosa resta da provare sull'orologio di William. Confronta anche le
   misure delle complicazioni con `docs/design/T-003-watch.md` e segnala dove non tornano (serve al Designer).
4. PR col solo rapporto, non unirla.

## Non fare
Non correggere il codice, non unire, nessuna build TestFlight, nessuna chiave. Non scrivere a William.

## Esito
