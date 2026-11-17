# NEAT — decisioni

Numerate, con data, chi ha deciso e perché. Una decisione superata si barra e rimanda a quella nuova, non si cancella.
«William» = decisione del proprietario; «Director» = decisione tecnica del Director, che William può ribaltare.
Le decisioni di prodotto della 1.0 sono nella tabella di `STORE_CHECKLIST.md` e restano valide.

## Scelte aperte
- Classificazione per età della 1.1 (4+ o 9+).
- Quando unire e pubblicare la 1.2 (Apple Watch).

## Prodotto e processo (già in vigore, riportate qui)
- **D-001** Salute solo in lettura (passi), mai scrittura né rete; nessun dato di Salute in iCloud. William.
- **D-002** Versioni, registro e Novità secondo `RILASCIO.md` (22/10/2026). William.
- **D-003** Build TestFlight e scheda dello store solo da `main`, via GitHub Actions (26/10/2026). William.
- **D-004** Repo pubblico: nessun segreto, profilo o chiave nel repo. William.
- **D-005** Italiano per tutto ciò che William legge; i testi da tradurre passano dall'italiano approvato da William.
- **D-006** Tolto l'inserimento dei passi a mano (1.1). William.

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
