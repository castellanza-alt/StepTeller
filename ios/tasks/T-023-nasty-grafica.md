# T-023 NASTY: il cuore, il fumetto e le schermate nuove
**Assegnato a:** Designer **Base:** `main` **Stato:** assegnato 19/11/2026

## Perché
NASTY è la 1.3 (D-045). William ha approvato carattere, tono e 196 battute (`docs/design/T-021-nasty/catalogo/
catalogo-approvato.md`) e il progetto (`docs/design/T-022-nasty-progetto.md`, da leggere per intero, con D-044).
Serve la grafica, su una tela che William approva prima del codice.

## Cosa fare (ramo `design/T-023-nasty`, worktree `/Volumes/SSD/Developer/neat-design`)
1. **Il cuore di NEAT**, senza volto, nel nostro stile manga (rosso, bianco, nero; token esistenti). Non deve
   ricordare l'icona di Apple Salute (niente cuore rosa su quadrato bianco). Due aspetti: **Piccante** (scuro, bordo a
   punte) e **NASTY** (nero con contorno rosso, crepato, con le corna). Giorno e notte. In Normale il cuore non c'è.
   Disegnalo in SVG; Higgsfield solo per una base, al massimo 3 crediti (ne restano 13,5).
2. **Il fumetto** in Home, nello spazio degli avvisi: battute fino a 12 parole, e la forma «titolo / testo» non serve
   qui. Mostra 3 battute vere per livello, la più corta e la più lunga del catalogo, su SE e 17 Pro Max.
3. **Come si muove:** battito lento, sussulto al cambio di battuta, reazione al tocco. Versione «Riduci movimento».
4. **Introduzione:** la pagina nuova «Vuoi che te lo dica gentilmente o che te lo dica davvero?» con le tre scelte e
   l'avviso prima di NASTY («Parolacce e insulti. L'hai voluto tu.»).
5. **Impostazioni › Voce:** tre livelli e la manopola delle notifiche (Poche · Normali · Tante), con le note.
6. Riga sotto l'obiettivo, pop-up di Jolly e serie, titolo della festa: fai vedere una battuta vera in ognuno e
   segnala quelle del catalogo che non ci stanno.
7. Specifica `docs/design/T-023-nasty-grafica.md` con misure e token, tela pubblicata, PR verso `main` senza
   unirla. Mandami il link della tela: la porto io a William.

## Disco
Solo SSD: file pesanti in `/Volumes/SSD/Temp/NEAT/`, cancellati a fine compito; a fine turno niente acceso.

## Non fare
Niente codice dell'app, niente testi nuovi (le battute sono quelle approvate), non scrivere a William.

## Esito
