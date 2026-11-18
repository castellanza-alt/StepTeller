# T-018 Correzioni dal collaudo del Natale (T-017)
**Assegnato a:** Developer (punto 6: Designer) **Base:** `main` 434c97a **Stato:** assegnato 18/11/2026 — urgente,
PR entro il 21/11: dopo si fa la build TestFlight per William

## Perché
Il collaudo T-017 (`comms/qa/T-017.md`, screenshot in `comms/qa/T-017/`) ha trovato un difetto bloccante e alcuni
minori. Decisioni del Director su ognuno qui sotto: si correggono tutti tranne le «osservazioni» del rapporto.

## Developer (ramo `task/T-018-correzioni`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Icona di Natale ingrandita (bloccante, difetto 1).** Sulla schermata Home si vede solo un pezzo di suola. Causa
   probabile: `AppIconNatale.icon` con PNG da 2048 px dove `AppIcon.icon` ha SVG. Correggi (dimensioni/scala in
   `icon.json` o livelli rifatti alla misura giusta; se servono SVG, chiedi a me e li faccio fare al Designer) e
   verifica sul Simulatore che l'icona intera corrisponda all'anteprima `docs/design/T-015-natale/icona-natale-1024.png`
   (suola, risvolto di pelliccia, pantalone), nelle varianti giorno, notte e tinta.
2. **Bande laterali sull'SE (difetto 2).** L'illustrazione di Natale deve arrivare ai bordi su tutti i telefoni
   (riempimento, non bande); verifica che la strada e il cursore restino allineati.
3. **Conti dei Jolly nella coda (difetto 3).** Ogni pop-up mostra il conto a quel punto della coda, non il totale
   finale: regalo «ora hai 3» → guadagnato «ora hai 4»; regalo «ora hai 4» → usato «ti restano 3». Test nel nucleo se
   il conto passo per passo nasce lì.
4. **Pomello che a 10 km/h copre «≈ km» fuori stagione (difetto 4)**, nato con D-042: a 10 km/h, su SE e 17 Pro Max,
   il pomello non deve coprire minuti né km (stessa soluzione del Natale o un'altra pulita).
5. **«SALUTE» sulla luna di notte senza dati (difetto 5)**: leggibile, per esempio con lo stesso alone di «MINUTI».
6. **Slitta che a 3 km/h esce dal bordo sinistro (difetto 7)**: resta tutta dentro lo schermo.
7. Riga nel CHANGELOG; `swift test`, Debug e Release; screenshot prima/dopo di ogni punto nella PR; revisione
   indipendente del diff; PR verso `main`, non unirla.

## Designer (ramo `design/T-018-regalo`, worktree `/Volumes/SSD/Developer/neat-design`)
8. **Bordo quadrato dell'illustrazione del regalo (difetto 6)**: ritaglia `RegaloJolly` @2x/@3x così che i tratteggi
   sfumino o seguano la forma, senza bordo dritto; nessun credito Higgsfield se si può fare in locale. PR verso `main`
   con i soli asset (il Developer li prende dopo), non unirla.

## Disco
Solo SSD: file pesanti in `/Volumes/SSD/Temp/NEAT/`, cancellati a fine compito; a fine turno niente acceso.

## Non fare
Non unire, nessuna build TestFlight, nessun tag, nessuna chiave. Non scrivere a William.

## Esito
