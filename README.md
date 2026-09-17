# Step Teller

PWA per rispondere a una domanda sola: **quanti minuti devo stare sul tappeto, e a che velocità, per arrivare all'obiettivo di passi di oggi.**

Live: https://castellanza-alt.github.io/StepTeller/ (il percorso è case-sensitive)

## Cosa fa
- **Quanto manca** — passi di oggi + obiettivo (default 10.000) → minuti necessari alla velocità scelta, con 6 andature di confronto a un tocco.
- **Quanti passi** — velocità × durata → passi stimati, km, cadenza.
- **Cammino / Corsa** — due curve cadenza(velocità) continue e monotone (niente gradini).
- **Taratura personale** — coppie velocità → cadenza misurate sul tappeto. 1 punto scala la curva, 2+ punti la fanno passare dai dati.
- Ricorda ultimi valori e taratura (localStorage, solo sul dispositivo). I «passi di oggi» si azzerano al cambio di data.
- Offline, installabile, tema chiaro/scuro.

## Parametri URL (per Comandi iOS)
`?passi=7200` · `&target=10000` · `&v=6` · `&modo=corsa` · `&min=30`

Esempio Comando: *Trova campioni Salute (Passi, oggi) → Calcola statistiche (somma) → Apri URL* `https://castellanza-alt.github.io/StepTeller/?passi=[somma]`

## Modello
`passi = cadenza(v) × minuti`. Le curve standard in `model.js` sono valori di letteratura per un uomo di ~178 cm (**Inferred**, non misurati). La taratura le sostituisce con i dati reali.

## Aggiornare
Sostituire i file e incrementare `CACHE` in `sw.js`.

## File
`index.html` · `model.js` · `sw.js` · `manifest.webmanifest` · `icon-180.png` · `icon-192.png` · `icon-512.png`
