# T-006 Notifiche e pop-up di obiettivo e Jolly
**Assegnato a:** Developer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026 — 1.2 «Natale», PR pronta entro il 24/11

## Perché
William, 17/11: notifica quando raggiunge i passi; pop-up quando guadagna un Jolly; notifica e pop-up quando ne usa
uno. Regole in D-038, ordine delle versioni in D-036 (questa è la 1.2; il Watch passa alla 1.3).

## Cosa fare (ramo `task/T-006-notifiche`, worktree `~/Developer/neat-dev`)
1. Nel core (`StepTellerCore`, funzioni pure con test): dagli stati di `StreakEngine` di ieri e di oggi ricava gli
   eventi «obiettivo raggiunto oggi», «Jolly guadagnato», «Jolly usato» (con data), così da non perderli né ripeterli.
   Ricorda che streak e Jolly non si salvano: si salva solo quali eventi sono già stati annunciati.
2. Notifiche: obiettivo raggiunto (una al giorno, appena il conteggio lo dice, mai di notte, annulla il promemoria
   serale di quel giorno se ancora in attesa), Jolly guadagnato, Jolly usato. Usa ciò che c'è già: consegna in
   sottofondo di Salute (`HealthKitStepsProvider`), widget (`WidgetReminder`), `ReminderRefreshTask`. Scegli tu come e
   scrivilo nella PR, con i limiti di iOS.
3. Pop-up alla prima apertura dopo un evento Jolly, mai ripetuto: per ora vignetta provvisoria con i token esistenti;
   la forma e i testi finali arrivano da T-005 (Designer).
4. Interruttore in Impostazioni per queste notifiche (acceso di serie), salvato anche nella copia in iCloud e nel Backup
   (formato del Backup: aggiungi campi, non rinominarli).
5. Testi: bozze italiane provvisorie nel catalogo con chiavi nuove; le traduzioni vere arrivano dopo l'ok di William.
6. Versione: apri «## 1.2 — in lavorazione» in cima al CHANGELOG e `MARKETING_VERSION` 1.2 in questa PR (autorizzato).
7. Verifica: `swift test`, compilazione Simulatore, prova degli eventi con il provider finto `#if DEBUG`; revisione
   indipendente del diff con un subagente; PR verso `main` (non bozza), non unirla.

## Riuscita
Test del core per ogni evento (compreso: due Jolly lo stesso giorno, evento visto da widget e app insieme, cambio di
fuso, reinstallazione); nessuna notifica doppia; CI verde; elenco nella PR di cosa si vede solo sul telefono.

## Non fare
Non unire, nessuna build TestFlight, nessun tag `[testflight]`/`[apple]`/`[store]`, nessuna chiave. Salute solo lettura,
niente rete. Non toccare la PR #28 (Watch) né la radice del repo. Non scrivere a William.

## Esito
