# T-002 Apple Watch riportato su `main` aggiornato
**Assegnato a:** Developer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026

## Perché
L'app per Apple Watch (1.2) è sul ramo `ia/1.2-watch` (601c235, 24/10), partito da `74fb221`, prima di gran parte della
1.1. Oggi va in conflitto con `main` (CHANGELOG, `project.yml`, foglio dei testi, widget). Va riportata sulla 1.1 così
com'è, senza aggiungere funzioni, per poterla poi rivedere (T-003) e collaudare.

## Cosa fare (ramo `task/T-002-watch`, worktree `~/Developer/neat-dev`)
1. Ramo da `main` aggiornato; porta dentro `origin/ia/1.2-watch` (merge o cherry-pick, a tua scelta) e risolvi i
   conflitti tenendo **tutto** quello della 1.1 (copia in iCloud, Backup, promemoria, niente passi a mano).
2. CHANGELOG: la sezione in cima resta «1.2 — in lavorazione» come sul ramo del Watch, la 1.1 sotto con il suo stato
   attuale, senza cambiarne il testo. `MARKETING_VERSION` 1.2. Foglio `localizzazione/NEAT_testi_tradotti.xlsx`:
   unisci le righe `w.watch.*` e `p.health.watch` a quelle della 1.1 con `scripts/cataloghi.py`, non a mano.
3. Verifica in locale: `swift test` del core; compilazione per Simulatore iPhone **e** watchOS; avvio dell'app sul
   Watch abbinato al Simulatore, con dati che arrivano dal telefono.
4. Revisione indipendente del tuo diff (un subagente che legge il diff senza la tua spiegazione) prima della PR.
5. PR **in bozza** da `task/T-002-watch` verso `main`, con cosa hai provato e cosa no. Non unirla: la 1.2 non entra in
   `main` finché la 1.1 non è pubblicata (lo decide il Director).

## Riuscita
Nessun conflitto con `main`; `swift test` verde; le due compilazioni riuscite; Watch avviato sul Simulatore; CI
«iOS verifica» verde sulla PR; nessuna funzione della 1.1 persa (elencale nella PR con il file dove stanno).

## Non fare
Non unire, non cambiare l'intestazione o lo stato del CHANGELOG oltre a quanto detto, nessuna build TestFlight, nessun
tag `[testflight]`/`[apple]`/`[store]` nei commit, nessuna chiave o credenziale. Non cambiare la grafica del Watch (la
specifica arriva da T-003). Non toccare i file in radice (web app). Non scrivere a William.

## Esito
