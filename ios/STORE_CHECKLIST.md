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
| Font lingue asiatiche | Da scegliere nella chat 4b, con prove a confronto |

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

## 1b. Rimozione della Live Activity del tappeto
- [ ] Live Activity, controller, attributi e `NSSupportsLiveActivities` tolti; widget intatti
- [ ] Build pulita, test verdi, widget invariati negli screenshot
- [ ] Controllo della chat di coordinamento e merge

## 2. Pagine di privacy e supporto
- [ ] Privacy policy (solo lettura da Salute, niente rete, nessun dato raccolto)
- [ ] Pagina di supporto (email, domande frequenti)
- [ ] Pubblicate su GitHub Pages (servite da `main`, radice) in una cartella nuova `neat/`, senza toccare la web app;
      URL annotati qui
- [ ] Link nelle Impostazioni dell'app (dopo la chat 1)
- [ ] Controllo della chat di coordinamento

## 3. Onboarding
- [ ] Schermate: cosa fa NEAT, permesso Salute, obiettivo, promemoria e permesso notifiche
- [ ] Solo al primo avvio; chi ha già l'app non lo vede
- [ ] Rivedibile dalle Impostazioni; opzione Debug per gli screenshot
- [ ] Prova su iPhone SE e Pro Max, giorno e notte
- [ ] Controllo della chat di coordinamento

## 4a. Traduzioni — base e lingue europee
- [ ] String Catalog per app, widget, Live Activity, notifiche e testi dei permessi
- [ ] Numeri e date secondo la lingua, test golden invariati
- [ ] IT, EN, ES, FR, DE, PT-BR
- [ ] Nessun testo tagliato (screenshot di prova per lingua)
- [ ] Controllo della chat di coordinamento

## 4b. Traduzioni — lingue asiatiche e font
- [ ] Font scelto da Will tra le prove (sistema vs font OFL dedicato, con peso in MB)
- [ ] JA, KO, ZH-Hans, ZH-Hant
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
