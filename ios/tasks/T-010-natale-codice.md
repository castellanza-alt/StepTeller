# T-010 Tema di Natale nell'app
**Assegnato a:** Developer **Base:** `main` aggiornato (con T-006 unita) **Stato:** assegnato 17/11/2026 — **urgente**, PR entro il 24/11

## Perché
1.2 «Natale» da inviare ad Apple entro il 1° dicembre (D-036). Regole in D-037, specifica del Designer in
`docs/design/T-004-natale.md` (anteprima e icona in `docs/design/T-004-natale/`).

## Cosa fare (ramo `task/T-010-natale`)
1. Meccanismo unico delle stagioni (§8 della specifica): stagione attiva da data (1/12–6/1 per Natale), interruttore
   «Temi stagionali» acceso di serie, salvato anche in iCloud e nel Backup (campi aggiunti, non rinominati).
2. Token nuovi `snow`, `gold`, `pine` giorno/notte in `MangaTokens.swift`; tutte le decorazioni della specifica (neve,
   luci, cappello, «FATTO!», fiamma, festa, splash, widget), con «Riduci movimento».
3. Icona alternativa dall'`AppIconNatale.icon` del Designer: cambio con l'API di iOS secondo le regole della specifica,
   ritorno all'icona normale a fine stagione o a interruttore spento.
4. Argomento di debug (`#if DEBUG`) per forzare la stagione, per gli screenshot e per la QA.
5. Testi nuovi (`set.season.toggle`, `set.season.note`) in bozza: le traduzioni arrivano dopo l'ok di William.
6. `swift test`, compilazione, prova sul Simulatore giorno/notte con e senza stagione; revisione indipendente; riga nella
   sezione 1.2 del CHANGELOG; PR verso `main`, non unirla.

## Riuscita
Fuori stagione l'app è identica alla 1.1; in stagione corrisponde all'anteprima; spegnendo l'interruttore tutto torna
normale, icona compresa; CI verde.

## Non fare
Non unire, nessuna build TestFlight, nessun tag `[testflight]`/`[apple]`/`[store…]`, nessuna chiave. Non scrivere a William.

## Esito
