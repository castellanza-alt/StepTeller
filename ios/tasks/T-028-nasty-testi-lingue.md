# T-028 NASTY (1.3): testi dell'interfaccia, privacy e scheda dello store nelle lingue
**Assegnato a:** Traduttore **Base:** `main` **Stato:** assegnato 19/11/2026

## Perché
William ha approvato il 19/11 i testi italiani di `docs/design/T-026-nasty-testi.md` (interfaccia §1, privacy §2,
store §3). Vanno portati nelle altre lingue. Regole: D-044…D-047, glossario `localizzazione/GLOSSARIO.md` (§5 NASTY).

## Cosa fare (ramo `lang/T-028-nasty-testi`, worktree `/Volumes/SSD/Developer/neat-lang`)
1. **Nome del terzo livello** in ogni lingua (italiano «Senza pietà»): proponi il nome naturale (per esempio EN «No
   mercy»), corto abbastanza per un selettore a tre segmenti su iPhone SE; scrivilo nel glossario. «Piccante» idem.
2. **Interfaccia** (T-026 §1) nelle 9 lingue, nel foglio `localizzazione/NEAT_testi_tradotti.xlsx`. Le righe le
   aggiunge il Developer (T-027): se non ci sono ancora, prepara le traduzioni in una tabella nel tuo Esito con gli
   stessi testi italiani come chiave, e inseriscile appena le righe esistono.
3. **Privacy**: versione inglese dei testi di T-026 §2 per `neat/privacy/index.html` (la pagina ha solo italiano e
   inglese). Consegnala come testo nel tuo Esito; la inserisce il Developer.
4. **Store**: Novità 1.3 (riga `novita.1.3` in `NEAT_novita.xlsx`), paragrafo nuovo della descrizione e testo
   promozionale nelle 9 lingue (`NEAT_store_tradotto.xlsx`), poi `scripts/store_metadata.py`. Niente parolacce nei
   testi dello store. Rispetta i limiti di caratteri.
5. PR verso `main`, non unirla. Nell'Esito: nomi dei livelli scelti per lingua e dubbi.

## Non fare
Non cambiare l'italiano né le battute. Non scrivere a William. Solo SSD; a fine turno niente acceso.

## Esito
