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
