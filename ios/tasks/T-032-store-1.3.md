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
**Developer, 19/11/2026.** Ramo `task/T-032-store`, PR verso `main` (non unita). Niente scritto su App Store Connect,
nessun commit `[store…]`.

1. **Classificazione** (`scripts/asc_store.py`, `age_profile`): fino alla 1.2 tutto «no» e 4+, come oggi. Dalla 1.3
   (`MARKETING_VERSION` ≥ 1.3, quindi solo con il `[store]` della 1.3) `profanityOrCrudeHumor` diventa frequente; il
   resto non cambia. Attesa **`THIRTEEN_PLUS`**: se Apple calcola altro dopo il salvataggio, lo script si ferma e lo dice.
   - Valori presi dalla specifica OpenAPI ufficiale di App Store Connect (4.6.1), scaricata e letta in locale.
   - `profanityOrCrudeHumor` accetta `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE` (questionario vecchio) e
     `INFREQUENT`, `FREQUENT` (2025).
   - Lo script manda `FREQUENT`; se Apple lo rifiuta (409/422) riprova con `FREQUENT_OR_INTENSE`. Se c'è già uno dei
     due, non lo tocca.
   - Domande nuove nella specifica (`datingAndRelationships`, `sharedLocation`): lo script le segnala già come «non
     gestite» e le lascia come sono, come chiede il compito.
2. **Note per il revisore** (`store/note_revisore.txt`, 3987 caratteri; lo script ora rifiuta oltre 4000):
   - «NEW IN 1.3»: la voce con Normal / Spicy / No mercy, scelta nella pagina 4 dell'introduzione e in Settings ›
     Voice; No mercy di serie, con parolacce e insulti solo sul camminare poco, dichiarati (13+); mai corpo, salute,
     età o tratti personali; si spegne con Normal.
   - Notifiche tra le 10 e le 20, nessuna dopo l'obiettivo.
   - In «EXTERNAL SERVICES», il file statico da GitHub Pages: GET senza parametri, nessun dato inviato. «No servers
     that receive data…».
   - Introduzione a 5 pagine; resta la riga sul Natale. Le parti già note sono state accorciate per stare nel limite.
3. **`[store-invio]`** prima non controllava la versione precedente: rifiutava solo «in lavorazione». Ora,
   prima di scrivere qualsiasi cosa (`previous_published`), si rifiuta se:
   - una versione precedente è ancora da Apple (in revisione, in attesa, in elaborazione);
   - la precedente non è «pubblicata» né nel CHANGELOG né su App Store Connect (in vendita). Se è in vendita ma il
     CHANGELOG non è aggiornato, vale App Store Connect.
4. **Prova a secco:** in locale non ci sono chiavi di App Store Connect (`RILASCIO.md` non ne prevede, e la regola dei
   compiti è niente chiavi), e `[store-prova]` è un commit su main, vietato qui. Quindi prova senza rete, con le
   risposte di App Store Connect simulate (dichiarazione di oggi tutta «NONE», 4+). Esito:
   - in prova nessuna scrittura; l'unica modifica sarebbe `profanityOrCrudeHumor` NONE → FREQUENT, con la nota «4+
     non è la classificazione attesa per la 1.3, la cambierà [store]»;
   - in applicazione si scrive solo quel campo; se Apple rifiuta, riprova con FREQUENT_OR_INTENSE; con 16+ si ferma;
   - `[store-invio]` con la 1.2 in revisione si rifiuta; con la 1.2 accettata ma non ancora in vendita
     (PENDING_DEVELOPER_RELEASE) si rifiuta; con la 1.2 in vendita, o «pubblicata» nel CHANGELOG, passa;
   - **per la prova vera con App Store Connect** serve un `[store-prova]` su main, che decide il Director. Non scrive
     nulla, ma vede la 1.2 in revisione.
5. CHANGELOG non toccato: la sezione in cima è «su TestFlight, build 1.204.1» e questi file non sono nella build.
6. **Revisione indipendente, corretto:**
   - `[store]` poteva scrivere la dichiarazione 13+ sulla «App Information» della 1.2 in revisione. Ora:
     - si scrive solo su un'App Information in preparazione;
     - `[store]` della 1.3 si ferma subito se una versione precedente è ancora da Apple;
     - `[store-prova]` resta libero.
   - Il secondo tentativo con l'altra grafia parte solo se Apple contesta proprio quel valore, non per un record
     bloccato.
   - Se App Store Connect conosce la versione precedente, conta solo «in vendita», qualunque cosa dica il CHANGELOG
     (per esempio con PENDING_DEVELOPER_RELEASE si rifiuta).
   - App mancante: il messaggio chiaro, non un errore.
   - Tutto riprovato senza rete con le risposte simulate.
