# Prompt per ChatGPT — traduzione di NEAT

> Già usato il 19 ottobre 2026: il risultato, controllato, è `NEAT_testi_tradotti.xlsx`.

Da incollare in una nuova chat di ChatGPT, allegando:
- `NEAT_testi_da_tradurre.xlsx` (questa cartella);
- gli screenshot della cartella `screenshot/` (bastano quelli di giorno).

---

Sei un traduttore e localizzatore esperto di app iOS. Devi tradurre i testi di **NEAT**, un'app per iPhone, dall'italiano in 9 lingue: inglese, spagnolo, francese, tedesco, portoghese (Brasile), giapponese, coreano, cinese semplificato e cinese tradizionale.

Ti allego:
1. **NEAT_testi_da_tradurre.xlsx**, con tre fogli: «Istruzioni», «Glossario» (i termini chiave) e «Testi» (173 righe, una per ogni testo dell'app, con schermata, contesto e limite di caratteri).
2. **Gli screenshot** dell'app in italiano, per vedere dove sta ogni testo.

Leggi tutto prima di cominciare.

## Cos'è NEAT

NEAT («NEAT – ogni passo conta») è un'app gratuita per iPhone che risponde a una domanda: **«Quanti minuti devo ancora camminare oggi per raggiungere il mio obiettivo di passi?»**

- Legge i passi di oggi dall'app **Salute** di Apple (Apple Health) e li confronta con l'obiettivo giornaliero (predefinito 10.000 passi).
- Calcola i **minuti di camminata o di tapis roulant** che mancano, alla velocità scelta dall'utente (3–16 km/h). Il calcolo usa la cadenza personale, tarata sugli allenamenti registrati in Salute.
- Tiene una **serie** (streak): i giorni consecutivi con obiettivo raggiunto, con un'icona a fiamma.
- Ha i **Jolly**, bonus che salvano la serie se si salta un giorno. Si parte con 3 Jolly e se ne guadagna 1 ogni 15 giorni di fila; quando serve, il Jolly si usa da solo.
- La sera manda un **promemoria** se l'obiettivo non è ancora raggiunto.
- È pensata per chi vuole muoversi di più nella vita di tutti i giorni: «NEAT» richiama il movimento quotidiano, non sportivo. Non è un'app da atleti.
- È privata: legge soltanto, non scrive nulla in Salute, non ha account e nessun dato esce dal telefono.

**Tono e stile.** La grafica è in stile **manga/fumetto** («Dan Dan Dan»): inchiostro nero, rosso come unico accento, linee cinetiche, scritte inclinate. I titoli usano un carattere **molto stretto e spesso**, sempre in MAIUSCOLO, come le onomatopee dei fumetti. Il tono è diretto, energico e amichevole: si dà del tu, con frasi brevi e parole semplici. Niente gergo da fitness, niente toni da coach motivazionale esagerato.

## Le schermate

1. **Introduzione** (4 pagine, solo al primo avvio):
   - Benvenuto: «BENVENUTO SU» + NEAT gigante + due righe su cosa fa l'app.
   - Salute: perché serve l'accesso ai passi, con la rassicurazione che è solo lettura.
   - Obiettivo: scelta dei passi al giorno con i bottoni − e +.
   - Promemoria: interruttore e orario.
   - In basso, un bottone rosso CONTINUA, che nell'ultima pagina diventa INIZIA.
2. **Home**: una grande illustrazione di una scarpa da corsa su una strada.
   - In alto a sinistra: PASSI DI OGGI, il numero gigante e «SU 10.000».
   - In basso a destra: MINUTI MANCANTI, il numero, «min» e i km.
   - In basso: un cursore della velocità che scorre sulla strada disegnata.
   - A obiettivo raggiunto, al posto dei minuti compaiono «OBIETTIVO RAGGIUNTO» e «FATTO!».
   - Se Salute non dà dati, compare un avviso con il percorso nelle impostazioni.
   - Toccando il numero si possono correggere i passi a mano.
3. **Barra in alto**:
   - Un bottone rosso che passa da Home a Storico e viceversa.
   - La fiamma con i giorni di serie e il numero dei JOLLY.
   - Un bottone per le Impostazioni.
4. **Storico**:
   - Il numero gigante della serie («GIORNI DI FILA!»), i Jolly pronti, «LA MIA SERIE PIÙ LUNGA» e «PROSSIMO JOLLY» con 15 tacche.
   - «I MIEI PASSI»: un grafico a barre con le schede SETTIMANA / MESE / ANNO / SEMPRE e la scelta PASSI / KM.
   - «IL MIO MEGLIO»: i record per giorno, settimana, mese, anno e serie.
5. **Impostazioni**: un foglio in stile iOS più sobrio (carattere normale, non manga). Contiene:
   - obiettivo, promemoria serale e tema (Sistema / Orario / Giorno / Notte);
   - le regole di serie e Jolly;
   - privacy, supporto, «Rivedi l'introduzione» e versione.
6. **Festa**: una schermata a tutto schermo che compare quando si raggiunge l'obiettivo, con «OBIETTIVO RAGGIUNTO!».
7. **Widget**: per la schermata Home di iOS (piccolo e medio) e per il blocco schermo (tondo, rettangolare e in linea).
8. **Notifica serale** e **testi dei permessi** che iOS mostra quando l'app chiede di leggere Salute.

## Cosa devi fare

### Passo 1 — Glossario (poi fermati)

Compila il foglio «Glossario»: per ogni termine, la traduzione in ciascuna delle 9 lingue e, nell'ultima colonna, 1–2 alternative con il perché.

Attenzione in particolare a:
- **Jolly**: è il nome di un bonus del gioco, deve essere breve, simpatico e funzionare in MAIUSCOLO. In inglese, per esempio, valuta Joker, Freeze, Wildcard e Save.
- **serie/streak**: in italiano usiamo tutte e due le parole. Nelle traduzioni scegli **un solo termine** per lingua e usalo ovunque.
- **Salute**: usa il **nome ufficiale** dell'app Apple Health in ciascuna lingua.

**Mostrami il glossario in una tabella e aspetta la mia approvazione prima di passare al passo 2.**

### Passo 2 — Traduzione

Compila nel foglio «Testi» tutte le colonne gialle, una per lingua, seguendo il glossario approvato. Regole:

1. **{segnaposto}**: le parole tra graffe (es. `{passi}`, `{obiettivo}`, `{min}`) vanno copiate **identiche**. Puoi spostarle dove serve nella frase, ma non tradurle né toglierle.
2. **MAIUSCOLO**: se l'italiano è tutto maiuscolo, scrivi la traduzione tutta in maiuscolo. Per giapponese, coreano e cinese questa regola non si applica.
3. **Limite di caratteri**: è indicativo, ma i titoli manga hanno poco spazio. Se la traduzione naturale lo supera, scegline una più corta e spiegalo in «Note del traduttore». Le 4 schede dello Storico e le 5 schede di «IL MIO MEGLIO» sono affiancate e strettissime: puoi abbreviare con il punto, come «SETTIM.».
4. **Tipo VoiceOver**: sono testi letti ad alta voce per chi non vede e non compaiono sullo schermo. Scrivi frasi naturali da ascoltare, senza limite di lunghezza.
5. **Tipo Sistema**: testi che mostra iOS. I testi dei permessi di Salute sono controllati anche da Apple: devono essere chiari, completi e non promettere niente di più di quello che dice l'italiano.
6. **Singolare e plurale** sono righe separate (`.one` / `.other`). In giapponese, coreano e cinese scrivi la stessa frase nelle due righe, adattata.
7. **km e km/h restano così** in tutte le lingue, senza miglia. **NEAT resta NEAT.**
8. Nomi di mesi e giorni, numeri e date **non sono nell'elenco**: li formatta iOS.
9. **Nel cinese tradizionale** usa la variante di Taiwan.
10. **Coerenza**: lo stesso testo italiano in più righe (es. «PASSI», «OBIETTIVO») va tradotto sempre allo stesso modo, salvo un contesto diverso indicato nella colonna «Contesto».
11. Usa la colonna «Note del traduttore» per dubbi, abbreviazioni e scelte che vuoi farmi controllare.

### Passo 3 — Consegna

1. Restituiscimi il file **.xlsx compilato**, con la stessa struttura: stessi fogli, stesse colonne, stesso ordine delle righe e nessuna colonna grigia modificata.
2. Aggiungi un breve riepilogo con:
   - le righe in cui hai superato il limite di caratteri;
   - le abbreviazioni che hai usato;
   - i dubbi da verificare con un madrelingua, soprattutto per giapponese, coreano e cinese.
