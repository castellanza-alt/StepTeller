# T-005 Pop-up e notifiche di obiettivo e Jolly

**Designer, 17/11/2026.** Regole: D-038. Logica e pop-up provvisori: T-006 (Developer). Coerente con
`App/GoalCelebration.swift` (festa dell'obiettivo, che resta com'è). Anteprima ferma: https://claude.ai/artifact/5qwTXAbVtKCeqQTK3Yximp (sorgente
`T-005-popup-jolly-anteprima.html`).

Regole generali: misure in pt sul telaio 390 × 844; colori solo da `MangaPalette` (`paper`, `ink`, `red`, giorno
#FFFFFF / #141414 / #E5231B, notte #0E1430 / #E2EAFF / #FF3B30) e, a Natale, dai token di T-004 (`pine`, `gold`).
Font Anton (`AntonText`, `GlyphText`, `TagText`) come la festa. Nessun token nuovo.

## 1. Pop-up «Jolly guadagnato» e «Jolly usato»

### 1.1 Quando
- Alla prima apertura dopo l'evento, dopo lo splash; **mai ripetuto** (l'evento si segna come mostrato appena il
  pop-up appare).
- Più eventi in coda, uno alla volta, 0,3 s tra l'uno e l'altro, in quest'ordine: **Jolly usato → Jolly guadagnato →
  festa dell'obiettivo** (dal più vecchio al più nuovo).
- Più eventi dello stesso tipo non ancora mostrati (es. app non aperta per giorni) diventano **un solo** pop-up con il
  totale: «−2», «+2».

### 1.2 Disposizione (uguale nei due pop-up)
Strati dal fondo:
1. Velo `paper` all'opacità 0,94 su tutto lo schermo (come la festa).
2. Solo «guadagnato»: raggi `RaysView` della festa (`KineticLines.rays(cx: 195, cy: 380, count: 90, innerMin: 150,
   innerMax: 230, outer: 700, seed: 7, redEvery: 7)`) con la stessa maschera radiale. «Usato»: nessun raggio.
3. **Vignetta** `Vignette(shape: .panelB, width: 318)` (fondo `paper`, bordo `ink` 3), centrata in orizzontale
   (x 36), centro verticale a y 430, ruotata **−4°**. Contenuto allineato a sinistra, padding della vignetta:

| # | Elemento | Specifica |
|---|---|---|
| a | Titolo | Anton 30, tracking 0,02, `ink`; `manga(rotate: -5, skew: -10)`; **padding sopra 16 dentro la vignetta**, altrimenti il titolo ruotato viene tagliato dal bordo (correzione T-013). «JOLLY GUADAGNATO!» / «JOLLY USATO» |
| b | Fiamma + numero | riga, `spacing` 10, padding sopra 12. `FlameIcon(.jolly)` 78 × 95 (`ink` con anima `red`). Numero `GlyphText` 112, lineHeight 0,9, tracking −0,03: guadagnato «+1» riempito `red`, contorno `ink` 2,5, ombra dura `ink` (5, 5); usato «−1» (segno meno U+2212) riempito `paper`, contorno `ink` 2,5, ombra dura `red` (5, 5). `manga(rotate: -5, skew: -10)` |
| c | Frase | Anton 20, tracking 0,02, `ink`, padding sopra 10, al massimo 2 righe (`lineLimit(2)`, `minimumScaleFactor` 0,8) |
| d | Seconda frase (solo «usato») | Anton 20, `red`, padding sopra 2 |
| e | Targhetta Jolly | `TagText` 16, tracking 0,1, testo `paper` su `ink`, padding sopra 12; `manga(rotate: -3, skew: -10)` |
| f | Nota (solo «guadagnato») | Anton 14, tracking 0,04, `ink` all'opacità 0,7, padding sopra 10 |
| g | Bottone | `TagText` 20, tracking 0,1, testo `ink` su `paper`, bordo `ink`, padding 6 / 22; allineato a destra, padding sopra 16; area di tocco minima 44 × 44; `PressScale` |

4. A Natale (tema T-004 attivo): cappello `santaHat` largo 46 sulla fiamma, aggancio (39, 16) nel riquadro 78 × 95,
   rotazione −10°; scintille (solo «guadagnato») nei colori `[red, ink, pine, gold]`. Il resto uguale.

### 1.3 Movimento
| Fase | Cosa | Curva |
|---|---|---|
| Entrata | velo e raggi: opacità 0 → 1 | `.easeOut(duration: 0.2)` |
| | vignetta: scala 0,6 → 1, rotazione −12° → −4° | `.spring(duration: 0.5, bounce: 0.45)`, ritardo 0,05 s (la `pop` della festa) |
| | guadagnato: fiamma scala 0 → 1 | `.spring(duration: 0.45, bounce: 0.5)`, ritardo 0,15 s; poi scintille della festa (`Sparks`) dal centro della fiamma |
| | usato: fiamma «scossa» | rotazione 0 → −8° → 8° → −5° → 0, `KeyframeAnimator` lineare 0,4 s, ritardo 0,2 s |
| Uscita | tutto: opacità 1 → 0, scala 1 → 0,96 | `.easeIn(duration: 0.3)` (come `close()` della festa) |
| Riduci movimento | solo opacità 0 → 1 in 0,3 s `.easeOut` e uscita uguale; niente molla, scintille, scossa, raggi fermi | |

**Aptica** all'apparire: guadagnato `.sensoryFeedback(.success)`; usato `.sensoryFeedback(.warning)`.

**Chiusura**: bottone «OK» o tocco in un punto qualsiasi. **Non** si chiude da solo (a differenza della festa, 3,4 s):
il pop-up appare una volta sola e deve essere letto.

**Giorno/notte**: stessi token, il tema già risolto dell'app. Nessuna differenza di misure.

**VoiceOver**: un solo elemento con la frase intera (`jolly.earned.vo` / `jolly.used.vo`), tratto pulsante, suggerimento
«Tocca per chiudere» (`party.close.vo`, esistente).

### 1.4 Testi dei pop-up (italiano, maiuscolo come la festa)
`N` = Jolly guadagnati o usati in questo pop-up (di solito 1), `S` = streak, `J` = Jolly che restano dopo l'evento,
`M` = giorni mancati salvati (= N).

| Chiave | Italiano | Note |
|---|---|---|
| `jolly.earned.title` | JOLLY GUADAGNATO! | |
| `jolly.earned.days` | %lld GIORNI DI FILA! | plurale su S (sempre ≥ 15) |
| `jolly.count` | ORA HAI %lld JOLLY | plurale su J; uno: «ORA HAI 1 JOLLY» |
| `jolly.earned.note` | SE SALTI UN GIORNO, UN JOLLY SALVA LA STREAK. | |
| `jolly.used.title` | JOLLY USATO | |
| `jolly.used.missed` | uno: «IERI NON HAI CHIUSO L'OBIETTIVO.» · altri: «%lld GIORNI SENZA OBIETTIVO.» | plurale su M |
| `jolly.used.saved` | LA STREAK DI %lld GIORNI È SALVA. | plurale su S; uno: «LA STREAK DI 1 GIORNO È SALVA.» |
| `jolly.left` | uno: «TI RESTA 1 JOLLY» · altri: «TI RESTANO %lld JOLLY» | plurale su J, J ≥ 1 |
| `jolly.left.none` | JOLLY FINITI: OGGI NON MOLLARE | al posto di `jolly.left` se J = 0 |
| `jolly.ok` | OK | bottone, entrambi i pop-up |
| `jolly.earned.vo` | Jolly guadagnato: %1$@ giorni di fila, ora hai %2$@ Jolly. | S, J |
| `jolly.used.vo` | Jolly usato: la streak di %1$@ giorni è salva, ti restano %2$@ Jolly. | S, J |

Il numero grande «+N» / «−N» non è un testo da tradurre (`LocalFormat.integer`).

## 2. Notifiche
Stile del promemoria serale esistente (`Reminder.swift`): titolo breve, corpo di una o due frasi, «streak» come nelle
regole in Impostazioni. Numeri con `LocalFormat.integer`. Le notifiche si mandano solo per eventi **di ieri o di oggi**;
eventi più vecchi (app e widget non partiti) restano solo nel pop-up.

| Evento | Chiave | Titolo | Chiave | Corpo |
|---|---|---|---|---|
| Obiettivo raggiunto | `notif.goal.title` | Obiettivo raggiunto! | `notif.goal.body` | %1$@ passi su %2$@. Streak: %3$lld giorni di fila. *(plurale su S; uno: «Streak: 1 giorno.»)* |
| Jolly guadagnato | `notif.jollyEarned.title` | Hai guadagnato un Jolly! | `notif.jollyEarned.body` | %1$lld giorni di fila: ora hai %2$lld Jolly. Se salti un giorno, salva la streak. |
| Jolly usato | `notif.jollyUsed.title` | Jolly usato | `notif.jollyUsed.body` | Ieri non hai chiuso l'obiettivo: la streak di %1$lld giorni è salva. Ti restano %2$lld Jolly. |
| Jolly usato, finiti | — | (stesso titolo) | `notif.jollyUsed.body.none` | Ieri non hai chiuso l'obiettivo: la streak di %lld giorni è salva. Jolly finiti: oggi non mollare. |

Esempi: «Obiettivo raggiunto!» / «10.240 passi su 10.000. Streak: 15 giorni di fila.» —
«Hai guadagnato un Jolly!» / «30 giorni di fila: ora hai 3 Jolly. Se salti un giorno, salva la streak.» —
«Jolly usato» / «Ieri non hai chiuso l'obiettivo: la streak di 32 giorni è salva. Ti restano 2 Jolly.»

Suono e interruzione: predefiniti (`.default`, livello `.active`), come il promemoria. Toccando la notifica si apre
la Home; il pop-up dell'evento appare lì (se non già visto).

## 3. Interruttore in Impostazioni
Nella sezione del promemoria, che si rinomina:
- Titolo della sezione `set.reminder.section`: da «Promemoria serale» a «**Notifiche**» (chiave esistente, testo nuovo).
- Righe, nell'ordine: `Toggle` «Avvisami la sera» (esistente) · riga «Ora» (esistente) · nota del promemoria
  (esistente) · **nuovo** `Toggle` «**Avvisi di obiettivo e Jolly**» (`set.notify.toggle`), `.tint(Theme.accent)`,
  **acceso di serie** · nota sotto (`set.notify.note`): «**Una notifica quando chiudi l'obiettivo (mai di notte) e
  quando guadagni o usi un Jolly. I pop-up nell'app restano.**»
- Spento: niente notifiche di obiettivo e Jolly; i pop-up e la festa restano (sono nell'app, non disturbano).

## 4. Testi nuovi o cambiati (da far approvare a William, poi 10 lingue)
Pop-up 12 (§1.4), notifiche 7 (§2), Impostazioni 2 nuovi + 1 cambiato (§3): **22 in tutto**.

## 5. Cosa resta aperto
- «Mai di notte» per la notifica dell'obiettivo: la fascia oraria la decide il Developer (T-006) con il Director.
