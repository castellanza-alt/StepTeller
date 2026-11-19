# T-030 Screenshot dello store per la 1.3
**Assegnato a:** Designer **Base:** `main` dopo il merge della #56 **Stato:** assegnato 19/11/2026

## Perché
Con la 1.3 la Home di serie mostra il cuore e il fumetto (D-047): gli screenshot 01 e 02 non corrispondono più
all'app. In più 02 e 03 mostrano 16 km/h, che dalla 1.2 non esiste (massimo 10 km/h, D-042). Vedi §8 di
`docs/design/T-023-nasty-grafica.md`.

## Cosa fare (ramo `design/T-030-screenshot`, worktree `/Volumes/SSD/Developer/neat-design`)
1. Rifai gli screenshot 01, 02 e 03 nelle 10 lingue (più es-MX e fr-CA, che riusano es e fr), dall'app vera sul
   Simulatore, con lo stesso metodo e lo stesso formato degli attuali (`scripts/store_screenshots.py`,
   `localizzazione/screenshot/`). Gli altri restano.
2. Nel fumetto solo battute **senza parolacce** (lo store le legge chiunque): scegline una del livello Senza pietà
   che non ne ha (per esempio N007 o N036) e usa la stessa in tutte le lingue. Se il titolo dello screenshot 01
   merita di citare la voce, proponi il testo italiano a me: non scriverlo nello screenshot senza approvazione.
3. Velocità mostrata: entro 10 km/h (6 mph dove si usano le miglia).
4. Consegna a me un'immagine sola con i tre screenshot italiani affiancati prima/dopo (per mostrarla a William in
   chat) e la PR verso `main` con tutte le lingue, non unita.

## Disco
Solo SSD; file pesanti in `/Volumes/SSD/Temp/NEAT/`; a fine turno niente acceso.

## Non fare
Non caricare niente su App Store Connect, nessun commit `[store…]`. Non scrivere a William.

## Esito
