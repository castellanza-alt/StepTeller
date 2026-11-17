# T-011 Pop-up e notifiche di obiettivo e Jolly nella forma finale
**Assegnato a:** Developer **Base:** `main` aggiornato **Stato:** assegnato 17/11/2026, dopo T-010

## Perché
T-006 ha messo la logica con un pop-up provvisorio. La forma e i testi finali sono nella specifica del Designer
`docs/design/T-005-popup-jolly.md` (anteprima linkata lì).

## Cosa fare (ramo `task/T-011-popup`)
1. Pop-up «Jolly guadagnato» e «Jolly usato» come da specifica (vignetta, animazioni, aptica, coda degli eventi,
   giorno/notte, variante di Natale di T-010).
2. Testi italiani della specifica (22) al posto delle bozze di T-006, sezione «Notifiche» in Impostazioni. Il Director
   ti dirà se William li ha cambiati; le altre lingue restano in bozza finché non arriva la traduzione.
3. Fascia «mai di notte»: 22:00–08:00, le notifiche di quella fascia si spostano alle 08:00 (decisione del Director).
4. Verifiche come in T-006; riga nella sezione 1.2 del CHANGELOG; PR verso `main`, non unirla.

## Non fare
Come in T-010.

## Esito
17/11/2026, Developer. PR https://github.com/castellanza-alt/StepTeller/pull/37 (ramo `task/T-011-popup`), impilata su T-010
(#36): da ribasare su `main` dopo l'unione della #36.
- **Fatto:** pop-up della specifica (vignetta, movimento, aptica, Natale, niente chiusura automatica), coda usato →
  guadagnato → festa con 0,3 s, notifiche con i testi della specifica, notte 22–8 spostata alle 8 anche per
  l'obiettivo, tocco su una notifica che apre la Home, sezione «Notifiche» in Impostazioni, 23 testi in bozza.
- **Provato:** `swift test` 92/92, compilazione Debug e Release, pop-up sul Simulatore giorno/notte e a Natale.
  Revisione indipendente: 3 bug corretti (obiettivo notturno ritirato, scintille senza fine, streak del widget).
- **Solo sul telefono:** notifiche vere (8 del mattino, tocco), «OK» e festa subito dopo, VoiceOver.
- **Per il Designer:** plurali mancanti nei testi delle notifiche, `jolly.used.vo` con 0 Jolly, «IERI» per Jolly più vecchi.
