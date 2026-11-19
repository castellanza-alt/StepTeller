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
**19/11/2026, Designer.** Ramo `design/T-023-nasty`.

**Consegna**
- Tela: https://claude.ai/artifact/AVJ8rdN4Jpd6nAbZzzcHeF, 7 tavole. È privata finché non la condivide il suo
  proprietario.
- Specifica: `docs/design/T-023-nasty-grafica.md`.
- Disegni: in `docs/design/T-023-nasty/` ci sono i 4 SVG del cuore e un'anteprima.

**Cosa c'è sulla tela**
1. **Il cuore** in due aspetti, giorno e notte. Il volume è come quello dello stivale dell'icona di Natale. Senza volto
   e senza niente che ricordi Salute.
2. **Il fumetto in Home** nello spazio degli avvisi. Per livello mostra la battuta più corta, una media e la più lunga,
   su 17 Pro Max e SE, sulle schermate vere dell'app.
3. **Il movimento**: battito, sussulto, tocco e Riduci movimento. La tavola si può provare.
4. **La pagina nuova dell'introduzione**, con l'avviso prima di NASTY.
5. **Impostazioni › Voce**, con la manopola delle notifiche.
6. **Una battuta vera** sotto l'obiettivo, nel pop-up dei Jolly e nel titolo della festa.

**Misure.** Tutte le 196 battute ci stanno. Solo N121, nel titolo della festa, scende ad Anton 24.

**Da decidere.** Mancano 5 testi piccoli (tasti dell'avviso, etichetta della manopola, nota della sezione, VoiceOver,
etichetta «VOCE»); sono nel §7 della specifica. Restano da decidere anche i numeri di Poche e Tante.

**Higgsfield.** 1 generazione da 1,5 crediti. Saldo 13,5 → 12.
