# T-032 Scheda dello store pronta per la 1.3 (senza inviare)
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026

## Perché
William: «prepara tutto e fermati un attimo prima di mandarlo ad Apple». La 1.3 è su TestFlight (build 1.204.1).
Testi, Novità e screenshot nuovi sono in `main` (#54, #58). Mancano tre cose perché `[store]` e `[store-invio]`
funzionino quando sarà il momento. La 1.2 è ancora in revisione: **niente va scritto su App Store Connect adesso**.

## Cosa fare (ramo `task/T-032-store`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Classificazione per età** in `scripts/asc_store.py`: oggi dichiara tutto «NONE» e accetta solo 4+. Per la 1.3:
   `profanityOrCrudeHumor` = frequente/intenso (il valore esatto dell'API), tutto il resto invariato; età attesa
   **13+** (D-044). Leggi dall'API i valori ammessi e come Apple chiama la fascia 13+; se l'età calcolata non è quella
   attesa lo script si ferma e lo dice. La dichiarazione deve cambiare **solo** con `[store]` della 1.3, mai prima.
2. **Note per il revisore** `store/note_revisore.txt` (inglese, sotto i 4000 caratteri): al posto di «NEW IN 1.2»,
   «NEW IN 1.3»: NEAT ha una voce con tre livelli (Normal, Spicy/Piccante, No mercy), scelta in Settings › Voice e
   nell'introduzione; il livello di serie è il più forte e contiene parolacce e insulti scherzosi rivolti solo al
   fatto di camminare poco (dichiarati nella classificazione, 13+); mai riferimenti a corpo, salute, età o altre
   caratteristiche personali; si spegne scegliendo Normal. L'app scarica una volta al giorno un file statico di testi
   da GitHub Pages (`…/neat/nasty/<lingua>/battute.json`) e **non invia alcun dato**: aggiorna il punto «EXTERNAL
   SERVICES» e la frase «No servers…». Notifiche locali in più (battute, tra le 10 e le 20). Tieni una riga sul
   Natale (1 dicembre–6 gennaio). Usa i nomi inglesi dei livelli del glossario.
3. **Controlli di `[store-invio]`:** verifica che lo script rifiuti l'invio della 1.3 finché la 1.2 non è
   «pubblicata» nel CHANGELOG o su App Store Connect (D-046); se non lo fa, aggiungi il controllo.
4. Prova a secco in locale (sola lettura, con le chiavi locali di sola lettura come da `RILASCIO.md`), senza scrivere
   nulla: riporta nell'Esito cosa cambierebbe. PR verso `main`, non unirla.

## Non fare
Nessun commit `[store]` o `[store-invio]`, nessuna scrittura su App Store Connect, nessuna build. Non unire la #57
(privacy). Non scrivere a William. Solo SSD; a fine turno niente acceso.

## Esito
