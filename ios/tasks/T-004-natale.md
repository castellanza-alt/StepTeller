# T-004 Tema stagionale di Natale (specifica e icona)
**Assegnato a:** Designer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026 — **urgente**: specifica entro il 19/11

## Perché
William, 17/11: «per ogni stagione un reskin (poi disabilitabile da opzioni) con icona stagionale e grafica stagionale.
Si inizia dal nataleeee». Esce con la 1.2, da inviare ad Apple entro il 1° dicembre (D-036). Regole in D-037.

## Cosa fare (ramo `design/T-004-natale`, worktree `~/Developer/neat-design`)
1. Specifica `ios/docs/design/T-004-natale.md`, stile «Dan Dan Dan» natalizio, giorno e notte:
   - periodo: 1° dicembre – 6 gennaio (confermalo o proponi altro con il motivo);
   - palette: token stagionali con valore giorno/notte in esadecimale, accanto a quelli di `MangaTokens.swift` che
     sostituiscono;
   - decorazioni di Home, Storico, splash e widget (neve, cappello sulla suola, luci, «FATTO!» natalizio…): forma,
     misure in pt, posizione, animazione con tipo/durata/rimbalzo, cosa succede con «Riduci movimento»;
   - testi esatti in italiano di ciò che cambia (pochi: ogni testo nuovo va tradotto in 10 lingue);
   - interruttore in Impostazioni: posizione, etichetta («Temi stagionali»?), nota sotto; acceso di serie;
   - **icona di Natale**: varianti giorno, notte, tinta e trasparente come l'icona attuale (`App/AppIcon.icon`, Icon
     Composer); consegna i livelli in PNG/SVG nel ramo, pronti per il Developer;
   - un mini-schema per le stagioni successive (cosa cambia da una stagione all'altra), così il meccanismo è unico.
2. Anteprima ferma come Artifact privato: Home giorno e notte, Storico, icona sulla schermata Home di iOS.
3. PR verso `main`, non unirla. Poi passa a T-005.

## Riuscita
Il Developer implementa senza domande; nessun colore fuori dai token (quelli nuovi hanno valore giorno/notte); icona
completa in tutte le varianti; testi nuovi al minimo e tutti elencati.

## Non fare
Non toccare il codice Swift. Nessuna spesa o servizio esterno senza il sì del Director. Niente immagini protette da
diritti (Babbo Natale «di marca», personaggi). Non unire. Non scrivere a William.

## Esito

**17/11/2026, Designer.** Specifica `ios/docs/design/T-004-natale.md`, anteprima ferma https://claude.ai/artifact/3LNgsKGVLzj6iGs2bF2QB4
(sorgente `ios/docs/design/T-004-natale/anteprima.html`, immagini ridotte dagli asset in `img/`).
- Periodo confermato 1/12 – 6/1. `paper`/`ink`/`red` invariati; 3 token nuovi giorno/notte (`snow`, `gold`, `pine`).
- Decorazioni: neve che cade in Home (ferma con Riduci movimento), 14 luci lampeggianti sulla strada del cursore,
  cappello (forma `santaHat`) su pomello, vignetta «FATTO!», fiamma dello Storico, festa e splash; neve ferma in
  Storico e nei widget. Tutte le posizioni in pt.
- Icona pronta per Icon Composer: `ios/docs/design/T-004-natale/AppIconNatale.icon/` (icon.json + 5 SVG, tinta
  specificata) e anteprime PNG 1024. Regole del cambio icona con l'avviso di iOS.
- Interruttore «Temi stagionali» nella sezione Tema, acceso di serie. Testi nuovi: 2 (`set.season.toggle`, `set.season.note`).
- Schema unico per le stagioni successive (§8).
- Aperto: pagina pubblicata non riguardata da me dopo la pubblicazione (serve l'accesso a claude.ai nel browser);
  argomento di debug per forzare la stagione negli screenshot (Developer). Le varianti scura e trasparente dell'icona
  le genera Icon Composer: da guardare in Xcode.

