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
| Font lingue asiatiche | Font OFL ridotti ai caratteri usati: Dela Gothic One (JA), Black Han Sans (KO), Noto Sans SC/TC Black (ZH), ~270 KB |

## Da decidere


- [ ] Ramo di uscita: `ia/versione-0.6.2` (base attuale) e `ios-nativa` (10 commit 0.5.5–0.6.1 fatti dal Mac, non
      presenti nel ramo attuale) sono divergenti. Il workflow TestFlight parte da `ios-nativa`. Decidere quale ramo
      porta la 1.0 prima della chat 7.

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

### 3b. Home a obiettivo raggiunto — PR [#17](https://github.com/castellanza-alt/StepTeller/pull/17), da unire
- [x] «OBIETTIVO RAGGIUNTO / FATTO! / +729 PASSI» in una vignetta storta con fondo carta, leggibile in tutte le lingue
- [x] Proposte mostrate a Will: scelta la B (vignetta)
- [x] Controllo della chat di coordinamento: diff letto (Vignette dello Storico invariata se riceve la larghezza),
      44 test, 0 avvisi; screenshot su iPhone SE in IT, DE (notte), FR, JA
- [ ] Merge della PR in `ia/versione-0.6.2` (ok di Will)

### 4b. Lingue asiatiche e font
- [x] Font scelto da Will tra le prove: OFL ridotti (Dela Gothic One, Black Han Sans, Noto Sans SC/TC Black)
- [ ] Sottoinsieme che copre anche date e mesi scritti da iOS (年月日, 월/년/일, giorni della settimana) e un controllo automatico
- [ ] Implementazione dopo il merge della 3b
- [ ] JA, KO, ZH-Hans, ZH-Hant dal foglio
- [ ] Layout controllati
- [ ] Rilettura di un madrelingua (facoltativa)
- [ ] Controllo della chat di coordinamento

## 5. Scheda App Store Connect
- [ ] Nome, sottotitolo, descrizione, parole chiave, testo promozionale in 10 lingue
- [ ] Categoria (Salute e fitness), classificazione per età, etichette privacy «Dati non raccolti»
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
