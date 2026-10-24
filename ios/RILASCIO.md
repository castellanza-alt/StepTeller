# NEAT — come si fa una versione nuova

Vale per ogni versione dopo la 1.0. Tre pezzi: la **regola dei numeri**, il **registro** (`CHANGELOG.md`) e le
**Novità per lo store** in 10 lingue. La CI e lo script dello store controllano le regole: se manca qualcosa, la build
o l'invio si fermano con un messaggio che dice cosa fare.

## 1. Regola dei numeri

`MAGGIORE.MINORE.CORREZIONE`, e il numero si decide dal contenuto:

| Cosa contiene la versione | Numero | Novità sullo store |
|---|---|---|
| Solo errori sistemati, niente da spiegare | **Correzione**: 1.0 → 1.0.1 → 1.0.2 | Testo fisso «Correzioni e piccoli miglioramenti» (riga `novita.correzioni` del foglio) |
| Funzioni nuove o cambiate che l'utente vede | **Minore**: 1.0 → 1.1 → 1.2 (si scrive `1.1`, non `1.1.0`) | Testo scritto per la versione, tradotto in 10 lingue |
| Aspetto o concetto dell'app rifatti (come fu la 0.6.0) | **Maggiore**: 1.x → 2.0 | Idem |

- Il numero sta in un posto solo: `project.yml`, `MARKETING_VERSION`. Si alza **quando si apre** la versione nel
  registro, non alla fine. Il numero di build (`1.<run>.<attempt>`) lo mette la CI da sola: non si tocca.
- Niente numeri «di prova» (0.99, 0.999): le build TestFlight portano già il numero della versione in arrivo e si
  distinguono per il numero di build.
- Il numero non torna mai indietro e non si riusa.

## 2. Il registro: `CHANGELOG.md`

Una sezione per versione, la più recente in cima. L'intestazione dice **la verità sul codice**:

```
## 1.1 — in lavorazione                                        il codice sta cambiando
## 1.1 — su TestFlight, build 1.95.1                           il codice è quello della build 1.95.1
## 1.1 — inviata ad Apple il 3 novembre 2026, build 1.95.1     in revisione
## 1.1 — pubblicata il 5 novembre 2026, build 1.95.1           sullo store (definitivo)
```

Regole, controllate da `scripts/registro.py`:

1. La prima sezione è la versione di `project.yml`. Versioni in ordine decrescente, ogni sezione con almeno una riga «- ».
2. **Ogni PR che tocca il codice dell'app** (`App/`, `Shared/`, `LiveActivity/`, `Sources/`, `project.yml`,
   `Package.swift`) aggiunge la sua riga alla sezione in cima, che deve essere «in lavorazione». Senza la riga la
   verifica della PR fallisce. PR di soli documenti, script o workflow: nessuna riga richiesta.
3. Se la sezione in cima è «su TestFlight», «inviata» o «pubblicata», il codice **non si tocca**: prima si apre la
   versione successiva («## 1.0.1 — in lavorazione» oppure «## 1.1 — …», con `MARKETING_VERSION` alzata), nella stessa
   PR della modifica.
4. Dopo una build TestFlight, se si continua a lavorare sulla stessa versione, l'intestazione torna «in lavorazione»
   (il codice non è più quello della build). Una versione **inviata** può tornare «in lavorazione» solo se Apple la
   rifiuta; una versione **pubblicata** mai.
5. Le righe sono in italiano, descrivono cosa cambia per chi usa l'app e, se serve, il dettaglio tecnico. È il
   registro interno: le Novità dello store si scrivono a parte (punto 3), filtrando da qui.

Chi aggiorna lo stato dell'intestazione: la chat di coordinamento, con un commit dedicato (come oggi per la
checklist), dopo la build TestFlight, dopo l'invio e dopo la pubblicazione.

## 3. Le Novità per lo store («What's New», 10 lingue)

- Fonte: `localizzazione/NEAT_novita.xlsx`, foglio «Novità», una riga per versione (`novita.1.1`) più la riga fissa
  `novita.correzioni`. Colonne come gli altri fogli: italiano + 9 lingue.
- L'italiano lo scrive la chat di coordinamento partendo dal registro: 3–6 punti, frasi corte, niente termini tecnici,
  niente promesse sulla salute. **Will approva il testo italiano** prima della traduzione.
- Traduzione: `localizzazione/PROMPT_CHATGPT_NOVITA.md` nella chat di ChatGPT che ha tradotto app e scheda, con il file
  allegato. Il file torna compilato e si salva al suo posto.
- `python3 scripts/store_metadata.py` rigenera `store/metadata.json` (testi della scheda **e** `whatsNew` per versione);
  si ferma se una cella è vuota o supera 4000 caratteri.
- `[store-prova]` mostra lingua per lingua cosa cambierebbe su App Store Connect, `[store]` scrive. Le versioni di sola
  correzione (X.Y.Z) senza riga propria usano `novita.correzioni`. La prima versione (1.0) non ha Novità: Apple non le
  prevede.
- `[store-invio]` **si rifiuta** se mancano le Novità della versione o se il registro dice ancora «in lavorazione».

## 4. La procedura, uguale ogni volta

```
Versione ____  (correzione / minore / maggiore)
[ ] 1. Apertura: in cima a CHANGELOG.md «## X.Y — in lavorazione», MARKETING_VERSION = X.Y in project.yml (stessa PR del primo cambiamento)
[ ] 2. Lavoro: ogni PR aggiunge la sua riga alla sezione (la CI lo pretende)
[ ] 3. Chiusura: Novità in italiano scritte dal registro, approvate da Will
[ ] 4. Traduzione: PROMPT_CHATGPT_NOVITA.md → NEAT_novita.xlsx compilato → python3 scripts/store_metadata.py → commit
[ ] 5. Commit con [testflight] (la CI rifiuta se il registro non è «in lavorazione» o «su TestFlight»)
[ ] 6. Intestazione → «su TestFlight, build N»; prova di Will sul telefono
[ ] 7. Commit [store-prova], lettura del riepilogo; poi [store]; rilettura «Nessuna differenza»
[ ] 8. Ok esplicito di Will → commit [store-invio]; intestazione → «inviata ad Apple il …, build N»
[ ] 9. Esito Apple: approvata → rilascio (manuale, dal sito); rifiutata → intestazione «in lavorazione», si corregge, si riparte dal punto 5
[ ] 10. Pubblicata: intestazione → «pubblicata il …, build N»; tag git vX.Y sul commit della build; merge su main
```

## 5. Cosa controlla la macchina

| Momento | Controllo | Dove |
|---|---|---|
| Ogni PR che tocca `ios/**` | Formato e ordine del registro; prima sezione = `MARKETING_VERSION`; se cambia codice: riga aggiunta e sezione «in lavorazione» | `ios-verifica.yml` → `scripts/registro.py --pr` |
| Push su `main` | Formato e ordine del registro | `ios-verifica.yml` → `scripts/registro.py` |
| `[testflight]` | Come sopra, più: sezione «in lavorazione» o «su TestFlight» (una versione inviata o pubblicata non si ricostruisce) | `ios-testflight.yml` → `scripts/registro.py --testflight` |
| `[store]` | Novità presenti per la versione (avviso se mancano); limiti di Apple su tutti i testi | `asc_store.py` |
| `[store-invio]` | Scheda uguale al repository; Novità presenti (salvo prima versione); registro «su TestFlight» o «inviata»; build con lo stesso `MARKETING_VERSION` | `asc_store.py` |

## 6. Casi particolari

- **Apple rifiuta.** L'intestazione torna «in lavorazione» con lo stesso numero (su App Store Connect la versione
  resta la stessa), si corregge, si ricostruisce, si reinvia. Il numero cambia solo se nel frattempo si aggiunge una
  funzione.
- **Correzione urgente mentre la minore è in lavorazione.** Si chiude prima la minore o si rinvia la correzione alla
  minore stessa: un solo ramo di uscita, una sola versione aperta alla volta.
- **Funzione grande in parallelo** (deciso da Will il 24 ottobre 2026 per l'app Apple Watch, 1.2, mentre la 1.1
  aspetta la pubblicazione): è l'unica eccezione alla regola sopra. La versione successiva vive su un ramo suo
  (`ia/1.2-watch`), tagliato dal ramo della versione aperta, con la sua sezione «in lavorazione» sopra quella
  precedente e `MARKETING_VERSION` già alzata; `registro.py` accetta due sezioni «in lavorazione» una sotto l'altra.
  La versione nuova **non va su TestFlight** finché la precedente non è almeno «inviata»; quando la precedente
  cambia stato, il ramo nuovo si riallinea (merge) e la sua sezione resta in cima. Le correzioni continuano a finire
  nella versione più bassa aperta.
- **Si cambia idea sul numero** (era 1.0.1, è diventata 1.1): si rinomina l'intestazione e si alza `MARKETING_VERSION`
  nella stessa PR, prima della build TestFlight. Dopo una build no.
