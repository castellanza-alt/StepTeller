# T-027 NASTY: l'interfaccia (cuore, fumetto, voce, notifiche, catalogo dal sito)
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026 — è il lavoro che porta la 1.3 su TestFlight

## Perché
William ha approvato tutto il 19/11: cuori, animazioni, testi («Ok, mi piace tutto procediamo. Finisci il lavoro e
prepara tutto e fermati un attimo prima di mandarlo ad Apple.»). Il nucleo c'è (T-024, #51), il catalogo nelle 10
lingue anche (#53). Manca l'app.

## Da leggere prima
`docs/DECISIONI.md` D-044…D-047 (D-047 prevale: il terzo livello in italiano è «Senza pietà» ed è **di serie per
tutti**, anche per chi aggiorna dalla 1.2) · `docs/design/T-023-nasty-grafica.md` e `docs/design/T-023-nasty/`
(cuori a livelli, tempi e curve delle animazioni, aptica) · pagina di riferimento delle animazioni
https://claude.ai/artifact/2TVrWv75kUHJfDLsu76SyH · `docs/design/T-022-nasty-progetto.md` · testi in
`docs/design/T-026-nasty-testi.md` §1 (solo quelli: nessun testo inventato).

## Cosa fare (ramo `task/T-027-nasty-app`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Livello di serie:** Senza pietà. Chi non ha il campo salvato (installazione nuova o aggiornamento) parte da lì;
   chi lo ha già scelto lo tiene. Aggiorna il nucleo e i suoi test se oggi il valore di serie è Normale.
2. **Cuore e fumetto in Home** come da specifica: due aspetti, giorno e notte, le tre famiglie di animazioni (riposo,
   quando parla, tocco con reazioni a rotazione e rabbia crescente), «Riduci movimento», aptica, VoiceOver. Con
   Normale non c'è niente. Fluido a 120 Hz, senza video né librerie.
3. **Battute** dal nucleo in: fumetto in Home, riga sotto l'obiettivo, pop-up di Jolly e serie, titolo della festa.
   **Prima battuta dopo l'aggiornamento**, una volta sola: «Da oggi parlo. Se non reggi: Impostazioni › Voce.»
4. **Introduzione:** pagina nuova della scelta, già puntata su Senza pietà.
5. **Impostazioni › Voce:** tre livelli, manopola «Notifiche di NEAT», nota; in iCloud e nel Backup.
6. **Notifiche roast** con `RoastPlan`: programmate a ogni apertura e a ogni risveglio da Salute, riprogrammate
   quando cambiano i passi, ferme a obiettivo raggiunto; promemoria serale e avvisi di obiettivo e Jolly con la voce
   del livello. Mai tra le 20 e le 10. Verifica il limite di iOS sulle notifiche in attesa.
7. **Catalogo:** a bordo quello generato da `scripts/battute.py` per le 10 lingue; una volta al giorno scarica
   `neat/nasty/battute.json` dal sito, lo controlla con il nucleo e lo usa; se manca o è rotto resta il precedente.
   Nessun dato inviato, nessun identificativo, nessun cookie; con Normale non scarica niente. Lingua senza catalogo
   valido: i livelli Piccante e Senza pietà non sono offerti.
8. **Testi dell'interfaccia** nel foglio e nei cataloghi, italiano di T-026 §1; le altre lingue le compila il
   Traduttore (T-028): lascia l'italiano dove manca.
9. **Pagina della privacy** `neat/privacy/index.html`, italiano: testi di T-026 §2. L'inglese lo scrive il Traduttore.
10. Riga nel CHANGELOG 1.3; `swift test`, Debug e Release; screenshot dei punti principali in `tasks/T-027/` (Home
    con i due cuori giorno e notte, pop-up, festa, introduzione, Impostazioni, una notifica; SE e 17 Pro Max);
    revisione indipendente; PR verso `main`, non unirla.

## Non fare
Nessuna build TestFlight, nessun commit `[store…]`, nessun invio ad Apple. Non toccare i disegni dei cuori né i testi
delle battute. Non scrivere a William.

## Disco
Solo SSD; file pesanti in `/Volumes/SSD/Temp/NEAT/`; a fine turno niente acceso.

## Esito
**Developer, 19/11/2026.** Ramo `task/T-027-nasty-app`, PR verso `main` (non unita). Screenshot in `tasks/T-027/`
(`pm-` 17 Pro Max, `se-` SE; Home Senza pietà e Piccante giorno e notte, prima battuta, pop-up, festa, introduzione,
Impostazioni, una notifica).

**Fatto**
1. Livello di serie nel nucleo: `NastyLevel.standard = .nasty` (D-047), usato da `StepsStore` e dalla copia del widget.
   Notifiche al giorno come T-026 §1: Senza pietà 2 · 4–5 · 7, Piccante 1 · 1–2 · 3 (`RoastPlan.countRange`).
2. Cuore e fumetto in Home (`App/Voice/`): i livelli vettoriali di `T-023-nasty/livelli/` come imageset SVG, impilati;
   le animazioni di T-023 §3 e della pagina di riferimento come funzioni del tempo (`HeartMotion`, curve CSS per tratto):
   battito e respiro, «quando parla» con il fumetto sparato dal cuore, quattro (NASTY) e tre (Piccante) reazioni al
   tocco a rotazione, rabbia `k` 1 · 1,35 · 1,7 entro 4 s (`NastyRage` nel nucleo). Orologio a 120 Hz mentre parla o
   reagisce, 60 Hz per il battito a riposo, fermo con l'app in sottofondo e, a riposo, con «Riduci movimento» (solo
   dissolvenze e lampo). Aptica come §3.3–3.4. VoiceOver: il cuore è un pulsante «NEAT. Tocca per un'altra battuta.»
   con la battuta come valore. Con Normale, o con l'avviso «nessun dato», niente.
3. Fumetto (`NastyBubble` nel nucleo): cambia quando cambia la situazione, al massimo una volta l'ora, e con il giorno;
   subito se la battuta non si può più dire (obiettivo raggiunto, numero mancante, ora finita). I numeri si riempiono a
   ogni comparsa. Una battuta conta come vista solo quando compare in Home non coperta. Prima battuta dopo
   l'aggiornamento: in sospeso per chi aveva già l'app (introduzione fatta), segnata quando compare davvero, resta per
   la stessa situazione del giorno; chi installa da zero non la vede.
4. Altri punti: riga sotto l'obiettivo (introduzione e Impostazioni, una battuta per raffica di tocchi), pop-up dei
   Jolly (la battuta al posto della prima frase, cuore adesivo; non per il Jolly di Natale), titolo della festa
   (2 righe in 330, fino ad Anton 24; solo a obiettivo raggiunto).
5. Introduzione a 5 pagine, la voce è la 4ª (`-stepteller.debugOnboarding 4`; `screenshots.sh` aggiornato); già su Senza
   pietà. Impostazioni › Voce dopo l'obiettivo, con «Notifiche di NEAT» solo con Piccante o Senza pietà. Scegliere una
   voce chiede il permesso delle notifiche se manca. Lingua senza catalogo valido: niente pagina né sezione, voce Normale.
6. Notifiche roast (`RoastScheduler`): rifatte a ogni lettura di Salute (apertura, risveglio, consegna in sottofondo),
   in coda con il promemoria; le consegnate di oggi entrano tra le viste e tengono i 90 minuti; nessuna a obiettivo
   raggiunto (le ritira anche il widget appena vede l'obiettivo). Prefisso `stepteller.roast.`. **Limite di iOS:** 64
   notifiche in attesa; qui al massimo 7 roast + 7 promemoria + pochi avvisi. Promemoria serale: battuta + i minuti di
   sempre; avvisi di obiettivo e Jolly: titolo di sempre, battuta come testo. Scelta ripetibile per giorno e scopo, senza
   memoria delle viste, così il widget non la cambia a ogni riscrittura.
7. Catalogo: a bordo le 10 lingue (`battute.py` legge anche `catalogo/lingue/<lingua>.json` di T-025; un file per lingua
   sul sito, T-022 §4 aggiornato). Una volta al giorno, solo con una voce in uso: GET di
   `neat/nasty/it/battute.json` e della lingua dell'app, sessione effimera, niente cookie, cache né credenziali,
   User-Agent «NEAT», `Accept-Language: *`; tenuto nell'App Group solo se passa il controllo ed è nuovo; senza rete
   riprova all'apertura dopo. Il widget rilegge i file quando cambiano.
8. Testi: 14 righe nel foglio, lingue dal Traduttore (`localizzazione/nasty-interfaccia.json`, T-028), cataloghi
   rigenerati; controllati su SE DE, FR e JA (i tre segmenti ci stanno). Font JA/KO/ZH ridotti anche ai caratteri delle
   battute (`font_asia.py`), tutti coperti.
9. Privacy: italiano T-026 §2 e inglese T-028 in `neat/privacy/index.html` (Jolly → Joker nella pagina inglese); data
   19 novembre 2026, da cambiare se si vuole quella della pubblicazione.
10. Revisione indipendente: corretti orologi sempre accesi, riga del promemoria instabile, memoria persa tra roast e
    Home, scaricamento dove la voce è Normale e senza nuovo tentativo, catalogo vecchio nel widget, VoiceOver del
    cuore, riga dell'obiettivo spuria nell'introduzione, prima battuta segnata sotto un pop-up, permesso delle
    notifiche, conteggio delle parole con la punteggiatura francese.

**Aperto**
- **PT-BR N138:** il titolo «Larga a porra do sofá» ha 5 parole (massimo 4): il controllo rifiuta il catalogo portoghese
  intero, quindi in PT-BR oggi niente Piccante e Senza pietà. Tre test lo segnalano (CI rossa finché non si corregge la
  riga in `catalogo/lingue/pt-BR.json`; poi `python3 scripts/battute.py` e `scripts/font_asia.py`). Testo del Traduttore.
- Il selettore PT-BR su SE va guardato dopo la correzione (con il catalogo rifiutato la sezione non compare).

**Verifiche:** `swift test` 156 test, verdi tranne i 3 di PT-BR; build Debug e Release; `battute.py --check`,
`registro.py`. Nessuna build TestFlight.
