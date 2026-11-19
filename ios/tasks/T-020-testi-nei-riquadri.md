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
