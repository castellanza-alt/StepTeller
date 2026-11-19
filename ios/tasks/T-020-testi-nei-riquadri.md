# T-020 Nessuna parola fuori dai riquadri, in tutte le lingue
**Assegnato a:** Developer **Base:** `main` **Stato:** assegnato 19/11/2026, urgente per la 1.2

## Perché
William, 19/11, dopo aver approvato i testi italiani della 1.2: «occhio alla grafica perché le parole escono dal
quadrato». Non ha detto dove. Le traduzioni della 1.2 arrivano con la PR #41 (Traduttore): DE, FR e PT-BR sono le
più lunghe; le targhette dei pop-up in EN/ES/DE arrivano a 22–24 caratteri.

## Cosa fare (ramo `task/T-020-riquadri`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. Controlla sul Simulatore ogni testo nuovo della 1.2 dentro un riquadro: pop-up Jolly (guadagnato, usato, regalo),
   festa dell'obiettivo, Impostazioni › Notifiche e Temi stagionali, widget. Fallo in italiano e in tutte le lingue
   della PR #41 (prendi i cataloghi dal ramo `lang/T-014-traduzioni-1.2`, senza unirlo), su iPhone SE e 17 Pro Max,
   con testo normale e con il testo più grande di Accessibilità.
2. Correggi l'impaginazione in modo robusto: il testo va a capo o si riduce con misura, senza uscire dal riquadro e
   senza essere tagliato. Niente correzioni lingua per lingua. Se un testo non ci sta proprio, segnalalo a me (il
   Traduttore lo accorcia).
3. Screenshot prima/dopo dei casi peggiori in `tasks/T-020/`. Riga nel CHANGELOG (la 1.2 torna «in lavorazione» se
   ancora «su TestFlight»: regola 4 di RILASCIO.md). `swift test`, Debug e Release, revisione indipendente del diff,
   PR verso `main`, non unirla.

## Disco
Solo SSD: screenshot pesanti in `/Volumes/SSD/Temp/NEAT/`, cancellati a fine compito; a fine turno niente acceso.

## Non fare
Non unire, nessuna build TestFlight, non cambiare i testi. Non scrivere a William.

## Esito
**Developer, 19/11/2026** (ramo `task/T-020-riquadri`, su `main` cdbf076 con le traduzioni #41)
- Verifica: Simulatore Debug su iPhone SE e 17 Pro Max, 10 lingue, cataloghi di `main` cdbf076. Casi: pop-up Jolly
  usato con 0 Jolly (targhetta più lunga, «JOLLY FINITI…»), guadagnato, regalo; festa dell'obiettivo; Impostazioni;
  widget. Testo normale e testo Accessibilità più grande (AX5) per Impostazioni, widget e pop-up.
- Unico testo fuori dal riquadro con i testi attuali: in **giapponese** il titolo del regalo «おまもりのプレゼント！»
  usciva a destra del pannello (il «！» era tagliato), su SE e Pro Max. Le altre lingue stavano dentro, alcune a
  pochi punti dal bordo (ES «¡COMODÍN DE REGALO!», DE «JOKER EINGESETZT»).
- Con il testo più grande: nelle Impostazioni l'etichetta dell'ora del promemoria si spezzava a metà parola (FR
  «Heur/e», DE «Uhr-/zeit»); i segmenti di Tema e Unità a quella misura sono troppo stretti per i nomi interi. I testi
  dei pop-up, della festa e del widget hanno misura fissa (Anton) e non cambiano con il testo più grande.
- Correzione, uguale per tutte le lingue: titolo e targhetta dei pop-up (una riga) si riducono fino al 60/70% per
  stare nel pannello, lasciando 14 pt a destra per l'inclinazione; le frasi vanno a capo fino a 3 righe prima di
  ridursi; nella festa titolo, targhetta e serie si riducono se superassero 330 pt. Nelle Impostazioni, alle misure
  di Accessibilità, l'ora va sotto l'etichetta e Tema/Unità diventano un menu con i nomi interi. Testi invariati.
- Opzione solo Debug `-stepteller.debugPopupJolly N` per fotografare il pop-up con N Jolly (0 = targhetta più lunga).
- Nessun testo da far accorciare al Traduttore. Screenshot in `tasks/T-020/` (1 e 2 prima/dopo, 3–5 dopo, 10 lingue).
- 117 test verdi, Debug e Release OK, revisione indipendente: nessun errore; applicato il suo suggerimento
  (VoiceOver non legge due volte «Ora» quando l'etichetta va sopra).

