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
17/11/2026, Developer. PR verso `main` dal ramo `task/T-010-natale` (link nella PR stessa e nel riepilogo al Director),
non unita.
- **Fatto:** `Season` nel nucleo (periodo 1/12–6/1, test), `SeasonPalette`/`SeasonLook`, neve, luci, cappello (pomello,
  «FATTO!», fiamma dello Storico, festa), neve ferma nello Storico e nei widget, cappello nello splash, icona
  `AppIconNatale` con `setAlternateIconName` (dopo splash + 0,6 s, mai durante l'introduzione), interruttore «Temi
  stagionali» in iCloud e Backup, testi in bozza, debug `-stepteller.season christmas|none`.
- **Provato:** `swift test` 90/90, compilazione Debug e Release; Simulatore giorno e notte con e senza stagione
  (Home, «FATTO!», Storico, festa, widget, splash), icona di Natale e ritorno alla normale con l'avviso di iOS.
  Revisione indipendente: 3 problemi corretti (avviso dell'icona da iCloud/introduzione, luci con «Riduci movimento»).
- **Solo sul telefono:** icona sul vero schermo Home (varianti chiara/scura/tinta), widget sul vero schermo Home,
  fluidità della neve.
- **Scelta da confermare (Director):** l'avviso dell'icona non compare durante l'introduzione: arriva alla sua fine.
