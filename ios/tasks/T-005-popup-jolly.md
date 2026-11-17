# T-005 Pop-up e testi di obiettivo e Jolly (specifica)
**Assegnato a:** Designer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026, dopo T-004

## Perché
William, 17/11: notifica quando raggiunge i passi, pop-up quando guadagna un Jolly, notifica e pop-up quando ne usa uno.
Regole in D-038. Il Developer costruisce la logica in T-006 con pop-up provvisori; tu dai la forma finale.

## Cosa fare (ramo `design/T-005-popup-jolly`)
1. Specifica `ios/docs/design/T-005-popup-jolly.md`:
   - pop-up «Jolly guadagnato» e «Jolly usato»: vignetta «Dan Dan Dan», misure, colori dai token, entrata e uscita
     (tipo, durata, rimbalzo), aptica, come si chiude, «Riduci movimento», giorno/notte, e con il tema di Natale (T-004);
   - testi esatti in italiano: titolo e corpo delle tre notifiche (obiettivo raggiunto, Jolly guadagnato, Jolly usato)
     e dei due pop-up, con i numeri (passi, Jolly rimasti, serie). Brevi: vanno in 10 lingue;
   - interruttore in Impostazioni per queste notifiche (vicino al promemoria): etichetta e nota.
   Guarda `App/GoalCelebration.swift` (festa a obiettivo raggiunto già esistente) per restare coerente.
2. Anteprima ferma come Artifact privato. PR verso `main`, non unirla.

## Riuscita
Il Developer sostituisce i provvisori senza domande; testi italiani pronti da far approvare a William dal Director.

## Non fare
Non toccare il codice Swift. Non unire. Non scrivere a William.

## Esito
