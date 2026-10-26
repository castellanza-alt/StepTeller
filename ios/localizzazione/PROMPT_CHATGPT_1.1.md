# Prompt per ChatGPT — testi della versione 1.1 di NEAT

Da incollare nella **stessa chat di ChatGPT che ha tradotto l'app e la scheda** (conosce già app e glossario),
allegando i tre file di questa cartella:
- `NEAT_novita.xlsx`
- `NEAT_store_tradotto.xlsx`
- `NEAT_testi_tradotti.xlsx`

Se usi una chat nuova, va bene lo stesso: il glossario è nel foglio «Glossario» di `NEAT_testi_tradotti.xlsx`.

---

NEAT ha una versione nuova, la **1.1**. Le novità per chi usa l'app:
- serie, obiettivi e impostazioni si salvano anche nel **proprio iCloud** (mai i dati di Salute, nessun server nostro):
  cambiando iPhone o reinstallando l'app si ritrova tutto;
- in Impostazioni c'è una sezione nuova, **Backup**, per salvare gli stessi dati in un file e ricaricarli;
- il **promemoria serale** è stato corretto.

Per questo la vecchia promessa «nessun dato lascia il telefono» non è più vera. La nuova promessa è **«i tuoi dati sono
solo tuoi»**: lo sviluppatore non riceve niente e nessuno tranne l'utente può vedere quei dati.

Ti allego tre file. In ognuno ci sono **solo poche righe da fare**, elencate qui sotto. **Tutto il resto non va
toccato**: né le altre righe, né le colonne grigie.

## 1. `NEAT_novita.xlsx`, foglio «Novità», riga `novita.1.1`

Testo «Novità di questa versione» per l'App Store. L'italiano è approvato. Traduci nelle 9 colonne gialle e aggiorna
«Caratteri usati». La riga `novita.correzioni` non va toccata.

- Ogni punto resta un punto, nello stesso ordine, con «• » all'inizio della riga. Il paragrafo iniziale resta un
  paragrafo.
- Massimo 4000 caratteri per lingua (qui ne bastano circa 500).

## 2. `NEAT_store_tradotto.xlsx`, foglio «Store», quattro righe: `store.promo`, `store.description`, `shot6.title`, `shot6.sub`

Le traduzioni ci sono già. In promozionale e descrizione è cambiata solo una frase: **cambia solo la frase
corrispondente** in ogni lingua e lascia il resto com'è, parola per parola. Le due didascalie cambiano per intero.

**`store.promo`** (limite rigido: 170 caratteri)
- Prima: «I tuoi dati restano sul tuo iPhone.»
- Ora: «I tuoi dati sono solo tuoi.»

**`store.description`**, penultimo paragrafo
- Prima: «I tuoi dati restano sul tuo iPhone. NEAT legge soltanto: niente account, niente pubblicità, niente
  tracciamento. Nessun dato lascia il telefono.»
- Ora: «I tuoi dati sono solo tuoi. NEAT legge soltanto: niente account, niente pubblicità, niente tracciamento. Serie
  e impostazioni si salvano nel tuo iCloud, mai su server di altri. Cambi iPhone? Ritrovi la tua serie.»

«i tuoi dati sono solo tuoi» deve suonare naturale e uguale in tutte e tre le righe (es. EN «Your data is yours
alone.»). «iCloud» e «iPhone» restano così.

**`shot6.title` e `shot6.sub`**: le didascalie del sesto screenshot (verrà rifatto)
- Titolo (≤ 36, MAIUSCOLO, a capo segnato con « / », al massimo 2 righe; obbligatorio in giapponese, coreano e cinese)
  - prima: «I TUOI DATI RESTANO SUL TUO IPHONE»
  - ora: «I TUOI DATI SONO SOLO TUOI», con le stesse parole di `store.promo` (salvo maiuscole e punto finale)
- Sottotitolo (≤ 34)
  - prima: «Nessun dato lascia il telefono»
  - ora: «Nessuno li vede, nemmeno noi» (= nemmeno chi ha fatto l'app)

Le tre etichette `shot6.tag*` restano uguali. Aggiorna le note di `store.promo`, `shot6.title` e `shot6.sub` che parlano
della vecchia promessa.

## 3. `NEAT_testi_tradotti.xlsx`, foglio «Testi», 12 righe: le 11 `set.backup.*` e `intro.2.p2`

Le traduzioni sono **bozze di Claude** (nota «Bozza di Claude (1.1), da confermare con ChatGPT»): **controllale e
correggile** come hai fatto per il resto dell'app.

- `set.backup.*`: i testi della nuova sezione Backup delle Impostazioni.
- `intro.2.p2`: la frase della pagina Salute dell'introduzione, sotto il titolo «I TUOI PASSI, SOLO DA LEGGERE». Prima
  era «Non scrive niente e nessun dato esce dal telefono.», ora è «I tuoi dati non lasciano mai il tuo account.».
  «account» è l'account Apple dell'utente (quello di iCloud): NEAT non ha account suoi. Usa la parola che Apple usa
  per l'account Apple nella lingua. Massimo 70 caratteri.

- Rispetta il limite di caratteri della colonna «Limite» e i segnaposto tra graffe (`{data}` resta identico).
- «streak» nella nota e nella conferma = la serie del glossario (racha, série, Serie, sequência, 連続記録, 연속 기록, 连续记录,
  連續紀錄).
- «Salute» = nome ufficiale dell'app Apple Health nella lingua.
- Quando una riga è confermata o corretta, sostituisci la nota con «Confermata da ChatGPT (1.1)» oppure «Corretta da
  ChatGPT (1.1): …» con il motivo in poche parole.

## Regole comuni

1. Traduci il senso, non parola per parola. Nessuna funzione in più o in meno, nessun aggettivo aggiunto.
2. Glossario già approvato: Jolly (Joker, Comodín, Joker, Joker, Coringa, おまもり, 지킴이, 护身符, 護身符), serie, obiettivo,
   promemoria, widget, Salute.
3. Tono come la scheda: semplice e diretto, con il tu o la forma naturale della lingua per le app. Frasi corte.
4. Niente promesse sulla salute (calorie, peso, longevità, prevenzione): Apple le rifiuta.
5. Niente promesse assolute sulla privacy («totale», «al 100%», «completamente sicuro»).
6. Cinese tradizionale: variante di Taiwan.

## Consegna

1. Restituiscimi i **tre file .xlsx** compilati, con la stessa struttura e lo stesso nome.
2. Aggiungi un breve riepilogo:
   - per lo store, le frasi nuove e le didascalie in ogni lingua, con i conteggi;
   - per il Backup e l'introduzione, le righe che hai corretto e perché;
   - i dubbi da far vedere a un madrelingua.
