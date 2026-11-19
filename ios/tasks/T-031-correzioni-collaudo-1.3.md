# T-031 Correzioni dal collaudo della 1.3 (T-029)
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026 — poi build TestFlight per William

## Perché
Il collaudo T-029 (`comms/qa/T-029.md`, PR #59) non ha trovato difetti bloccanti, ma cinque minori. Decisioni del
Director qui sotto.

## Cosa fare (ramo `task/T-031-correzioni`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Orologio della voce (difetto 1):** fumetto, battute, notifiche roast e controllo del catalogo leggono
   `AppClock.now()`, così `-stepteller.debugNow` sposta anche la voce e le ore si collaudano sul Simulatore.
2. **Ripetizioni (difetto 2):** nel pop-up non si sceglie una battuta che ripete il titolo («Jolly guadagnato…» sotto
   «JOLLY GUADAGNATO!») né una che ripete il numero della targhetta («Ne restano 3» sopra «TI RESTANO 3 JOLLY»). Nel
   promemoria serale, se la battuta contiene già i passi mancanti, non si aggiunge «(mancano N)». Fallo con una regola
   nel nucleo (per esempio un campo «non nel pop-up» o un confronto sui segnaposti), con test; i testi non cambiano.
3. **Doppio e record (difetto 3):** se c'è un evento (record, doppio dell'obiettivo), le battute di quell'evento
   hanno la precedenza sulle generiche di «Quando ce la fai»; tra più eventi vince il più raro (record, poi doppio).
   Test nel nucleo.
4. **Battuta del tocco (difetto 4):** la battuta «se tocchi il cuore» è temporanea: non diventa la battuta della
   Home. Dopo qualche secondo, o alla riapertura dell'app, torna quella della situazione.
5. **Senza dati di Salute (difetto 5):** se l'ultima lettura di Salute non è riuscita o i dati mancano, promemoria e
   notifiche roast usano i testi normali (o non partono, per le roast): mai una battuta sui passi senza un numero
   letto davvero.
6. Riga nel CHANGELOG 1.3; `swift test`, Debug e Release; revisione indipendente; PR verso `main`, non unirla.

## Non fare
Nessuna build TestFlight, nessun commit `[store…]`. Non toccare i testi delle battute. Non scrivere a William.
Solo SSD; a fine turno niente acceso.

## Esito
