# T-015 — Registro delle generazioni Higgsfield (18/11/2026)

Tetto: 39 crediti, nessuna ricarica (D-040). Saldo verificato con `balance`: **39 → 22,5**, cioè **16,5 crediti spesi**.
Ho controllato il costo con `get_cost` prima di generare:
- `nano_banana_2_lite` 1k: 1 credito;
- `nano_banana_2_1` 1k: 1,5 crediti;
- `nano_banana_2_1` 2k: 2 crediti.

Le immagini di partenza sono quelle dell'app: la Home attuale di giorno e di notte, allargate a 9:16 con bande ai lati di
62 px su 1005, e l'icona attuale in PNG. Il modello ha rifatto il disegno dentro le stesse proporzioni; poi ho tagliato le
bande per tornare a 881 × 1786. Così la strada resta dove corre il cursore della velocità, `SpeedTrack.road`.

Gli originali restano nell'archivio Higgsfield con il loro id; nel repository ci sono solo gli asset finali, in `asset/`.

| # | Id del lavoro | Modello | Crediti | Uso | Esito |
|---|---|---|---|---|---|
| 1 | 82c5d191 | nano_banana_2_lite 1k | 1 | prova: stivale e neve sulla Home di giorno | buona idea, ma l'inquadratura cambia (formato 9:16): scartata |
| 2 | c9952379 | nano_banana_2_1 2k | 2 | Home di giorno con stivale e neve, dal riferimento allargato | **base di tutto**: gamba e strada combaciano con l'originale |
| 3 | 83fefbbc | nano_banana_2_1 2k | 2 | sfondo di giorno senza gamba, dalla #2 | **asset** `HomeNataleDay.jpg` |
| 4 | 07da37d4 | nano_banana_2_1 2k | 2 | gamba isolata su magenta, dalla #2 | **fallita sul server**, crediti addebitati |
| 5 | f240e03e | nano_banana_2_1 2k | 2 | notte, dalla #2 con la Home di notte come riferimento | scartata: neve troppo chiara, i testi chiari non si leggerebbero |
| 6 | e0d96927 | nano_banana_2_1 2k | 2 | sfondo di notte, dalla #3 con la Home di notte come riferimento | **asset** `HomeNataleNight.jpg` |
| 7 | f0d28da8 | nano_banana_2_1 1k | 1,5 | slitta con due renne, su magenta | **asset** `Slitta@2x/3x.png` |
| 8 | 8bc49b75 | image_background_remover | 1 | ritaglio della gamba dalla #2 | **asset** `HomeLegNataleDay.png`; la notte è ricolorata da qui (spec §2.3) |
| 9 | b97f8f06 | nano_banana_2_1 1k | 1,5 | icona con lo stivale, dall'icona attuale | **asset** `AppIconNatale.icon` (livelli separati per colore) |
| 10 | a420daea | nano_banana_2_1 1k | 1,5 | regalo che si apre con la fiamma, su magenta | **asset** `RegaloJolly@2x/3x.png` |

## Prompt (testo esatto inviato)

**#1 e #2** (il #2 aggiunge le frasi su margini, sole e inquadratura «pixel for pixel»):
> Edit this manga illustration. Keep EXACTLY the same composition and framing pixel for pixel: same camera angle, same leg position and angle, same foot position, same speed lines, and the same winding road with its dashed center line exactly where it is now (the road curves from the horizon at left down to the bottom). Christmas special episode of the same manga. Changes only: 1) the running sneaker and white sock become Santa Claus's boot: glossy black leather boot, sole facing the viewer in the same position as the sneaker sole, sole tread in vivid red and black, a thick white fluffy fur cuff at the top of the boot; the bare skin leg becomes a red trouser leg with black ink folds and halftone screentone shading. 2) the landscape becomes a snowy winter landscape: hills covered in deep white snow with blue-grey screentone shadows, the cypress trees become snow-covered pine trees, snow banks along the road edges, a pale low winter sun, a few snowflakes in the sky. Fill the white side margins naturally with the same scene. Style: Japanese manga ink drawing, bold black ink lines, screentone dots, only black, white, light grey and one vivid red (#E5231B), white paper, high contrast, dynamic action lines. No text, no people, no faces, no religious symbols, not a greeting card, not photorealistic.

**#3**:
> Edit this image: completely remove the red trouser leg and the black Santa boot (and its white fur cuff and the snow spray around the boot). Fill the area where they were with the scene behind them, continuing what is already there: the snowy winter landscape, the snowy hills, the winding road with its dashed center line continuing naturally, pale grey sky with snowflakes and the black diagonal manga speed lines. Keep everything else EXACTLY identical, same framing, same pixel positions of the road, horizon, trees and sun. Same manga ink style, black white grey and vivid red. No leg, no foot, no shoe, no person.

**#4**:
> Edit this image: keep ONLY the red trouser leg, the black Santa boot with its red sole and its white fur cuff, and the snow and ice chunks spraying right around the boot, EXACTLY as they are, same position, same size, same pixels. Replace everything else (sky, landscape, road, speed lines, background) with a perfectly flat uniform solid magenta color #FF00FF, no gradient, no texture, no shadow. Clean crisp edges around the leg and boot.

**#5**:
> Redraw the FIRST image as a night scene, using the color palette and night treatment of the SECOND image. Keep EXACTLY the composition of the first image: same Santa boot and red trouser leg in the same position, same snowy landscape, same winding road with dashed line in the same place, same speed lines. Night palette: deep navy sky #0E1430 with small stars and falling snowflakes, a full pale moon low on the horizon at the left instead of the sun, snow and ink highlights in pale icy blue-white #E2EAFF, lavender blue screentone shadows, the trouser leg and sole stay vivid red #FF3B30, the boot stays black with pale blue rim highlights, the fur cuff pale blue-white. Manga ink drawing style, screentone, high contrast. No text, no people, no religious symbols.

**#6**:
> Redraw the FIRST image as a dark night scene using exactly the night palette of the SECOND image. Keep EXACTLY the composition of the first image pixel for pixel: same snowy hills, same pine trees, same winding road with dashed center line in the same place, same speed lines. Night palette: the whole image is dark, dominated by deep navy #0E1430 (sky AND snowy ground): the snow is drawn as dark navy areas with pale icy blue-white #E2EAFF ink highlights, white line strokes and lavender blue screentone, like the second image where the ground is dark with white strokes. Small stars, falling snowflakes, a full pale moon with soft glow low at the left horizon instead of the sun. A few vivid red #FF3B30 accent strokes in the speed lines. Manga ink drawing style, high contrast. No large light areas. No text, no people, no religious symbols.

**#7**:
> A small compact sticker-like icon of a sleigh pulled by two reindeer, side view, moving fast to the right, seen slightly from above, the whole group fits in a wide short rectangle (about 2.2 times wider than tall). Vivid red #E5231B sleigh with curled runners, black ink reindeer silhouettes with simple antlers galloping, a short red rein, a few motion speed lines behind and a little snow spray under the runners. Nobody riding the sleigh, empty sleigh, no character. Japanese manga ink style: bold black outlines, one thick white outline stroke around the whole group like a sticker, screentone dots, only black, white and vivid red. Isolated on a perfectly flat solid magenta #FF00FF background, no shadow on the background. No text.

**#8**: `remove_background` su #2, senza prompt.

**#9**:
> Redesign this flat app icon keeping EXACTLY the same flat graphic style (only three flat colors: near-black #0C0C0C background, pure white #FFFFFF, vivid red #E5231B, no gradients, no shading, bold simple shapes, thick black gaps between shapes) and the same composition: the big red tread sole seen from below filling the left and center, same angle, same size, same red tread blocks. Change the shoe into Santa Claus's boot: remove the laces; the boot upper is black drawn with a few bold white highlight strokes on the outline; at the top right, where the ankle and sock were, a big fluffy white fur cuff with a scalloped bumpy edge; above the cuff, at the top edge, a short piece of red trouser leg. Keep the white and red speed streaks at bottom left. No snowflakes, no hat, no text, no letters.

**#10**:
> Japanese manga ink illustration, dramatic action panel: a square gift box bursting open, its lid flying off upwards, a big red ribbon and bow uncoiling, and from inside a burst of energy lines and a single bold stylized flame shooting up out of the box. The box is white with bold black ink outlines and screentone shading, the ribbon and the flame are vivid red #E5231B with black ink, radiating speed lines around it. Only black, white and vivid red. High contrast, bold strokes, no gradient. Isolated on a perfectly flat solid magenta #FF00FF background. No text, no letters, no people, no Christmas tree, no stars, no religious symbols.

## Lavoro fatto in locale (gratis)

Tutto in Python con PIL e numpy:
- taglio delle bande laterali, ridimensionamento a @3x e JPEG con qualità 86;
- gamba in PNG a 256 colori con trasparenza;
- scontorno del magenta con correzione del bordo viola;
- gamba di notte ricolorata dalla gamba di giorno (§2.3 della specifica);
- separazione dell'icona in livello rosso e livello bianco a 2048 px.
