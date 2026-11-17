# NEAT 1.1 — bozze da approvare

Bozze di Claude, 26 ottobre 2026. Niente è ancora nei fogli, nelle pagine o nel repository: dopo il tuo ok le metto al
loro posto (italiano), preparo l'inglese e il file per ChatGPT.

Il motivo di quasi tutti i cambi: con la 1.1 alcuni dati (mai quelli di Salute) vanno nel **tuo iCloud**, quindi la
frase «nessun dato lascia il telefono» non è più vera. Resta vero che **lo sviluppatore non riceve niente**: niente
server nostri, nessuno può vedere quei dati tranne te.

---

## 1. Novità della 1.1 (App Store, «Novità di questa versione»)

> I tuoi progressi non si perdono più. Serie, obiettivi e impostazioni si salvano anche nel tuo iCloud: se cambi
> iPhone o reinstalli NEAT, ritrovi tutto, compresa la serie. Nulla però esce dal tuo account, la tua privacy è totale.
>
> • Nuovo in Impostazioni: «Backup». Salva i tuoi dati in un file e ricaricali quando vuoi.
> 
> • Corretto il promemoria della sera: usa i passi più recenti e non arriva più se l'obiettivo è già raggiunto.
>
> • Piccole correzioni.

---

## 2. Scheda dello store (italiano; poi va tradotta come la 1.0)

Cambiano due frasi su cinque campi. Nome, sottotitolo e parole chiave restano uguali.

**Testo promozionale**
- Oggi: «… I tuoi dati restano sul tuo iPhone.»
- Bozza: «Quanti passi ti mancano oggi? NEAT te lo dice in un colpo d'occhio. I tuoi dati sono solo tuoi.»

**Descrizione**, il penultimo paragrafo
- Oggi: «I tuoi dati restano sul tuo iPhone. NEAT legge soltanto: niente account, niente pubblicità, niente
  tracciamento. Nessun dato lascia il telefono.»
- Bozza: «I tuoi dati sono solo tuoi. NEAT legge soltanto: niente account, niente pubblicità, niente tracciamento.
  Serie e impostazioni si salvano nel tuo iCloud, mai su server di altri. Cambi iPhone? Ritrovi la tua serie.»

---

## 3. Pagina privacy (italiano; l'inglese la segue frase per frase)

Data in alto: «Ultimo aggiornamento: [giorno della pubblicazione della 1.1]».

**In breve** (sostituisce il paragrafo attuale)
> NEAT legge da Apple Salute i passi, la distanza a piedi e di corsa e gli allenamenti, e li usa solo sul tuo iPhone.
> Non ha account e non contiene pubblicità, analisi o tracciamento. Le tue impostazioni e la tua serie si salvano anche
> nel tuo iCloud, per ritrovarle su un nuovo iPhone; i dati di Salute no. Lo sviluppatore non riceve nessun dato e
> nessuno, nemmeno lui, può vederli.

**Dove restano i dati**: resta tutto com'è, si aggiunge alla fine un paragrafo nuovo
> **Copia nel tuo iCloud.** Se sull'iPhone è attivo iCloud, NEAT ne salva una copia nel tuo spazio iCloud (il servizio
> «chiave-valore» di Apple): obiettivo con lo storico degli obiettivi, data di inizio della serie, velocità, unità di
> misura, promemoria e orario, tema e taratura della cadenza. Serve a ritrovarli se reinstalli l'app o cambi iPhone con
> lo stesso account Apple. La copia è gestita da Apple e protetta dal tuo account: lo sviluppatore non può leggerla.
> **I dati di Salute non vanno mai in iCloud** tramite NEAT (Salute ha la sua sincronizzazione, gestita da Apple).
>
> **File di backup.** In Impostazioni → Backup puoi esportare gli stessi dati in un file (`NEAT-backup-….json`) e
> salvarlo dove vuoi (File, AirDrop, Mail…). Il file lo crei e lo conservi tu; NEAT non lo invia a nessuno.

**Cosa NEAT non fa**: il primo punto cambia
- Oggi: «Nessuna connessione a internet: l'app non invia e non riceve dati.»
- Bozza: «Nessun server dello sviluppatore: l'app non invia dati a nessuno. L'unico scambio è la copia nel tuo
  iCloud, fatta da iOS.»

**Come cancellare i dati**: si aggiunge
> Disinstallando l'app la copia in iCloud resta, così puoi ritrovarla. Per non usarla più: Impostazioni → [il tuo
> nome] → iCloud → app che usano iCloud → NEAT, e spegnila. Per cancellarla: stesso percorso, «Gestisci spazio» → NEAT
> → Elimina dati.

**I tuoi diritti**: «nessun dato personale viene raccolto o trasmesso allo sviluppatore» resta vero; si aggiunge
«La copia in iCloud è nel tuo account Apple e la controlli tu (vedi sopra).»

Da verificare prima di pubblicare: i percorsi esatti di iOS per spegnere e cancellare la copia in iCloud. Li controllo
sul tuo iPhone con la build TestFlight e, se serve, correggo il testo.

---

## 4. Pagina supporto (italiano e inglese)

- Risposta su Salute: «Non scrive mai in Salute e nessun dato lascia il telefono» → «Non scrive mai in Salute e i dati
  di Salute non lasciano il telefono».
- Domanda «NEAT raccoglie i miei dati?»: «No. Niente account, niente pubblicità né analisi, nessun server nostro.
  Serie e impostazioni si salvano anche nel tuo iCloud per ritrovarle su un nuovo iPhone; nessuno tranne te può
  vederle. Dettagli nella privacy.»
- Domanda nuova «Ho cambiato iPhone (o reinstallato NEAT): ritrovo la serie?»: «Sì, se usi lo stesso account Apple con
  iCloud attivo: serie, obiettivi e impostazioni tornano da soli, a volte dopo qualche minuto. L'introduzione si rivede
  perché i permessi di Salute e notifiche vanno dati di nuovo. Senza iCloud usa Impostazioni → Backup: esporta il file
  dal vecchio iPhone e importalo sul nuovo.»

---

## 5. App Store Connect, scheda privacy

**Resta «Dati non raccolti».** Per Apple un dato è «raccolto» quando lo sviluppatore (o un suo partner) può
leggerlo; la copia nel tuo iCloud chiave-valore e il file di backup non arrivano mai a noi. Non serve toccare nulla.

---

## 6. Note per il revisore (inglese, come le attuali)

Cambiano due punti, il resto resta uguale.

- Punto 3, riga Settings: si aggiunge «Backup (Export backup / Import backup: a JSON file the user saves and opens
  through the system share sheet and file picker)».
- Punto 4, si aggiunge una voce e cambia la frase finale:
  > - iCloud key-value storage (NSUbiquitousKeyValueStore), in the user's own iCloud account: goal and goal history,
  >   streak start date, speed, units, reminder settings, theme and cadence calibration, so they come back after a
  >   reinstall or on a new iPhone. No Health data is stored in iCloud. The developer has no access to it.
  >
  > No servers of our own, analytics, ads, AI services, sign-in services or payment providers. No data is sent to the
  > developer. The only links in the app (Privacy and Support in Settings) open our web pages in the browser.

In italiano, in sostanza: «Usiamo l'iCloud chiave-valore dell'utente per obiettivo, serie e impostazioni; niente dati di
Salute; lo sviluppatore non vi accede. Nessun server nostro.»

---

## Cosa ti chiedo

Un ok (o le correzioni) su:
1. le **Novità** (punto 1);
2. le due frasi della **scheda** (punto 2), e se aggiungere «Cambi iPhone? Ritrovi la tua serie.»;
3. **privacy e supporto** (punti 3 e 4).

Le note per il revisore e la scheda privacy le sistemo io dopo il tuo ok sugli altri testi.
