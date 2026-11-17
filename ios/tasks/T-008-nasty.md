# T-008 Voce «NASTY»: carattere e testi italiani
**Assegnato a:** Designer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026, dopo T-004 e T-005

## Perché
William, 17/11: una versione «NASTY» alla Carrot Weather che insulta l'utente, «cattivissimo». Poi ha precisato:
«cattiva ma senza parolacce, lo scopo è umiliare con humor inglese, non offendere in modo facile con insulti. L'utente
deve ridere ma anche sentirsi incentivato a fare i passi. Questo deve essere vero in ogni aspetto, anche quando imposta
il target dei passi.» Regole in D-039.

## Cosa fare (ramo `design/T-008-nasty`)
1. `ios/docs/design/T-008-nasty.md`, prima parte, **carattere**: chi parla (un maggiordomo inglese deluso? un sergente
   di Oxford? proponi 2 personaggi con 3 battute ciascuno e scegline uno motivando), registro (understatement, ironia
   secca, finta cortesia), cosa non fa mai (D-039: niente parolacce né insulti facili, mai corpo, peso, aspetto,
   salute, età, genere: solo il comportamento), e come ogni battuta chiude spingendo a camminare.
2. Seconda parte, **tutti i punti dell'app** dove parla, ognuno con 3–5 varianti in italiano, brevi:
   scelta dell'obiettivo (per fasce: basso, medio, alto, ritocco al ribasso, al rialzo), Home a 0, a metà, quasi,
   fatto, molto oltre; Storico (giorni mancati, record); serie e Jolly (guadagnato, usato, finiti, serie persa);
   promemoria serale e notifiche di T-006; introduzione; Impostazioni (la voce stessa: come si accende e si spegne,
   con una battuta anche lì); widget. Indica il limite di caratteri di ogni punto (guarda i testi attuali).
3. Come si sceglie la voce in Impostazioni (etichetta, nota, aspetto), e se cambia qualcosa della grafica.
4. Anteprima ferma come Artifact privato con 6–8 schermate di esempio. PR verso `main`, non unirla.

## Riuscita
Il Director può far scegliere a William il personaggio e approvare i testi italiani in una lettura; ogni punto dell'app
ha la sua battuta; nessuna battuta viola D-039.

## Non fare
Non toccare il codice Swift. Non tradurre (le traduzioni passano dall'italiano approvato da William, D-005). Non unire.
Non scrivere a William.

## Esito
