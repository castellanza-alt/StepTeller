# T-022 NASTY: progetto dell'app (prima del codice)

**Director, 19/11/2026.** Approvato da William (D-045), poi corretto da D-046 (tutte le lingue) e **D-047**: il terzo
livello in italiano si chiama «Senza pietà» ed è quello di serie per tutti, anche per chi aggiorna; niente avviso
prima di attivarlo. Dove il testo sotto dice il contrario, vale D-047. Regole: D-044. Carattere: `T-021-nasty-roast.md`. Battute
approvate: `T-021-nasty/catalogo/catalogo-approvato.md` (196: 137 NASTY, 59 Piccante). Nessun codice finché William
non approva questo documento.

## 1. Cosa vede l'utente
- **Tre livelli** in Impostazioni › Voce: **Normale** (l'app di oggi) · **Piccante** · **NASTY**. Di serie Normale.
- **Introduzione:** una pagina nuova dopo quella dell'obiettivo: «Vuoi che te lo dica gentilmente o che te lo dica
  davvero?» con le tre scelte. Su NASTY un avviso prima di confermare: «Parolacce e insulti. L'hai voluto tu.»
- **NEAT, il cuore:** con Piccante o NASTY in Home compare il cuore con il suo fumetto, nello spazio degli avvisi.
  Rosso e pulito non esiste (in Normale il cuore non c'è): Piccante = cuore scuro a punte; NASTY = cuore nero con
  contorno rosso, crepato, con le corna. Senza volto. Batte piano; quando cambia battuta ha un sussulto. Toccarlo
  fa uscire una battuta «se tocchi il cuore».
- **Dove parla:** fumetto in Home (cambia quando cambia la situazione, al massimo una volta l'ora); riga sotto
  l'obiettivo quando lo scegli o lo cambi; pop-up di Jolly e serie; titolo della festa dell'obiettivo; notifiche.
  Storico e widget restano com'è oggi nella prima versione.
- **Notifiche roast:** tra le 10 e le 20, a orari non fissi, mai due a meno di 90 minuti. NASTY 4–5 al giorno,
  Piccante 1–2. Manopola in Impostazioni: Poche · Normali · Tante. Si fermano a obiettivo raggiunto (resta una sola
  notifica, quella «quando ce la fai»). Il promemoria serale e gli avvisi di obiettivo e Jolly prendono la voce del
  livello scelto.

## 2. Come sceglie la battuta
- Situazione calcolata dal nucleo con i soli dati che l'app ha: passi, obiettivo, percentuale, minuti mancanti, ora,
  serie, Jolly, cambio di obiettivo. Stesse situazioni del catalogo.
- Dentro la situazione, a caso, senza ripetere le ultime 20 viste (memoria sul telefono, per livello).
- Segnaposti riempiti con i numeri veri; una battuta il cui numero manca non viene scelta.
- **Mai «zero passi»:** sotto i 50 passi si usano solo le battute senza `{passi}`.

## 3. Notifiche: il limite di iOS
iOS non sveglia l'app ogni ora. Quindi: a ogni apertura e a ogni risveglio da Salute l'app programma le notifiche
roast fino a sera, con le battute giuste per i passi di quel momento; quando arrivano passi nuovi le butta e le
riprogramma. Se non ti muovi arrivano comunque; se ti muovi cambiano. Il numero di passi in una notifica può essere
vecchio di qualche decina di minuti: le notifiche programmate usano di preferenza battute senza `{passi}`.

## 4. Battute aggiornabili senza App Store
- L'app parte con il catalogo approvato dentro (funziona senza rete).
- Una volta al giorno scarica `battute.json` dal sito di NEAT (GitHub Pages, lo stesso della privacy), lo controlla
  (formato, versione, lunghezze, segnaposti) e lo usa al posto di quello a bordo. Se il file è rotto o manca, resta
  il precedente.
- Il file si genera dal catalogo nel repository; si pubblica con il merge su `main`, solo con battute approvate da
  William.
- **È la prima volta che NEAT usa la rete.** L'app scarica un file e non invia niente. Da aggiornare: testo della
  privacy, note per il revisore, e la scheda privacy dello store resta «nessun dato raccolto».

## 5. Apple
- Età: «parolacce o umorismo volgare: frequenti» → **13+** (D-044). Niente sesso, corpo, salute.
- Note per il revisore: i livelli sono una scelta dell'utente, di serie Normale; come attivarli per la prova.
- Screenshot dello store: restano quelli di oggi (Normale).

## 6. Dati
- Livello e frequenza delle notifiche: nelle impostazioni, in iCloud e nel Backup (campi nuovi, compatibili).
- Battute già viste: solo sul telefono.

## 7. Lavori, in ordine
1. **Designer:** il cuore nei due aspetti (Piccante, NASTY), fumetto, pagina dell'introduzione, sezione Voce. Tela
   da far approvare a William.
2. **Developer (nucleo):** situazioni, scelta della battuta, catalogo e suo controllo, con test.
3. **Developer (app):** cuore e fumetto, introduzione, Impostazioni, notifiche roast, scaricamento del catalogo.
4. **QA:** collaudo, con attenzione a notifiche, lingue e «Riduci movimento».
5. Build TestFlight → prova di William → store.

## 8. Decisioni che servono da William
1. **Lingue.** Il catalogo è in italiano. Tradurre un roast non è tradurre un'impostazione: va riscritto lingua per
   lingua. Proposta: prima versione con Piccante e NASTY **solo in italiano** (nelle altre lingue la sezione Voce non
   compare); inglese subito dopo, poi le altre.
2. **Versione.** Proposta: NASTY è la **1.3**; l'Apple Watch (PR #28) passa alla 1.4.
3. **Hargreaves e T-008:** archiviati (decisione già implicita in D-044).
