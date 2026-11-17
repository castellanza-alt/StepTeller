# T-009 Scheda dello store: aggiornamento dopo una versione pubblicata
**Assegnato a:** Developer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026 — **urgente**, blocca l'invio della 1.1

## Perché
William ha approvato l'invio della 1.1 con età 4+ (D-007). Il commit `[store-prova]` di `main` (esecuzione
44076486789) si ferma con «Nessuna «App Information» modificabile su App Store Connect». Con la 1.0 pubblicata, Apple
crea la «App Information» modificabile solo dopo che esiste la nuova versione (1.1) in preparazione, ma
`scripts/asc_store.py` (riga ~565) controlla prima le informazioni dell'app (`app_info_section`) e solo dopo crea la
versione (`version_section`). Con la 1.0 non succedeva perché era la prima versione.

## Cosa fare (ramo `task/T-009-scheda`, in un worktree **separato** da quello di T-006, es. `~/Developer/neat-dev-fix`, da togliere alla fine)
1. Correggi l'ordine o il controllo così che:
   - `[store-prova]`, senza versione 1.1 su App Store Connect, non si fermi: dica «la versione 1.1 verrà creata» e che
     età, nome e sottotitolo si controlleranno su quella (oppure li confronti con la «App Information» pubblicata, in
     sola lettura);
   - `[store]` crei prima la versione 1.1, poi rilegga le «App Information» e applichi età (solo 4+, il controllo che
     ferma tutto se Apple calcola altro resta il primo passo sulle informazioni), nome, sottotitolo, categorie, testi,
     Novità, screenshot, note per il revisore;
   - `[store-invio]` resti com'è.
2. Prova in locale solo ciò che non chiama Apple (sintassi, funzioni pure); niente chiavi: le chiamate vere le fa la CI
   quando il Director fa il commit con il tag.
3. Riga nel CHANGELOG solo se la CI la chiede per questo file (è uno script, non codice dell'app); revisione
   indipendente del diff; PR verso `main`, non unirla. Poi torna a T-006.

## Riuscita
Diff piccolo e leggibile; con la 1.0 pubblicata e senza 1.1 su App Store Connect, la prova non si ferma e la scrittura
crea la versione prima di toccare le informazioni.

## Non fare
Nessun tag `[store…]`, `[testflight]` o `[apple]` nei commit: li fa solo il Director. Nessuna chiave. Non unire. Non
scrivere a William.

## Esito
