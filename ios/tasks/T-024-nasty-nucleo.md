# T-024 NASTY: situazioni, scelta della battuta e catalogo nel nucleo
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026

## Perché
NASTY è la 1.3 (D-045). Progetto in `docs/design/T-022-nasty-progetto.md` (§2, §4, §6), regole in D-044. La grafica
arriva con T-023: qui si fa solo la logica, senza interfaccia, così non dipende dal Designer.

## Cosa fare (ramo `task/T-024-nasty-nucleo`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Apri la 1.3:** `MARKETING_VERSION` 1.3 e sezione «## 1.3 — in lavorazione» in cima al CHANGELOG (la 1.2 è
   «inviata ad Apple» e non si tocca; regole in `RILASCIO.md`).
2. **Catalogo** in `StepTellerCore`: modello (id, livello, situazione, testo, titolo facoltativo per le notifiche),
   lettura da JSON, e **controllo** (formato, versione, segnaposti ammessi `{passi} {obiettivo} {mancano} {minuti}
   {serie} {jolly} {percento}`, lunghezza massima, livelli e situazioni noti). Un file rifiutato non sostituisce mai
   quello buono. Il catalogo di bordo si genera da `docs/design/T-021-nasty/catalogo/catalogo-approvato.json` con uno
   script in `scripts/`, che produce anche il `battute.json` per il sito; un test verifica che siano allineati.
3. **Situazione** come funzione pura dai soli dati che l'app ha (passi, obiettivo, percentuale, minuti mancanti, ora,
   serie, Jolly, cambio di obiettivo, evento Jolly/serie), con le stesse situazioni del catalogo e soglie scritte
   nel codice e nei test.
4. **Scelta della battuta:** a caso dentro la situazione e il livello, senza ripetere le ultime 20 (memoria passata
   come valore), mai una battuta il cui segnaposto non ha valore; sotto i 50 passi solo battute senza `{passi}`
   (regola di William: mai «zero passi»). Numeri formattati come nel resto dell'app.
5. **Piano delle notifiche roast** come funzione pura: tra le 10 e le 20, orari non fissi, almeno 90 minuti tra due,
   numero secondo livello e manopola (NASTY 4–5, Piccante 1–2; Poche · Normali · Tante), nessuna dopo l'obiettivo
   raggiunto, preferenza per battute senza `{passi}`. Casualità con seme, così i test sono ripetibili.
6. Campi nuovi di impostazioni (livello della voce, frequenza) compatibili con iCloud e Backup vecchi.
7. Test per tutto, `swift test` verde su Linux e Mac, Debug e Release; riga nel CHANGELOG; revisione indipendente;
   PR verso `main`, non unirla.

## Non fare
Niente interfaccia, niente rete (lo scaricamento arriva con il compito dell'app), nessuna build TestFlight. Solo
italiano: nelle altre lingue i livelli Piccante e NASTY non sono disponibili (lo espone il nucleo come dato).
Non scrivere a William.

## Disco
Solo SSD; a fine turno niente acceso.

## Esito
