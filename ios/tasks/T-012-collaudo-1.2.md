# T-012 Collaudo della 1.2 «Natale» sul Simulatore
**Assegnato a:** QA **Base:** `main` 96628e1 **Stato:** assegnato 17/11/2026

## Perché
In `main` ci sono tutte le novità della 1.2 (T-006, T-010, T-011). Prima della build TestFlight per William serve un
collaudo unico, mirato a ciò che è cambiato.

## Cosa fare (ramo `qa/T-012`, worktree `~/Developer/neat-qa`)
1. Fuori stagione (oggi) e in stagione (`-stepteller.season`, solo DEBUG): l'app fuori stagione è identica alla 1.1;
   in stagione corrisponde all'anteprima di `docs/design/T-004-natale.md` (Home, Storico, splash, widget, giorno/notte,
   Riduci movimento); interruttore «Temi stagionali» e icona (cambio e ritorno, avviso di iOS, anche durante
   l'introduzione).
2. Pop-up «Jolly guadagnato» e «Jolly usato» e festa dell'obiettivo, con la coda e senza ripetizioni (provider finto);
   confronto con `docs/design/T-005-popup-jolly.md`.
3. Notifiche: cosa si riesce a vedere sul Simulatore (obiettivo, Jolly, fascia 22–8 spostata alle 8, promemoria
   tolto quando l'obiettivo è chiuso), sezione «Notifiche» in Impostazioni, Backup che porta i nuovi interruttori.
4. Non regressioni della 1.1: Backup, introduzione, Home senza dati.
5. Rapporto `ios/comms/qa/T-012.md` con l'elenco breve di cosa William deve provare sul telefono; PR col solo
   rapporto, non unirla.

## Non fare
Non correggere il codice, non unire, nessuna build TestFlight, nessuna chiave. Non scrivere a William.

## Esito
