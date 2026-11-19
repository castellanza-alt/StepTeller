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
**Developer, 19/11/2026.** Ramo `task/T-031-correzioni`, PR verso `main` (non unita).

1. **Orologio:** fumetto, battute, prima battuta, notifiche roast e controllo del catalogo leggono `AppClock.now()`. Le
   animazioni del cuore restano sull'ora vera: con un `debugNow` nel futuro il fumetto restava invisibile. Provato su SE:
   con `debugNow` alle 9 solo «Pochi passi», alle 14:30 e alle 18:40 le battute dell'ora.
2. **Ripetizioni:** regole nel nucleo, i testi non cambiano. In `NastyPicker.pick` ci sono `excluding` (segnaposti mai
   detti) e `notSaying` / `excludingIDs` (testi mai ripetuti). Le battute che ripetono un titolo si trovano
   sull'italiano (`NastyPicker.repeating`) e si escludono per id in tutte le lingue, perché le traduzioni riformulano
   i titoli.
   - Pop-up «Jolly usato»: niente titolo, niente `{jolly}` né `{serie}`. Pop-up «Jolly guadagnato»: niente titolo né
     `{jolly}`.
   - Avvisi di obiettivo e Jolly: mai il loro titolo.
   - Promemoria: niente `{mancano}`, `{minuti}`, `{obiettivo}`, che il promemoria dice già.
   - **Effetto da sapere:** con il catalogo di oggi «Jolly guadagnato» (N099, P039, entrambe «Jolly guadagnato…») e
     «Jolly usato» in Piccante (P037 ripete il titolo, P038 il numero) non hanno più una battuta. Quei pop-up tengono
     la frase di sempre. «Jolly usato» in Senza pietà ha N092 e N098.
3. **Eventi prima:** le battute di un evento vero battono le generiche, il più raro per primo: record, poi doppio,
   poi ultimo Jolly, poi gli altri eventi. Vale anche quando l'evento arriva dopo nella stessa situazione: il fumetto
   lascia la battuta generica.
4. **Tocco:** la battuta resta 6 s, non si salva come battuta della Home e non sopravvive al passaggio in sottofondo.
   Poi torna quella della situazione, chiesta dalla Home stessa (solo se è a schermo); subito se cambia il livello.
   Provato su SE.
5. **Senza dati:** la voce vale solo con passi letti davvero (`hasReadSteps`: lettura di questo avvio, o il conteggio
   di oggi salvato da una lettura vera).
   - Senza dati il promemoria ha il testo di sempre.
   - Le roast non si ripianificano: resta il piano dell'ultima lettura vera, e con Normale si ritirano comunque.
   - Il widget dava già la voce solo con un conteggio letto.
6. **Revisione indipendente:** corretti il titolo ripetuto nelle altre lingue (prima il controllo valeva solo per
   italiano e inglese), l'evento arrivato dopo nel fumetto, `hasReadSteps` vero prima di ogni lettura e il timer del
   tocco che parlava fuori dalla Home.

**Verifiche:** `swift test` 155 test verdi (nuovi: eventi prima, niente ripetizioni, titoli per id in 10 lingue,
evento che arriva dopo); build Debug e Release; `registro.py`. Nessuna build TestFlight.
