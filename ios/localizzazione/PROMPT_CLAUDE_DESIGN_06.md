# Prompt per Claude Design — screenshot 6 della 1.1 (10 lingue)

Si usa **dopo** le traduzioni di ChatGPT (`PROMPT_CHATGPT_1.1.md`), quando ci sono:
1. le didascalie nuove di `shot6.title` e `shot6.sub` nelle 10 lingue (foglio `NEAT_store_tradotto.xlsx`);
2. le schermate dell'app con la frase nuova della pagina Salute (`intro.2.p2`), rifatte da Claude sul simulatore in 10
   lingue con `scripts/screenshots.sh` (`intro-2-day_<lingua>.png`).

Claude prepara lo zip `NEAT_06_per_Claude_Design.zip` con, per ogni lingua:
- `06_attuale.jpg`: lo screenshot 6 pubblicato con la 1.0 (`store/screenshots/<lingua>/06.jpg`);
- `intro-2-day_<lingua>.png`: la schermata nuova dell'app;
- `didascalie.txt`: titolo (con « / » dove va a capo), sottotitolo e le tre etichette, uguali al foglio.

La tabella delle didascalie in fondo la compila Claude con i testi tornati da ChatGPT.

---

Dobbiamo rifare **un solo screenshot della pagina App Store di NEAT, il sesto** (privacy), in 10 lingue. Gli altri
cinque restano come sono. Lo hai già disegnato tu: ti allego, per ogni lingua, la versione attuale (`06_attuale.jpg`),
che è il **riferimento da rispettare** in tutto, tranne tre cose.

## Cosa cambia

1. **Titolo:** al posto di «I TUOI DATI RESTANO SUL TUO IPHONE» va **«I TUOI DATI SONO SOLO TUOI»** (traduzioni sotto).
2. **Sottotitolo** (etichetta nera sotto il titolo): al posto di «Nessun dato lascia il telefono» va **«Nessuno li vede,
   nemmeno noi»** (traduzioni sotto).
3. **Schermata nel telefono:** la pagina «Salute» dell'introduzione è cambiata. La frase sotto il paragrafo ora dice «I
   tuoi dati non lasciano mai il tuo account.». Usa la schermata nuova allegata (`intro-2-day_<lingua>.png`) al posto di
   quella dentro `06_attuale.jpg`.

## Cosa resta identico

- Formato **1320 × 2868 px**, PNG, stesso fondo con le linee cinetiche, stessa sagoma dell'iPhone con l'ombra rossa,
  stessa posizione e inclinazione di titolo e sottotitolo.
- Le tre etichette **NIENTE ACCOUNT · NIENTE PUBBLICITÀ · NIENTE TRACCIAMENTO**, già tradotte, nella stessa posizione.
- Stile, font (Anton per titoli ed etichette; per giapponese, coreano e cinese lo stesso font spesso della versione
  attuale), colori (inchiostro #141414, rosso #E5231B, carta #FFFFFF).
- Il titolo va a capo **solo** dove c'è « / » nella tabella (« / » non si scrive). Al massimo 2 righe.

## Consegna

- 10 PNG, uno per lingua, con questi nomi: `06_dati-iphone_<lingua>.png` (it, en, es, fr, de, pt-BR, ja, ko, zh-Hans,
  zh-Hant).
- Un'immagine di controllo con i 10 risultati affiancati in piccolo, così si vede subito se una lingua è diversa
  dalle altre.
- Nelle note, ogni lingua in cui hai dovuto ridurre il testo o cambiare l'a capo, e perché.

## Didascalie (identiche al foglio, non cambiarle)

| Lingua | Titolo (« / » = a capo) | Sottotitolo |
|---|---|---|
| it | I TUOI DATI / SONO SOLO TUOI | Nessuno li vede, nemmeno noi |
| en | *(da ChatGPT)* | *(da ChatGPT)* |
| es | *(da ChatGPT)* | *(da ChatGPT)* |
| fr | *(da ChatGPT)* | *(da ChatGPT)* |
| de | *(da ChatGPT)* | *(da ChatGPT)* |
| pt-BR | *(da ChatGPT)* | *(da ChatGPT)* |
| ja | *(da ChatGPT)* | *(da ChatGPT)* |
| ko | *(da ChatGPT)* | *(da ChatGPT)* |
| zh-Hans | *(da ChatGPT)* | *(da ChatGPT)* |
| zh-Hant | *(da ChatGPT)* | *(da ChatGPT)* |
