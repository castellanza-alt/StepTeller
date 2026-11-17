# T-008 Voce «NASTY»: carattere e testi italiani

**Designer, 17/11/2026.** Regole: D-039. Anteprima ferma: https://claude.ai/artifact/VoQCuAcpUoGyEzCnnbPGeC (sorgente `T-008-nasty/anteprima.html`; le immagini `img/` sono quelle ridotte di `T-004-natale/img/`).
Solo italiano: le traduzioni partono dopo l'ok di William (D-005).

## 1. Carattere

### 1.1 Due personaggi a confronto
| | **A. Hargreaves, il maggiordomo** (proposto) | B. La Professoressa di Oxford |
|---|---|---|
| Chi è | maggiordomo inglese di lunga carriera, al suo servizio e profondamente deluso, con garbo | docente severa che dà i voti alla giornata |
| A zero passi | «Il contapassi segna zero. Ho controllato: non è rotto. Si alzi, prego.» | «Zero passi. Voto: non classificato. Si presenti all'appello, in cortile.» |
| Obiettivo basso | «Obiettivo registrato. Lo farò incorniciare accanto al telecomando. Ora però si cammina.» | «Quattromila? Un compito svolto con la cura di chi lo copia. Rifaccia, più in alto.» |
| Jolly usato | «Ho usato un Jolly per coprirla. Non lo dirò a nessuno. Lei però cammini.» | «Jolly usato. Giustificazione accettata, firmata dal divano. Oggi interrogo io: i passi.» |

**Scelta: A, Hargreaves.** Motivi:
1. La finta cortesia è il cuore dell'umorismo inglese: un servitore impeccabile che umilia restando gentile fa ridere
   più di un'insegnante che rimprovera.
2. Il maggiordomo **sta dalla parte** di chi usa l'app: è deluso perché ci tiene. La Professoressa giudica dall'alto, e
   alla lunga sa di punizione, il contrario della spinta a camminare.
3. Il «Lei» del maggiordomo è neutro rispetto al genere e regge 10 lingue (in inglese il tono è naturale).

### 1.2 Registro
- Dà del **Lei**. Frasi brevi, punto fermo, niente esclamazioni (tranne rarissime, per finto entusiasmo).
- **Understatement**: dice meno di quel che pensa («Rispettabile. Quasi da persona che esce di casa.»).
- **Finta cortesia**: «prego», «se permette», «con tatto»; la cortesia è la lama.
- **Ironia secca**: nessuna battuta spiegata, nessuna emoji, nessun punto esclamativo per far ridere.
- Parla del **comportamento** e degli **oggetti** della pigrizia: divano, poltrona, telecomando, scuse, porta di casa,
  scarpe all'ingresso. Il divano è il suo antagonista ricorrente.
- Firma i fumetti con «— H.».

### 1.3 Cosa non fa mai (D-039)
- Niente parolacce, nemmeno attenuate. Niente insulti diretti («pigro», «scemo»…): osserva, non etichetta.
- **Mai** corpo, peso, forma, aspetto, salute, malattie, età, genere, provenienza o altre caratteristiche personali.
  Niente parti del corpo, cibo come colpa, medici, «alla sua età».
- **Nessun aggettivo o participio che riveli il genere** di chi legge («stanco/stanca», «è arrivato/a»): si usano «avere»,
  il Lei, i sostantivi. Controllato su ogni testo qui sotto.
- Mai sui dati di Salute oltre i passi. Mai cattivo nei momenti delicati: a serie persa è asciutto ma incoraggiante.

### 1.4 Ogni battuta chiude con una spinta
Struttura fissa: **osservazione → stoccata → invito a muoversi** («Si alzi, prego.», «La porta è da quella parte.»,
«In marcia.», «Domani si replica.»). Quando l'obiettivo è già raggiunto la spinta guarda a domani o a continuare.

### 1.5 Come si scelgono le varianti
- Punti fissi (Home, Storico, widget, obiettivo): **una variante al giorno per punto**, scelta a caso con seme
  data + punto, mai la stessa del giorno prima. Cambia solo se cambia la fascia (es. da «metà» a «quasi»).
- Eventi (notifiche, pop-up, cambio di obiettivo): a caso a ogni evento, mai la stessa due volte di fila.
- Segnaposti: `{passi}` `{obiettivo}` `{mancano}` `{minuti}` `{velocita}` `{serie}` `{jolly}`, numeri con
  `LocalFormat`. Le varianti senza segnaposto restano valide anche se il numero manca.

## 2. Dove parla (con limiti di caratteri)

| Punto | Dove si vede | Limite | Sostituisce |
|---|---|---|---|
| Obiettivo | Impostazioni, riga sotto il numero, sopra la nota | 90 | — (si aggiunge) |
| Home | fumetto (§3) | 75 | — |
| Storico | fumetto (§3) | 75 | — |
| Serie e Jolly | frase dei pop-up T-005 (righe c–d) | 75 | testi di `jolly.earned.days` / `jolly.used.*` |
| Festa obiettivo | titolo della festa | 24 | «OBIETTIVO RAGGIUNTO!» |
| Promemoria serale | notifica | titolo 30, corpo 140 | testi di `Reminder.swift` |
| Notifiche T-006 | notifica | titolo 30, corpo 120 | testi `notif.*` di T-005 |
| Introduzione | primo paragrafo di ogni pagina | 120 | `intro.N.p1` (e `intro.3.title` resta) |
| Impostazioni, voce | nota sotto la scelta | 110 | — |
| Widget medio | etichetta sopra i passi | 18, maiuscolo | «PASSI DI OGGI» |

### 2.1 Scelta dell'obiettivo (fasce sul nuovo valore; «ritocco» se cambia rispetto a ieri)
**Basso (sotto 5.000)**
1. «{obiettivo} passi. Ambizione notevole, per una pianta d'appartamento. Proviamo a salire un poco?»
2. «Obiettivo registrato. Lo farò incorniciare accanto al telecomando. Ora però si cammina.»
3. «Un traguardo prudente. Anche le lumache hanno una reputazione da difendere. Su, le scarpe.»
4. «Un passo alla volta, d'accordo. Possibilmente più di uno. Si alzi, prego.»

**Medio (5.000–9.999)**
1. «{obiettivo}. Rispettabile. Quasi da persona che esce di casa. Dimostri che non è un caso.»
2. «Un numero onesto. Non lo racconterei a cena, ma è un inizio. In marcia.»
3. «Obiettivo sensato. Lo dico con una certa sorpresa. Ora lo onori.»

**Alto (da 10.000)**
1. «{obiettivo}. Audace. Avviso il divano che stasera resterà solo.»
2. «Ottimo. Ho preso nota, e prenderò nota anche di come finisce. Cominci pure adesso.»
3. «Un obiettivo serio. Vediamo se ai numeri seguono i passi. Fuori, prego.»

**Ritocco al ribasso**
1. «Abbassato. Naturalmente. Capitolo "Trattative con il divano". Ora però cammini.»
2. «Lo sconto è applicato. I passi, purtroppo, non si scontano da soli. Prego, la porta.»
3. «Capisco: l'obiettivo era troppo esigente. Lei no, a quanto pare. Recuperi oggi.»

**Ritocco al rialzo**
1. «Rialzato. Mi commuovo, con moderazione. Adesso lo dimostri al marciapiede.»
2. «Ha alzato l'asticella. Ora la scavalchi, a piedi.»
3. «Un gesto coraggioso. Il coraggio però si misura in passi. Vada.»

### 2.2 Home (fumetto)
**A zero**
1. «Zero passi. Una giornata di grande raccoglimento. La porta è da quella parte.»
2. «Nessun passo. Immagino stia meditando. Mediti camminando, prego.»
3. «Il contapassi segna zero. Ho controllato: non è rotto. Si alzi, prego.»
4. «Oggi finora: nulla. Discreto, elegante, immobile. Cambiamo l'ultima parola?»

**Sotto la metà**
1. «{passi} passi. Un inizio timido. Ne mancano {mancano}: si avvii.»
2. «Siamo all'antipasto. Il piatto forte sono {minuti} minuti di cammino.»
3. «Procede. Lentamente, ma procede. Altri {minuti} minuti e ne riparliamo.»

**Dalla metà**
1. «A metà strada. Il divano la reclama: finga di non sentire.»
2. «Metà fatta. L'altra metà non si farà da sola, glielo assicuro.»
3. «Bene. Non lo dico spesso. Ancora {minuti} minuti, per non farmene pentire.»

**Quasi (dall'85 %)**
1. «Mancano {mancano} passi. Fermarsi qui sarebbe imbarazzante. Per entrambi.»
2. «Quasi. "Quasi" non si mette in bacheca. {minuti} minuti, prego.»
3. «Un ultimo sforzo, e dovrò ammettere di averla sottovalutata.»

**Fatto**
1. «Obiettivo raggiunto. Sono colpito; mi riprenderò presto. Domani si replica.»
2. «Fatto. Lo annoto con una sorpresa che tenterò di nascondere. A domani.»
3. «Complimenti sinceri. Non ci si abitui: domani si riparte da zero.»

**Molto oltre (dal 150 %)**
1. «{passi} passi. Ora sta solo dando spettacolo. Continui pure.»
2. «Il divano ha chiesto sue notizie. Gli ho detto di non aspettarla.»
3. «Devo rivedere ciò che pensavo di lei. Quasi tutto. Domani di nuovo.»

### 2.3 Storico (fumetto)
**Giorni mancati nel periodo mostrato**
1. «Vedo dei buchi nel calendario. "Pause di riflessione", immagino. Oggi si riflette camminando.»
2. «Alcuni giorni mancano all'appello. Non insisterò. Insisteranno i passi di oggi.»
3. «Un mese a macchia di leopardo. Elegante, ma oggi preferirei la tinta unita.»

**Record nuovo (giorno, settimana, mese, anno o serie)**
1. «Un record. Lo metto in cornice, accanto ai buoni propositi. Ora lo superi.»
2. «Il suo meglio di sempre. Finora. È una minaccia affettuosa.»
3. «Record battuto. Il record precedente, il suo, si dichiara offeso. Rivincita domani.»

**Nessuno dei due** (periodo pieno, nessun record): «Un periodo senza buchi. Non ho nulla da ridire, e la cosa mi
irrita. Continui.» · «Tutto in ordine. Sospetto. Lo verifichi camminando anche oggi.» · «Regolare come un orologio
svizzero. Io preferisco quelli inglesi. Avanti.»

### 2.4 Serie e Jolly (pop-up T-005, righe c–d; la targhetta col numero di Jolly resta quella di T-005)
**Jolly guadagnato**
1. «{serie} giorni di fila. Le concedo un Jolly e un sopracciglio alzato. Avanti così.»
2. «Un Jolly. Le servirà, lo sappiamo entrambi. Continui come se non ce l'avesse.»
3. «Jolly guadagnato. Lo custodisco io; lei pensi a camminare.»

**Jolly usato**
1. «Ieri niente obiettivo. Il Jolly ha pagato il conto. Oggi offre lei, in passi.»
2. «Ho usato un Jolly per coprirla. Non lo dirò a nessuno. Lei però cammini.»
3. «Serie salva, dignità in revisione. Oggi la si ripara a piedi.»

**Jolly finiti** (usato l'ultimo)
1. «Jolly esauriti. Da qui in avanti si cammina senza rete.»
2. «La cassaforte dei Jolly è vuota. Le consiglio vivamente le scarpe.»
3. «Niente più Jolly. Ora ogni giorno conta davvero, a cominciare da questo.»

**Serie persa** (nuovo evento, stesso pop-up di «usato» senza fiamma: numero «0» in `GlyphText`)
1. «La serie si è interrotta. Un minuto di silenzio, poi si riparte: giorno uno.»
2. «Serie azzerata. Succede nelle migliori famiglie. Si ricomincia oggi.»
3. «Fine della serie. Il record resta, a ricordarle cosa sa fare. Lo rifaccia.»

**Festa dell'obiettivo**, titolo (24 caratteri, maiuscolo): «CONTRO OGNI PREVISIONE!» · «INCREDIBILE, MA VERO.» ·
«L'HA FATTO DAVVERO.» · «ANNOTATO CON STUPORE.»

### 2.5 Promemoria serale (sostituisce `Reminder.swift`)
Con i minuti (titolo / corpo):
1. «Una parola, se permette» / «Mancano {mancano} passi: bastano {minuti} minuti a {velocita} km/h. Il divano può
   attendere; ci è abituato.»
2. «Il tappeto la aspetta» / «{minuti} minuti e la giornata è salva. Non mi costringa a scrivere "quasi" nel registro.»
3. «Promemoria, con tatto» / «È sera e mancano {mancano} passi. Con tutto il tatto possibile: si alzi.»

Aggiunta se il Jolly è a rischio: «Altrimenti stanotte spendo un Jolly. Il suo.»
Aggiunta se la serie è a rischio: «Altrimenti la serie di {serie} giorni finisce stanotte. E io lo annoterei.»
Senza minuti (giorni futuri): «Le scarpe chiedono di lei» / «Apra NEAT: le dirò quanti minuti servono, con la massima
discrezione.»

### 2.6 Notifiche di T-006 (sostituiscono `notif.*` di T-005)
**Obiettivo raggiunto**
1. «Obiettivo raggiunto. Davvero.» / «{passi} passi su {obiettivo}. Ho controllato due volte. Domani si replica.»
2. «Sorpresa piacevole» / «{passi} passi. Mi complimento, e torno a dubitare da domattina.»
3. «Annotato con stupore» / «Serie a {serie} giorni. Non si fermi proprio ora che comincio a crederci.»

**Jolly guadagnato**
1. «Un Jolly per lei» / «{serie} giorni di fila: ora ha {jolly} Jolly. Faccia finta di non averli e continui.»
2. «Jolly in cassaforte» / «Glielo custodisco io. Lei pensi ai passi di oggi.»

**Jolly usato**
1. «Ho coperto la sua assenza» / «Ieri niente obiettivo: un Jolly ha salvato la serie di {serie} giorni. Ne restano
   {jolly}. Oggi tocca alle scarpe.»
2. «Jolly speso» / «La serie di {serie} giorni è salva. La reputazione la ripariamo oggi, a piedi.»
3. Jolly finiti: «Ultimo Jolly speso» / «La serie di {serie} giorni è salva, ma la cassaforte è vuota. Da oggi si
   cammina senza rete.»

### 2.7 Introduzione (una frase per pagina; tre proposte, ne resta una)
La voce si sceglie in Impostazioni, quindi queste frasi si vedono solo con «Rivedi l'introduzione» a NASTY attiva.
- Pagina 1: «Leggo i suoi passi e le dico quanti minuti mancano. Con franchezza, come d'accordo.» · «Sono Hargreaves.
  Conto i suoi passi e, purtroppo per lei, li commento.» · «Le dirò ogni giorno quanto manca. Con garbo, ma glielo dirò.»
- Pagina 2 (Salute): «Leggo soltanto i passi e non ne parlo con nessuno. Solo con lei, purtroppo.» · «Discrezione
  assoluta: i suoi passi restano tra noi. I commenti, invece, glieli faccio.» · «Leggo e non scrivo. Scrivere a
  Salute zero passi sarebbe crudele.»
- Pagina 3 (Obiettivo): «Scelga un numero. Io lo commenterò; lei lo raggiungerà, si spera.» · «Un numero onesto, prego.
  Me ne accorgo, se bara.» · «Scelga con coraggio. O con prudenza: lo noterò comunque.»
- Pagina 4 (Promemoria): «La sera, se manca qualcosa, glielo farò notare. Con garbo. Più o meno.» · «Un avviso la
  sera, quando il divano diventa insistente.» · «Le scriverò la sera. Brevemente, ma lo leggerà.»

### 2.8 Widget medio (etichetta, 18 caratteri, maiuscolo)
A zero: «NEANCHE UN PASSO.» · «IL DIVANO VINCE.» · Sotto la metà: «UN INIZIO TIMIDO.» · «SI PUÒ FARE DI PIÙ.» ·
Dalla metà: «METÀ. NON BASTA.» · «IL DIVANO ATTENDE.» · Quasi: «QUASI. CAMMINI.» · «MANCA POCO. VADA.» ·
Fatto: «SONO COLPITO.» · «CONTRO PRONOSTICO.»

## 3. Il fumetto di Hargreaves (unica novità grafica)
Componente `ButlerBubble`, uguale in Home e Storico, giorno e notte:
- `Vignette(shape: .panelA, width: 230)`: fondo `paper`, bordo `ink` 3 (giorno #FFFFFF / #141414, notte #0E1430 /
  #E2EAFF). Padding interno della vignetta.
- Testo Anton 15, tracking 0,02, `ink`, maiuscolo come il resto della Home, al massimo 3 righe, `minimumScaleFactor` 0,85.
- Firma «— H.» Anton 12, `red` (#E5231B / #FF3B30), allineata a destra, 4 sotto il testo.
- Coda: triangolo pieno `ink` 16 × 12 sotto il bordo inferiore, a 22 dal lato sinistro, punta in basso a sinistra.
- Trasformazione `manga(rotate: -4, skew: -6, anchor: .topLeading)`.
- **Home**: in (20, 340), lo spazio degli avvisi (`notices`); se c'è l'avviso «Nessun dato da Salute» il fumetto non c'è.
  **Storico**: in (148, 704), tra i pannelli delle serie e «I MIEI PASSI».
- Entrata quando appare o cambia testo: scala 0,85 → 1 con `.spring(duration: 0.4, bounce: 0.35)` e opacità 0 → 1 in
  0,15 s. Riduci movimento: solo opacità 0,2 s.
- VoiceOver: legge il testo, poi «Hargreaves» (`voice.signature.vo`).
- Con la voce normale il fumetto non esiste: la Home resta quella di oggi.

Nient'altro cambia nella grafica: stessi colori, stessa icona, stessi font.

## 4. Scelta della voce in Impostazioni
- Nuova sezione **«Voce»** (`set.voice.section`) subito dopo «Obiettivo giornaliero».
- `Picker` a segmenti: «**Normale**» (`set.voice.normal`) · «**NASTY**» (`set.voice.nasty`). Di serie: Normale.
- Nota sotto (`set.voice.note`): «NASTY: Hargreaves, maggiordomo inglese, commenta i suoi passi. Niente parolacce,
  solo verità scomode.»
- Al cambio, riga sotto la nota per 4 s (testo `ink` 13, corsivo di sistema, poi sparisce in 0,3 s):
  - accesa: «Ottima scelta. Da ora le dirò la verità. Cominciamo con una passeggiata.» · «Al suo servizio. Le scarpe
    sono all'ingresso, come sempre.» · «Molto bene. Avviso il divano che i tempi sono cambiati.»
  - spenta: «Mi ritiro. Cammini anche senza di me, mi raccomando.» · «Come desidera. La sorveglierò in silenzio.» ·
    «Torno in dispensa. I passi però li conto lo stesso.»

## 5. Conteggio per l'approvazione
Personaggio: 1 scelta tra A e B. Testi italiani: obiettivo 16, Home 19, Storico 9, serie e Jolly 12 + 4 titoli della
festa, promemoria 6, notifiche 8, introduzione 12 (ne restano 4), widget 10, Impostazioni 4 + 6 righe di cambio +
1 VoiceOver. Totale proposte **107**, di cui da tradurre **≈ 99** dopo la scelta delle frasi d'introduzione.

## 6. Cosa resta aperto
- Evento «serie persa» (§2.4) non esiste ancora in T-006: va aggiunto se William approva il testo.
- Nome del personaggio: «Hargreaves» è una proposta; si cambia in un punto solo (firma e nota).
