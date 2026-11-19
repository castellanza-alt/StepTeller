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

**19/11/2026, Designer, secondo giro.** William: «A me piacciono molto». I due cuori sono approvati e non cambiano.
Ha chiesto più animazione.

- **Livelli.** Ogni cuore è diviso in livelli che, sovrapposti, rifanno il disegno approvato: Piccante in punte,
  corpo e lucido; NASTY in schegge, corna, corpo, crepe e lucido. Sono in `docs/design/T-023-nasty/livelli/`, 11 SVG,
  di giorno e di notte.
- **Tavola 2.** È rifatta: i due cuori affiancati si possono provare sulla tela.
  - A riposo: un doppio colpo. Piccante è morbido e le punte respirano. NASTY è nervoso e le crepe si accendono a ogni
    battito.
  - Quando parla: si gonfia e spara il fumetto. NASTY intanto trema e lancia le schegge.
  - Quando lo tocchi, le reazioni girano a rotazione: Piccante ne ha 3 (riccio, si scansa, sbuffa), NASTY 4 (si
    spacca, cornata, si gira di scatto, crepe che lampeggiano).
  - Con più tocchi entro 4 s si arrabbia di più.
  - Riduci movimento: solo dissolvenze.
- **Specifica.** Il §3 è riscritto con tempi, curve, livelli e aptica per ogni animazione, tutto fattibile in SwiftUI.
- **Testi.** I testi di T-026 §1 sono sulla tela (tavole 5 e 6) e nella specifica (§7).

**19/11/2026, Designer, D-047.** Ho applicato le due decisioni sulla tela e nella specifica.

- **Nome.** Nell'interfaccia il terzo livello si chiama «Senza pietà». Ci sta nel controllo a tre segmenti anche su SE
  (circa 75 pt su circa 103), quindi non serve un menu.
- **Di serie.** L'app parte su Senza pietà:
  - tolti l'avviso e i suoi tasti;
  - l'introduzione parte già su Senza pietà, con sotto la riga «Parolacce e insulti compresi. Si cambia quando vuoi in
    Impostazioni › Voce.»;
  - nuova nota sotto Voce.
- **Prima battuta dopo l'aggiornamento.** È disegnata nella tavola 5, una volta sola: fumetto rosso pieno, bordo e
  ombra più spessi, cuore più grande, linee di richiamo, entrata lenta.
- **Specifica.** Riscritti il §4 e il §5. Nuovo §8, sugli screenshot dello store:
  - cambiano 01 e 02 (Home di giorno e di notte);
  - 03 e 02 mostrano ancora 16 km/h, che dalla 1.2 non esiste più;
  - le battute proposte per gli screenshot sono senza parolacce.
