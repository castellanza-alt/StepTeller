# NEAT — decisioni

Numerate, con data, chi ha deciso e perché. Una decisione superata si barra e rimanda a quella nuova, non si cancella.
«William» = decisione del proprietario; «Director» = decisione tecnica del Director, che William può ribaltare.
Le decisioni di prodotto della 1.0 sono nella tabella di `STORE_CHECKLIST.md` e restano valide.

## Scelte aperte

## Prodotto e processo (già in vigore, riportate qui)
- **D-001** Salute solo in lettura (passi), mai scrittura né rete; nessun dato di Salute in iCloud. William.
- **D-002** Versioni, registro e Novità secondo `RILASCIO.md` (22/10/2026). William.
- **D-003** Build TestFlight e scheda dello store solo da `main`, via GitHub Actions (26/10/2026). William.
- **D-004** Repo pubblico: nessun segreto, profilo o chiave nel repo. William.
- **D-005** Italiano per tutto ciò che William legge; i testi da tradurre passano dall'italiano approvato da William.
- **D-006** Tolto l'inserimento dei passi a mano (1.1). William.
- **D-007** Età 4+ anche per la 1.1 (17/11/2026: «si, 4+»), invio ad Apple approvato. William.

## Versioni dopo la 1.1
- **D-036 Natale prima dell'orologio (17/11/2026, Director).** La 1.2 è «Natale»: notifica a obiettivo raggiunto, Jolly
  guadagnato e usato (notifica e pop-up), tema stagionale di Natale con icona. Va inviata ad Apple entro il 1° dicembre
  per uscire in tempo. L'app per Apple Watch passa alla 1.3 (PR #28 resta in bozza); la versione «NASTY» viene dopo,
  con la sua classificazione per età. Perché: il Natale ha una data, l'orologio no, e una versione piccola passa la
  revisione prima. William può ribaltarla.
- **D-037 Temi stagionali (17/11/2026, Director).** Un solo meccanismo per tutte le stagioni (date di inizio e fine,
  palette, decorazioni, icona); si parte da Natale (1° dicembre – 6 gennaio). Interruttore in Impostazioni, acceso di
  serie. L'icona alternativa si cambia con l'API di iOS, che mostra il suo avviso di sistema: niente trucchi per
  nasconderlo. I colori passano dai token di `MangaTokens.swift` (giorno e notte), mai scritti nelle viste.
- **D-038 Notifiche di obiettivo e Jolly (17/11/2026, Director).** Una sola notifica al giorno per l'obiettivo raggiunto,
  mai durante la notte e mai doppia con il promemoria; Jolly guadagnato e usato: una notifica per evento e un pop-up
  alla prima apertura dopo l'evento, mai ripetuto. Si usano i meccanismi già presenti (consegna in sottofondo di Salute,
  widget, risveglio in sottofondo), Salute sempre in sola lettura, nessuna rete. Si possono spegnere in Impostazioni.
- **D-044 NASTY, impostazione alla Carrot (19/11/2026, William).** NEAT stesso è il personaggio e parla in prima
  persona: ha una forma ma non un volto. Tre livelli (Normale, intermedio, NASTY), gratuiti; di serie Normale, e
  l'introduzione chiede se si vuole «un'esperienza più piccante». Tono da roast («Roast in Peace»), non da battuta
  bonaria: i testi di T-008 (Hargreaves) sono troppo blandi e vanno riscritti; Hargreaves come personaggio terzo
  decade. Linguaggio (William, 19/11): parolacce al livello 3 e insulti diretti sul comportamento («pigro
  bastardo»), che superano D-039 su questi due punti; restano fuori corpo, peso, aspetto,
  salute, età, genere e altre caratteristiche personali (linee guida di Apple). Prima del codice: ricerca su Carrot
  (`docs/design/T-008-nasty/carrot-ricerca.md`), carattere e campione di battute approvati da William.
- **D-039 NASTY (17/11/2026, William).** «Cattiva ma senza parolacce, lo scopo è umiliare con humor inglese, non
  offendere in modo facile con insulti. L'utente deve ridere ma anche sentirsi incentivato a fare i passi. Questo deve
  essere vero in ogni aspetto, anche quando imposta il target dei passi.» Regole del Director che ne seguono: niente
  parolacce, niente insulti facili; mai corpo, peso, aspetto, salute, età, genere o altre caratteristiche personali
  (anche per le linee guida di Apple): si prende in giro solo il comportamento (pigrizia, divano, scuse, obiettivi
  bassi). Ogni battuta chiude con una spinta a muoversi. È una voce che si sceglie, non quella di serie. Esce dopo la
  1.2 «Natale».

- **D-040 Natale rifatto (18/11/2026, William).** Il primo tema di Natale (cappellini su ogni elemento) è bocciato:
  «non mi piace come ha lavorato design». Nuova direzione, che sostituisce le decorazioni di D-037 (restano il
  meccanismo unico, le date 1/12–6/1, l'interruttore e l'icona alternativa):
  - stessa struttura della Home: gamba in primo piano con parallasse, ma **lo stivale di Babbo Natale** al posto
    della scarpa da corsa; dietro un **paesaggio innevato**;
  - il pomello della velocità prova a diventare **la slitta trainata dalle renne**; se non funziona, resta il pomello;
  - **Jolly regalo**: +1 Jolly alla prima apertura dalla mezzanotte della vigilia (25/12 00:00 ora locale) in poi, così
    non lo perde chi non apre l'app a Natale; con una scritta speciale. Il Director aggiunge: vale fino al 6/1, ogni
    anno, una volta per stagione (segnato anche in iCloud e nel Backup, così una reinstallazione non lo ripete);
  - **nessun riferimento religioso**: solo Natale e regalo;
  - **icona ridisegnata con lo stivale**;
  - illustrazioni vere con **Higgsfield** (sì di William alla spesa, entro i crediti già presenti: 39 al 18/11, nessuna
    ricarica senza un nuovo sì);
  - **tutto insieme nella 1.2**: niente Natale in un aggiornamento separato, anche a costo di slittare sul 1° dicembre.
- **D-042 Slitta e velocità massima (18/11/2026, William).** Vista la slitta a grandezza vera nel Simulatore (troppo
  piccola, a 15 km/h copre i testi): «farei una slitta un filo più grande. Poi cambiamo il passo dei km/h: arriviamo a
  10, non oltre». Il cursore della velocità arriva a **10 km/h** (in miglia l'equivalente, 6 mph), in tutta l'app e non
  solo a Natale; le velocità salvate più alte (telefono, iCloud, Backup) scendono a 10.
- **D-043 Disco (18/11/2026, William).** «Da ora in poi non devi usare e far usare il disco interno ma solo quello
  esterno. Creati delle cartelle ordinate con regole semplici.» Mappa in `/Volumes/SSD/LEGGIMI.md`, regole in
  `ios/CLAUDE.md` (sezione Disco). Spostati: build Xcode, cache SwiftPM (simulatori e progetti già dal 15/11); le
  conversazioni e i temporanei di Claude si spostano con l'app chiusa. Motivo: una registrazione del Simulatore
  dimenticata da una sessione di briciola aveva riempito il disco interno (63 GB).
- **D-041 Traduttore (18/11/2026, William).** Quinto membro del team, «NEAT: Traduttore» (worktree
  `~/Developer/neat-lang`, rami `lang/…`): traduce nelle 10 lingue i testi italiani approvati da William (D-005) e
  tiene `localizzazione/GLOSSARIO.md`. Sostituisce il giro dei prompt in ChatGPT. Parla solo con il Director.

## Team (17/11/2026, William: «stessa struttura di Briciola»)
- **D-030 Organizzazione.** Quattro ruoli: **Director** (unico che parla con William, scrive i compiti, decide le
  questioni tecniche, unisce in `main`, chiede le build), **Designer** (specifiche numeriche in `ios/docs/design/`,
  anteprime ferme come Artifact, non tocca il codice), **Developer** (costruisce su rami, revisione indipendente del
  proprio diff, non unisce), **QA** (un collaudo per build sul Simulatore, rapporto in `ios/comms/qa/T-xxx.md`).
  Le «chat dedicate» e la «chat di coordinamento» di `STORE_CHECKLIST.md`/`RILASCIO.md` diventano: Director = chat
  di coordinamento; gli altri ruoli = chat dedicate. William.
- **D-031 Rami.** Un ramo per compito da `main` aggiornato: `task/T-xxx-nome` (Developer), `design/T-xxx-nome`
  (Designer), `qa/T-xxx` (QA). Ognuno lavora nel suo worktree. PR verso `main`; nessuno unisce tranne il Director.
- **D-032 Build.** Solo il Director: unione in `main` (che pubblica anche Pages) e build TestFlight dalla CI.
  Nessun agente cerca o legge chiavi, certificati o credenziali; i segreti stanno solo in GitHub Actions.
- **D-033 Provata.** Una build si segna *provata da William* solo quando William lo dice per quella build. I giudizi
  senza build esplicita vanno in `ios/comms/feedback.md` con la build presunta.
- **D-034 Rilascio.** Il flusso di `RILASCIO.md` (versione, CHANGELOG, Novità, invio) passa al Director. Ogni PR di
  codice aggiunge comunque la sua riga al CHANGELOG (lo vuole la CI); l'intestazione e lo stato li cambia solo il Director.
- **D-035 Spese.** Nessuna spesa (servizi, crediti, minuti macOS oltre il normale) senza il sì di William in chat.
