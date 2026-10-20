# NEAT 1.0 — checklist per l'App Store

Documento di coordinamento. Lo aggiorna solo la chat di coordinamento, dopo aver controllato il lavoro di ogni
chat dedicata; le chat dedicate non lo modificano.

**Regola:** dalla 0.6.3 il comportamento e l'aspetto dell'app sono bloccati. Ogni modifica visibile va concordata
prima tra Will e la chat di coordinamento.

## Decisioni prese

| Tema | Decisione |
|---|---|
| Nome sullo store | «NEAT - ogni passo conta» (tradotto per lingua); sotto l'icona resta NEAT |
| Prezzo | Gratuita, nessun acquisto in-app, nessuna pubblicità |
| Paesi | Tutti |
| Trader UE (DSA) | Non-trader (progetto personale, gratuito) |
| Versione | 1.0 |
| Email di supporto | castellanza@gmail.com (pubblica su pagina di supporto e store) |
| Live Activity del tappeto | Tolta (chat 1b): dalla 0.6.0 nessun bottone la avviava |
| Lingue | Italiano, inglese, spagnolo, francese, tedesco, portoghese (Brasile), giapponese, coreano, cinese semplificato, cinese tradizionale |
| Unità di misura | km e km/h per tutte le lingue nella 1.0 (miglia eventualmente in una versione successiva) |
| Termini chiave | Glossario (Jolly, serie, tappeto, obiettivo…) approvato da Will prima di tradurre |
| Icona | Nuova (20 ottobre): suola rossa e scarpa bianca su nero, vettoriale, Liquid Glass — PR [#19](https://github.com/castellanza-alt/StepTeller/pull/19), unita (`adc5cdc`) |
| Font lingue asiatiche | Font OFL ridotti ai caratteri usati: Dela Gothic One (JA), Black Han Sans (KO), Noto Sans SC/TC Black (ZH), ~270 KB |

## Da decidere


- [x] Ramo di uscita (deciso da Will, 20 ottobre: «Git pulito e ordinato»): la 1.0 parte da `ia/versione-0.6.2`.
      TestFlight e verifica partono da `main` e da `ia/versione-0.6.2` (non più da `ios-nativa`). La vecchia
      `ios-nativa` (0.5.5–0.6.1, design «carta e matita») è salvata in `archivio/ios-nativa-0.6.1`.

### Riordino di Git (alla chiusura, dopo l'ok di Will sulla 1.0)
- [ ] `ia/versione-0.6.2` unito in `main` (pubblica anche Pages: web app invariata, pagine `neat/` già online)
- [ ] TestFlight solo da `main`; il ramo della 1.0 tolto dai workflow
- [ ] Rami di lavoro già uniti cancellati (`ia/*`, `ios-nativa`); l'archivio diventa un tag `archivio/0.6.1`
- [ ] Tag `v1.0` sulla versione inviata ad Apple

## 0. Finetuning — fatto
- [x] Modifiche della chat «finetuning» salvate: 0.6.3 (`0aa5c2e`), codice bloccato da qui

## 1. Pulizia e conformità — fatto, PR [#11](https://github.com/castellanza-alt/StepTeller/pull/11)
- [x] `PrivacyInfo.xcprivacy` nell'app e nel widget (UserDefaults CA92.1 e 1C8F.1; nessuna altra API da dichiarare)
- [x] Avvisi del compilatore a zero in Debug e Release
- [x] Codice morto rimosso (colori del vecchio tappeto, funzioni senza chiamanti), screenshot invariati
- [x] `MARKETING_VERSION` 1.0 e CHANGELOG
- [x] Build Release pulita, `swift test` verde (43), PR aperta
- [x] Controllo della chat di coordinamento: diff letto, build rifatta sul Mac con Xcode 27.1 (0 avvisi,
      manifest in `.app` e `.appex`)
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `6ab9596`)

## 1b. Rimozione della Live Activity del tappeto — fatto, PR [#14](https://github.com/castellanza-alt/StepTeller/pull/14)
- [x] Live Activity, controller, attributi, `NSSupportsLiveActivities` e ActivityKit tolti; widget intatti
      (WidgetBundle ora in `LiveActivity/WidgetsBundle.swift`; target e bundle ID invariati)
- [x] Build pulita, test verdi, widget invariati negli screenshot
- [x] Controllo della chat di coordinamento: diff letto, build sul Mac con Xcode 27.1 (0 avvisi, `.appex` presente
      con bundle ID di sempre, niente ActivityKit nel binario)
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `7f5ab52`)

## 2. Pagine di privacy e supporto — fatto, PR [#12](https://github.com/castellanza-alt/StepTeller/pull/12) e [#13](https://github.com/castellanza-alt/StepTeller/pull/13)
- [x] Privacy policy (solo lettura da Salute, niente rete, nessun dato raccolto), italiano e inglese
- [x] Pagina di supporto (email, domande frequenti), italiano e inglese
- [x] Cartella nuova `neat/`, nessun file della web app toccato. URL (online, verificati):
      https://castellanza-alt.github.io/StepTeller/neat/privacy/ ·
      https://castellanza-alt.github.io/StepTeller/neat/supporto/
- [x] Sezione «Informazioni» nelle Impostazioni: Privacy, Supporto, versione
- [x] Controllo della chat di coordinamento: testi letti, screenshot visti, #13 provata sopra la base attuale
      (nessun conflitto, 43 test, 0 avvisi in Release)
- [x] Merge della #12 su `main` (`fa6b677`, pagine online) e della #13 in `ia/versione-0.6.2` (`2c75d6a`)

## 3. Onboarding — fatto, PR [#15](https://github.com/castellanza-alt/StepTeller/pull/15)
- [x] 4 pagine: benvenuto, Salute (richiesta di sistema lasciando la pagina), obiettivo, promemoria (notifiche su «Inizia»)
- [x] Solo al primo avvio; utente esistente riconosciuto dalle chiavi già salvate (nessuna introduzione, nessun permesso)
- [x] «Rivedi l'introduzione» nelle Impostazioni; `-stepteller.debugOnboarding 1…4` per gli screenshot
- [x] Promemoria: «Apri NEAT» al posto di «Apri Step Teller»
- [x] Prove della chat: Salute concessa e negata, utente esistente, rivedi; Home/Storico/widget invariati
- [x] Controllo della chat di coordinamento: diff letto, 43 test, 0 avvisi Release e Debug; build Release provata su
      iPhone SE: installazione nuova → introduzione; **aggiornamento reale** dalla base → Home, nessuna introduzione
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `7a333a4`)

## 4. Traduzioni — testi tradotti con ChatGPT, controllati dalla chat di coordinamento
Materiale in `ios/localizzazione/`: `NEAT_testi_tradotti.xlsx` (173 testi + glossario, 9 lingue),
`PROMPT_CHATGPT.md` (descrizione dell'app e delle schermate, regole), `screenshot/`.
- [x] Inventario dei testi dal codice (introduzione, Home, Storico, Impostazioni, festa, widget, notifiche, permessi)
- [x] ChatGPT: glossario approvato da Will (Jolly: EN/FR/DE Joker, ES Comodín, PT-BR Coringa, JA おまもり,
      KO 지킴이, ZH 护身符/護身符; serie: streak, racha, série, Serie, sequência)
- [x] ChatGPT: foglio compilato in EN, ES, FR, DE, PT-BR, JA, KO, ZH-Hans, ZH-Hant (1.557 traduzioni)
- [x] Controllo della chat di coordinamento: segnaposto, celle vuote, MAIUSCOLO, lunghezze, coerenza, caratteri
      semplificati nel cinese tradizionale; letti per intero EN e DE, a campione le altre. Corretti: testo del permesso
      di scrittura (italiano inesatto: «legge soltanto i tuoi passi») in tutte le lingue, inglese americano
      (kilometers), DE «NUR ZUM LESEN»
- [ ] Rilettura madrelingua JA, KO, ZH (facoltativa; dubbi annotati nel foglio)

### 4a. Localizzazione nel codice — fatto, PR [#16](https://github.com/castellanza-alt/StepTeller/pull/16)
- [x] String Catalog per app, widget, onboarding, notifiche e testi dei permessi, riempito dal foglio (`scripts/cataloghi.py`)
- [x] Info.plist italiano: nuovo testo del permesso di scrittura; nomi del percorso «Salute → Condivisione → App» giusti su iOS 27
- [x] Percorso di Salute sul telefono di Will: NEAT compare in Salute → Condivisione → App (sul simulatore l'elenco è vuoto)
- [x] Lingua di riserva inglese (`CFBundleDevelopmentRegion` en in app e widget): olandese → inglese, italiano → italiano,
      provato sulla build Release
- [x] ES «COMODINES» nella barra in alto: le schede si rimpiccioliscono quando serve
- [x] Numeri e date secondo la lingua, test golden invariati (44 test)
- [x] Tutte e 10 le lingue nei cataloghi (le asiatiche con il carattere di sistema, da rifinire nella 4b)
- [x] Nessun testo tagliato (screenshot per lingua)
- [x] Controllo della chat di coordinamento: tutte le 1.557 traduzioni del foglio trovate nei cataloghi, nessun testo
      italiano rimasto nel codice, 0 avvisi Release/Debug, screenshot DE e JA rifatti sul Mac
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `aeec748`)

### 3b. Home a obiettivo raggiunto — fatto, PR [#17](https://github.com/castellanza-alt/StepTeller/pull/17)
- [x] «OBIETTIVO RAGGIUNTO / FATTO! / +729 PASSI» in una vignetta storta con fondo carta, leggibile in tutte le lingue
- [x] Proposte mostrate a Will: scelta la B (vignetta)
- [x] Controllo della chat di coordinamento: diff letto (Vignette dello Storico invariata se riceve la larghezza),
      44 test, 0 avvisi; screenshot su iPhone SE in IT, DE (notte), FR, JA
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `f191cf5`)

### 4b. Lingue asiatiche e font — fatto, PR [#18](https://github.com/castellanza-alt/StepTeller/pull/18)
- [x] Font scelto da Will tra le prove: OFL ridotti (Dela Gothic One, Black Han Sans, Noto Sans SC/TC Black)
- [x] Sottoinsieme che copre anche date e mesi scritti da iOS (年月日, 월/년/일, giorni della settimana) e un controllo automatico
- [x] Implementazione: un solo punto in MangaTokens (Anton + font asiatico in cascata), paragrafi in grassetto di sistema,
      +0,6 MB; 44 test, 0 avvisi; IT/EN/DE identici
- [x] Storico: scritte sotto il «22» staccate in JA/KO/ZH (`TitleFont.gap`, 0 nelle altre lingue); anche Home e widget medio
- [x] Controllo della chat di coordinamento: 44 test, 0 avvisi; Storico e Home rifotografati in JA, KO, ZH-Hant
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, `6ca7909`)
- [x] JA, KO, ZH-Hans, ZH-Hant dal foglio
- [x] Layout controllati
- [ ] Rilettura di un madrelingua (facoltativa)

## 4c. Revisione finale del codice (Fable) — fatto, PR [#20](https://github.com/castellanza-alt/StepTeller/pull/20)
- [x] Rapporto di Fase 1 approvato (con precisazioni: E2 senza la motivazione del budget, aggiornamento immediato
      andando in background; D2 con `Calendar.autoupdatingCurrent`; E4 non fatto)
- [x] 10 commit: residui, una sola rilettura dello storico, widget e promemoria coalizzati (26 → 1, gara delle
      notifiche chiusa), Storico precalcolato (body «Anno» 4,5 → 1,1 ms), formattatori riusati, cache glifi limitata,
      fuso orario, rinomine (`HistoryView`), duplicazioni, 704 righe di commenti in inglese
- [x] Controllo della chat di coordinamento: letti i commit a rischio (E1, E2, D2); il commit dei commenti non cambia
      codice (verifica automatica); chiavi salvate identiche; 48 test, 0 avvisi Release/Debug; Storico rifotografato
- [x] Merge della PR in `ia/versione-0.6.2` (ok di Will, 10 commit in fila, ultimo `f918bf2`)
- [x] TestFlight 0.99 pubblicata nel gruppo «Personale» (`4b441fc`); versione da riportare a 1.0 prima dell'invio ad Apple
- [x] Prova di Will sul telefono (20 ottobre): tutto ok, salvo lo «0» per qualche secondo all'apertura
- [x] Apertura senza «0»: ultimi passi e serie salvati mostrati fino alla lettura di Salute — PR [#21](https://github.com/castellanza-alt/StepTeller/pull/21) (`ae28edf`)
- [x] Nuova build 0.99 su TestFlight con la correzione (build 1.68.2, al secondo tentativo: il primo è rimasto senza Mac)
- [ ] Prova di Will dell'apertura senza «0»

## 5. Scheda App Store Connect
Messaggio approvato da Will: un obiettivo di passi e tre domande (quanti passi oggi, quanti ne mancano, quanto
camminare ancora) + «i tuoi dati restano sul tuo iPhone». Comunicazione semplice, pochi messaggi. Niente
promesse su salute/calorie; il significato di NEAT (Non-Exercise Activity Thermogenesis) non si spiega nella scheda.
Testi italiani in `ios/localizzazione/NEAT_store_da_tradurre.xlsx`, prompt in `PROMPT_CHATGPT_STORE.md`.
- [x] Italiano approvato: nome «NEAT - ogni passo conta», sottotitolo «Il tuo obiettivo. Raggiungilo.»,
      promozionale, descrizione (655 car.), parole chiave
- [x] Anteprima italiana con Claude Design: 6 screenshot 1320×2868 in `localizzazione/design/claude-design-IT/`
      (non versionati); didascalie 1, 3, 6 ritoccate per allinearle ai messaggi (approvate da Will)
- [x] Claude Design: versione italiana finale (6 PNG 1320×2868, 06 con «Nessun dato lascia il telefono» e tre etichette)
- [x] Screenshot dell'app nelle 9 lingue per Claude Design (`design/app-lingue/`, 54 immagini controllate) e zip
      `NEAT_lingue_per_Claude_Design.zip` con didascalie per lingua
- [ ] Claude Design: 6 immagini per ciascuna delle 9 lingue
- [x] ChatGPT: testi dello store e 15 didascalie degli screenshot nelle 9 lingue → `NEAT_store_tradotto.xlsx`
- [x] Controllo della chat di coordinamento: limiti (30/30/170/100) rispettati, a capo «/» in tutti i titoli, nessuna
      promessa sanitaria; serie in JA/KO/ZH riallineata al glossario dell'app (連続記録/연속 기록/连续记录/連續紀錄)
- [ ] Parole chiave JA/KO/ZH: 42–60 caratteri ma 102–146 byte; verificare in App Store Connect se il limite di 100 è in
      caratteri o in byte, e accorciarle se serve
- [ ] Lingua principale della scheda: inglese (così i paesi senza traduzione vedono l'inglese, non l'italiano);
      copie per en-GB/en-AU/en-CA, es-MX, fr-CA dove servono
- [ ] Categoria Salute e fitness (seconda: Stile di vita), età 4+, privacy «Dati non raccolti»
- [ ] URL di privacy e supporto
- [ ] Prezzo gratuito, tutti i paesi, dichiarazione non-trader UE
- [ ] Note per il revisore (Salute vuota, passi inseribili a mano)
- [ ] Controllo della chat di coordinamento

## 6. Screenshot per lo store
- [ ] Scelta di 5–6 schermate
- [ ] Didascalie tradotte
- [ ] Script aggiornato, immagini in 10 lingue
- [ ] Controllo della chat di coordinamento

## 7. Uscita
- [ ] Build 1.0 su TestFlight, prova completa di Will
- [ ] Invio in revisione
- [ ] Eventuale rifiuto gestito
- [ ] Merge su `main` (su richiesta di Will)
