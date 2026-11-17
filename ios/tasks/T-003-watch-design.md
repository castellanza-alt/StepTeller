# T-003 Specifica grafica dell'Apple Watch
**Assegnato a:** Designer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026

## Perché
L'app per Apple Watch (ramo `ia/1.2-watch`, `ios/Watch/WatchHomeView.swift` e le complicazioni in
`ios/LiveActivity/StepsWidget.swift` / `ios/Shared/StepsWidgetView.swift`) è stata scritta direttamente in codice, senza
una specifica. Prima della pubblicazione deve stare allo stesso livello della Home dell'iPhone, stile «Dan Dan Dan».

## Cosa fare (ramo `design/T-003-watch`, worktree `~/Developer/neat-design`)
1. Leggi il codice del Watch su `origin/ia/1.2-watch` (solo lettura) e i token in `ios/App/Design/MangaTokens.swift`.
   Puoi guardarlo sul Simulatore watchOS se ti serve, senza cambiare codice.
2. Scrivi `ios/docs/design/T-003-watch.md`: schermata principale (serie e Jolly, passi, obiettivo, barra, minuti che
   mancano, «OBIETTIVO RAGGIUNTO»), le quattro famiglie di complicazioni (tondo, rettangolo, riga, angolo), schermate
   per 41, 45 e 49 mm. Numeri, non aggettivi: misure in pt, colori in esadecimale (palette notte), font e dimensioni,
   curve con tipo/durata/rimbalzo, testi esatti in italiano. Per ogni punto: cosa cambia rispetto al codice attuale.
3. Anteprima ferma come Artifact (privato) con la schermata e le complicazioni, prima e dopo; il link va nella specifica.
4. Aggiorna l'indice di `ios/docs/design/README.md`. PR da `design/T-003-watch` verso `main`; non unirla.

## Riuscita
Il Developer può implementare la specifica senza fare domande: ogni elemento ha misure, colori, testo e stato.
Nessun colore fuori dai token, o un nuovo token proposto con il suo valore giorno/notte.

## Non fare
Non toccare il codice Swift. Non unire, nessuna build, nessuna spesa (servizi o crediti esterni) senza il sì del
Director. Non scrivere a William.

## Esito
