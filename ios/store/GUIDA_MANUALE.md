# Passi a mano su App Store Connect (non disponibili nell'API)

Da fare una volta, da computer o telefono (Safari), su https://appstoreconnect.apple.com con l'account sviluppatore.
I nomi dei menu possono essere in italiano o in inglese: sono indicati tutti e due.

## 1. Privacy dell'app → «Dati non raccolti»

1. **App** → **NEAT** (o «Step Teller», se il nome non è ancora cambiato).
2. Nella colonna a sinistra: **Privacy dell'app** (*App Privacy*).
3. **URL della politica sulla privacy**: deve già comparire
   `https://castellanza-alt.github.io/StepTeller/neat/privacy/` (lo imposta lo script). Se è vuoto, incollarlo.
4. **Inizia** (*Get Started*) accanto a «Raccolta di dati».
5. Domanda «Tu o i tuoi partner raccogliete dati da questa app?» → **No, non raccogliamo dati da questa app**
   (*No, we do not collect data from this app*) → **Salva**.
6. In alto a destra: **Pubblica** (*Publish*). Sulla scheda comparirà «Dati non raccolti».

## 2. Stato di operatore commerciale UE (DSA) → non-trader

1. Dalla pagina iniziale di App Store Connect: **Attività** (*Business*).
2. Sezione **Digital Services Act** (o il riquadro «Conformità» / *Compliance*) → **Completa** / **Modifica**.
3. Alla domanda se sei un operatore commerciale (*trader*): **Non sono un operatore commerciale**
   (*I'm not a trader*) → conferma.
4. Effetto: l'app resta disponibile nell'Unione Europea, senza indirizzo e telefono pubblici sulla scheda.

## 3. Accordi e termini

1. **Attività** (*Business*) → **Accordi** (*Agreements*).
2. Se compare un riquadro giallo/rosso con termini nuovi da accettare (Apple Developer Program License Agreement
   o «Accordo per app gratuite»), aprirlo e accettarlo. Per un'app gratuita **non** servono l'accordo per app a
   pagamento, i dati bancari né quelli fiscali.
3. Se in alto nella pagina iniziale c'è un avviso «Rivedi l'accordo aggiornato», accettarlo: senza, Apple blocca
   l'invio in revisione.

## 4. Da controllare prima dell'invio (facoltativo)

- **Rilascio della versione** (pagina della versione 1.0, in fondo): di base l'app esce **da sola appena approvata**.
  Per decidere il giorno, scegliere «Rilascia manualmente questa versione».
- **Cina continentale**: Apple può chiedere un numero di registrazione ICP; se nel riepilogo di `[store]` la Cina
  risulta non attivabile, l'app esce ovunque tranne lì (nessuna azione richiesta).

Poi, solo dopo l'ok di Will: commit con `[store-invio]` (vedi `README.md`).
