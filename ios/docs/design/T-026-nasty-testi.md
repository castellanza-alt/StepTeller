# T-026 NASTY (1.3): privacy, store e testi dell'interfaccia

**Director, 19/11/2026.** Bozza in italiano per William (D-005: si traduce solo dopo il suo ok). Richiesta di William:
«sarà da aggiornare anche la pagina della privacy e preparare tutta la parte di aggiornamento dei testi».

## 1. Testi nuovi dell'interfaccia (dalla tela T-023)
1. Introduzione, domanda: «Vuoi che te lo dica gentilmente o che te lo dica davvero?» Scelte: «Normale» · «Piccante» ·
   «NASTY».
2. Avviso prima di NASTY: «Parolacce e insulti. L'hai voluto tu.» Tasti: «Annulla» · «NASTY».
3. Impostazioni, sezione: «Voce». Nota: «Piccante: sarcasmo. NASTY: parolacce e insulti. NEAT commenta i tuoi passi
   nell'app e nelle notifiche.»
4. Manopola: «Notifiche di NEAT» · «Poche» · «Normali» · «Tante». NASTY: 2, 4–5, 7 al giorno. Piccante: 1, 1–2, 3.
5. VoiceOver del cuore: «NEAT. Tocca per un'altra battuta.»

## 2. Pagina della privacy (`neat/privacy/index.html`, italiano e inglese)
**«In breve», frase da aggiungere in fondo:**
> Se scegli la voce Piccante o NASTY, NEAT scarica dal suo sito l'elenco aggiornato delle battute: è un file uguale
> per tutti, e l'app non invia nessun tuo dato.

**Sezione nuova «Le battute di NEAT», dopo «Dove restano i dati»:**
> Con la voce Piccante o NASTY, NEAT sceglie le battute sul telefono, in base ai tuoi passi e al tuo obiettivo. Una
> volta al giorno scarica dal sito di NEAT (ospitato su GitHub Pages) il file con l'elenco aggiornato delle battute.
> È un file pubblico, uguale per tutti: l'app lo legge soltanto e non invia passi, obiettivi né altri dati. Come per
> qualsiasi pagina web, il servizio che ospita il sito (GitHub) riceve l'indirizzo IP da cui parte la richiesta; lo
> sviluppatore non lo vede e non lo conserva. Con la voce Normale l'app non scarica niente.

**«Notifiche», testo che sostituisce l'attuale** (oggi parla solo del promemoria serale: mancano già gli avvisi
della 1.2):
> Tutte le notifiche di NEAT sono notifiche locali: il promemoria serale, gli avvisi di obiettivo e Jolly e, se hai
> scelto la voce Piccante o NASTY, le battute. Vengono calcolate e programmate sul telefono, senza alcun server. Puoi
> spegnerle o ridurle in NEAT (Impostazioni → Notifiche e Impostazioni → Voce) oppure in Impostazioni di iOS →
> Notifiche → NEAT.

**«Cosa NEAT non fa», primo punto, che sostituisce l'attuale:**
> Nessun server dello sviluppatore: l'app non invia dati a nessuno. Gli unici scambi sono la copia nel tuo iCloud,
> fatta da iOS, e lo scaricamento dell'elenco delle battute, che non contiene e non invia dati tuoi.

**«Dove restano i dati», preferenze:** aggiungere «voce scelta e frequenza delle notifiche» all'elenco, anche nella
copia in iCloud. Data in cima: quella della pubblicazione.

## 3. Scheda dello store (senza parolacce: i testi dello store li legge chiunque)
**Novità 1.3**
> NEAT adesso ha una voce. E non è gentile.
>
> Scegli quanto vuoi sentirti dire la verità sui tuoi passi:
> • Normale: l'app di sempre.
> • Piccante: sarcasmo, senza sconti.
> • NASTY: nessuna pietà, parolacce comprese. L'hai voluto tu.
>
> NEAT commenta nell'app e nelle notifiche, e impara battute nuove senza bisogno di aggiornamenti. Di serie resta
> Normale: la voce la scegli tu, nell'introduzione o nelle Impostazioni.
>
> • Correzioni e piccoli miglioramenti.

**Descrizione, paragrafo nuovo prima di «I tuoi dati sono solo tuoi»:**
> Vuoi una spinta in più? Dai una voce a NEAT. Piccante, per un po' di sarcasmo sui tuoi passi. NASTY, se vuoi
> sentirti dire tutto, parolacce comprese. Di serie è spenta.

**Testo promozionale (al posto dell'attuale):**
> NEAT ora ti dice cosa pensa dei tuoi passi. Tre voci: Normale, Piccante, NASTY. Scegli con coraggio.

**Nome, sottotitolo, parole chiave, screenshot:** invariati (parole chiave: valutare «motivazione» al posto di
«tapis roulant»; decide William).

## 4. Apple
- Classificazione: «parolacce o umorismo volgare: frequenti» → 13+ (D-044).
- Scheda privacy dello store: resta «nessun dato raccolto» (l'app scarica un file e non invia nulla).
- Note per il revisore (inglese, le scrive il Director): come attivare i livelli; che NASTY è una scelta
  dell'utente con avviso; che l'app scarica un file statico di testi da GitHub Pages e non invia dati.

## 5. Dopo l'ok di William
Traduttore: interfaccia, privacy inglese, Novità e scheda nelle 9 lingue. Developer: testi nell'app e nella pagina.
