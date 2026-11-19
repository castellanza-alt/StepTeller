# T-030 Screenshot dello store per la 1.3
**Assegnato a:** Designer **Base:** `main` dopo il merge della #56 **Stato:** consegnato 19/11/2026 (PR non unita)

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
**19/11/2026, Designer.** Rifatti 01, 02 e 03 nelle 10 lingue (`store/screenshots/<lingua>/01…03.jpg`); 04–06 non toccati.
- **Dall'app vera:** build Debug di `main` dopo la #56, iPhone 15 Pro Max iOS 27 (come gli originali), 3.465 passi su
  10.000, ore 9:41. Per fissare la battuta: `-stepteller.voice.bubble` passato all'avvio (dominio degli argomenti,
  nessuna modifica al codice). Prima prova scritta nelle preferenze: in 8 lingue l'app la sostituiva con un'altra
  battuta, anche con parolacce, quindi scartata.
- **Battuta:** N007 in tutte le lingue («3.465 passi. Sei un soprammobile con il telefono.»), senza parolacce in
  nessuna, controllata sulle 30 schermate.
- **Velocità:** 01 e 03 in alto 4,0 km/h (2,5 mph in inglese); 02 e 03 in basso 10,0 km/h (6,0 mph): 42 min, 7,0 km.
- **Metodo:** titoli, cornici e impaginazione restano quelli approvati. Le schermate nuove sono messe al posto delle
  vecchie con la stessa scala e la stessa rotazione, misurate per ogni immagine (SIFT); JPEG con le impostazioni di
  `scripts/store_screenshots.py`. Gli script stanno in `docs/design/T-030-screenshot/`.
- **Due ritocchi:** in 02 il riquadro ingrandito dei minuti è sceso di circa 470 px, perché copriva il fumetto; in 03
  la finestra sulla strada è salita di 70 px, perché nell'app nuova «MINUTI MANCANTI» sta più in alto e veniva
  tagliato.
- **Prima/dopo per William:** `tasks/T-030-prima-dopo-it.jpg`.
- **Titolo di 01, proposta (non scritta negli screenshot):** il titolo resta; la riga piccola potrebbe diventare
  «Datti un obiettivo. NEAT ti tiene d'occhio.» al posto di «Datti un obiettivo e controllalo». Serve la tua
  approvazione e poi la traduzione nelle 9 lingue.
- es-MX e fr-CA riusano es e fr come prima. Niente su App Store Connect.

