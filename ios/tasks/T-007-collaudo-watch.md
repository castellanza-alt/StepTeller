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
17/11/2026, QA. Rapporto `ios/comms/qa/T-007.md` (ramo `qa/T-007`, PR col solo rapporto, non unita).
- **Funziona sul Simulatore** (codice `task/T-002-watch` 7b8a631): arrivo e aggiornamento di obiettivo, velocità,
  unità, serie e Jolly, anche ad app chiusa e con il telefono spento; passi dalla Salute dell'orologio; «OBIETTIVO
  RAGGIUNTO» e «Niente dati»; casse 41/45/49 (e 42/46) mm con le misure di T-003; italiano e giapponese; nel pacchetto
  solo impostazioni, nessun dato di Salute.
- **Non provato:** le quattro complicazioni (manca il permesso di toccare l'orologio nel Simulatore), una taratura
  vera, i passi che salgono con l'app aperta (il Simulatore non sincronizza Salute dopo l'abbinamento).
- Nessun difetto bloccante; confermato il testo «telefono» nel permesso Salute delle complicazioni.
- Provato da William: no.
