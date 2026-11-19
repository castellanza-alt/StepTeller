# T-028 NASTY (1.3): testi dell'interfaccia, privacy e scheda dello store nelle lingue
**Assegnato a:** Traduttore **Base:** `main` **Stato:** fatto 19/11/2026, PR da unire; interfaccia da inserire nel foglio quando T-027 aggiunge le righe

## Perché
William ha approvato il 19/11 i testi italiani di `docs/design/T-026-nasty-testi.md` (interfaccia §1, privacy §2,
store §3). Vanno portati nelle altre lingue. Regole: D-044…D-047, glossario `localizzazione/GLOSSARIO.md` (§5 NASTY).

## Cosa fare (ramo `lang/T-028-nasty-testi`, worktree `/Volumes/SSD/Developer/neat-lang`)
1. **Nome del terzo livello** in ogni lingua (italiano «Senza pietà»): proponi il nome naturale (per esempio EN «No
   mercy»), corto abbastanza per un selettore a tre segmenti su iPhone SE; scrivilo nel glossario. «Piccante» idem.
2. **Interfaccia** (T-026 §1) nelle 9 lingue, nel foglio `localizzazione/NEAT_testi_tradotti.xlsx`. Le righe le
   aggiunge il Developer (T-027): se non ci sono ancora, prepara le traduzioni in una tabella nel tuo Esito con gli
   stessi testi italiani come chiave, e inseriscile appena le righe esistono.
3. **Privacy**: versione inglese dei testi di T-026 §2 per `neat/privacy/index.html` (la pagina ha solo italiano e
   inglese). Consegnala come testo nel tuo Esito; la inserisce il Developer.
4. **Store**: Novità 1.3 (riga `novita.1.3` in `NEAT_novita.xlsx`), paragrafo nuovo della descrizione e testo
   promozionale nelle 9 lingue (`NEAT_store_tradotto.xlsx`), poi `scripts/store_metadata.py`. Niente parolacce nei
   testi dello store. Rispetta i limiti di caratteri.
5. PR verso `main`, non unirla. Nell'Esito: nomi dei livelli scelti per lingua e dubbi.

## Non fare
Non cambiare l'italiano né le battute. Non scrivere a William. Solo SSD; a fine turno niente acceso.

## Esito
**Traduttore, 19/11/2026.** Ramo `lang/T-028-nasty-testi`.

### 1. Nomi dei livelli (glossario §5)
| | EN | ES | FR | DE | PT-BR | JA | KO | ZH-Hans | ZH-Hant |
|---|---|---|---|---|---|---|---|---|---|
| Normale | Normal | Normal | Normal | Normal | Normal | ふつう | 보통 | 普通 | 普通 |
| Piccante | Spicy | Picante | Piquant | Bissig | Picante | ピリ辛 | 매운맛 | 辛辣 | 辛辣 |
| Senza pietà | No mercy | Sin piedad | Sans pitié | Gnadenlos | Sem dó | 容赦なし | 무자비 | 毫不留情 | 毫不留情 |

Il più lungo ha 10 caratteri (ES, FR). Dubbi: DE «Bissig» (mordace) invece di «Scharf» (piccante, ma anche
«eccitato»); PT «Sem dó» è parlato, «Sem piedade» (11) è più comune ma più lungo; KO 무자비 è secco, l'alternativa
독설 («lingua velenosa») suona meglio ma dice meno «senza pietà». Da provare sullo schermo dell'SE (T-027).

### 2. Interfaccia (T-026 §1), da inserire nel foglio
Le righe non ci sono ancora in `NEAT_testi_tradotti.xlsx` (T-027 non le ha aggiunte). Chiave = italiano. Sezione
«Voce»: EN Voice, ES/PT Voz, FR Voix, DE Stimme, JA 口調, KO 말투, ZH 语气/語氣 (NEAT non ha audio, quindi in
JA/KO/ZH «modo di parlare»). JA e KO: nell'introduzione e nella prima battuta parla NEAT, registro informale; la nota
delle Impostazioni nel registro dell'app (です・ます, 해요체).

| Italiano | EN | ES | FR | DE |
|---|---|---|---|---|
| Vuoi che te lo dica gentilmente o che te lo dica davvero? | Want me to say it nicely, or tell it like it is? | ¿Te lo digo con buenas palabras o te lo digo de verdad? | Tu veux que je te le dise gentiment, ou que je te le dise vraiment ? | Soll ich’s dir nett sagen oder so, wie es ist? |
| Parolacce e insulti compresi. Si cambia quando vuoi in Impostazioni › Voce. | Swearing and insults included. Change it anytime in Settings › Voice. | Palabrotas e insultos incluidos. Lo cambias cuando quieras en Ajustes › Voz. | Gros mots et insultes compris. Tu changes quand tu veux dans Réglages › Voix. | Mit Schimpfwörtern und Beleidigungen. Jederzeit änderbar unter Einstellungen › Stimme. |
| Da oggi parlo. Se non reggi: Impostazioni › Voce. | From today, I talk. Can’t take it? Settings › Voice. | Desde hoy hablo. Si no lo aguantas: Ajustes › Voz. | À partir d’aujourd’hui, je parle. Tu ne supportes pas ? Réglages › Voix. | Ab heute rede ich. Hältst du’s nicht aus: Einstellungen › Stimme. |
| Voce | Voice | Voz | Voix | Stimme |
| Piccante: sarcasmo. Senza pietà: parolacce e insulti. NEAT commenta i tuoi passi nell'app e nelle notifiche. Normale: NEAT sta zitto. | Spicy: sarcasm. No mercy: swearing and insults. NEAT comments on your steps in the app and in notifications. Normal: NEAT keeps quiet. | Picante: sarcasmo. Sin piedad: palabrotas e insultos. NEAT comenta tus pasos en la app y en las notificaciones. Normal: NEAT se calla. | Piquant : sarcasme. Sans pitié : gros mots et insultes. NEAT commente tes pas dans l’app et dans les notifications. Normal : NEAT se tait. | Bissig: Sarkasmus. Gnadenlos: Schimpfwörter und Beleidigungen. NEAT kommentiert deine Schritte in der App und in Mitteilungen. Normal: NEAT schweigt. |
| Notifiche di NEAT | NEAT notifications | Notificaciones de NEAT | Notifications de NEAT | Mitteilungen von NEAT |
| Poche · Normali · Tante | Few · Normal · Lots | Pocas · Normales · Muchas | Peu · Normal · Beaucoup | Wenige · Normal · Viele |
| NEAT. Tocca per un'altra battuta. (VoiceOver) | NEAT. Tap for another line. | NEAT. Toca para otra frase. | NEAT. Touche pour une autre réplique. | NEAT. Tippen für einen neuen Spruch. |

| Italiano | PT-BR | JA | KO | ZH-Hans | ZH-Hant |
|---|---|---|---|---|---|
| Vuoi che te lo dica gentilmente o che te lo dica davvero? | Quer que eu fale com jeitinho ou que eu fale a real? | やさしく言ってほしい？それとも本音で言ってほしい？ | 좋게 말해 줄까, 아니면 제대로 말해 줄까? | 想让我好好说，还是说实话？ | 想要我好好說，還是說真話？ |
| Parolacce e insulti compresi. Si cambia quando vuoi in Impostazioni › Voce. | Palavrões e xingamentos inclusos. Dá para mudar quando quiser em Ajustes › Voz. | 暴言・悪口あり。「設定」›「口調」でいつでも変更できます。 | 욕설과 독설 포함. 설정 › 말투에서 언제든 바꿀 수 있어요. | 含脏话和骂人的话。随时可在“设置”›“语气”中更改。 | 含髒話和罵人的話。隨時可在「設定」›「語氣」中更改。 |
| Da oggi parlo. Se non reggi: Impostazioni › Voce. | A partir de hoje, eu falo. Se não aguentar: Ajustes › Voz. | 今日からしゃべるぞ。耐えられないなら「設定」›「口調」へ。 | 오늘부터 말한다. 못 견디겠으면: 설정 › 말투. | 从今天起我开口了。受不了就去“设置”›“语气”。 | 從今天起我開口了。受不了就去「設定」›「語氣」。 |
| Voce | Voz | 口調 | 말투 | 语气 | 語氣 |
| Piccante: sarcasmo. Senza pietà: … Normale: NEAT sta zitto. | Picante: sarcasmo. Sem dó: palavrões e xingamentos. O NEAT comenta seus passos no app e nas notificações. Normal: o NEAT fica quieto. | ピリ辛：皮肉。容赦なし：暴言と悪口。NEATがアプリ内と通知であなたの歩数にコメントします。ふつう：NEATは黙っています。 | 매운맛: 비꼬기. 무자비: 욕설과 독설. NEAT가 앱과 알림에서 걸음 수에 한마디해요. 보통: NEAT는 조용히 있어요. | 辛辣：讽刺。毫不留情：脏话和骂人。NEAT 会在 App 和通知里点评你的步数。普通：NEAT 保持安静。 | 辛辣：諷刺。毫不留情：髒話和罵人。NEAT 會在 App 和通知裡點評你的步數。普通：NEAT 保持安靜。 |
| Notifiche di NEAT | Notificações do NEAT | NEATの通知 | NEAT 알림 | NEAT 通知 | NEAT 通知 |
| Poche · Normali · Tante | Poucas · Normais · Muitas | 少なめ · ふつう · 多め | 적게 · 보통 · 많이 | 少 · 正常 · 多 | 少 · 一般 · 多 |
| NEAT. Tocca per un'altra battuta. (VoiceOver) | NEAT. Toque para outra frase. | NEAT。タップすると別のセリフ。 | NEAT. 탭하면 다른 한마디. | NEAT。轻点换一句。 | NEAT。點一下換一句。 |

Dubbio: JA «ふつう» è sia il livello sia la frequenza media; in ZH la frequenza è 正常/一般 apposta per non ripetere 普通.

### 3. Privacy in inglese (T-026 §2), per `neat/privacy/index.html`
Termini come nella pagina inglese di oggi; il Jolly è «Joker» come nell'app (oggi la pagina dice «Jolly (streak
savers)»: da allineare).

**«In short», sentence to add at the end:**
> With the Spicy or No mercy voice (the default), NEAT downloads the updated list of lines from its website: it is the
> same file for everyone, and the app sends none of your data.

**New section «NEAT's lines», after «Where the data stays»:**
> With the Spicy or No mercy voice, NEAT picks its lines on the phone, based on your steps and your goal. Once a day
> it downloads the file with the updated list of lines from the NEAT website (hosted on GitHub Pages). It is a public
> file, the same for everyone: the app only reads it and sends no steps, goals or any other data. As with any web
> page, the service hosting the website (GitHub) receives the IP address the request comes from; the developer does
> not see it or keep it. With the Normal voice, the app downloads nothing.

**«Notifications», replacing the current text:**
> All NEAT notifications are local notifications: the evening reminder, the goal and Joker alerts and, if you kept
> the No mercy voice or chose Spicy, the lines. They are computed and scheduled on the phone, with no server
> involved. You can turn them off or reduce them in NEAT (Settings → Notifications and Settings → Voice) or in iOS
> Settings → Notifications → NEAT.

**«What NEAT does not do», first point, replacing the current one:**
> No developer servers: the app sends data to no one. The only exchanges are the copy in your own iCloud, made by
> iOS, and the download of the list of lines, which contains and sends none of your data.

**«Where the data stays», preferences:** add «chosen voice and notification frequency» to the list, and to the iCloud
copy list.

### 4. Store
- `NEAT_novita.xlsx`: riga `novita.1.3` in cima, 10 lingue (italiano di T-026 §3), ultimo punto = `novita.correzioni`;
  ricalcolate le formule dei caratteri delle righe sotto.
- `NEAT_store_tradotto.xlsx`: paragrafo nuovo prima di quello sulla privacy e testo promozionale nuovo, 10 lingue
  (italiano compreso, perché approvato). Nessuna parolaccia: solo «parolacce», «swearing», ecc. come descrizione.
- `store/metadata.json` rigenerato con `scripts/store_metadata.py`: tutti nei limiti (promo più lunga DE 121/170,
  descrizione più lunga DE 1009/4000).
- Dubbio, non mio da decidere: la descrizione dice ancora «NEAT legge soltanto» e «mai su server di altri»; resta vero
  (scarica un file, non invia), ma con la 1.3 l'app usa la rete. Parole chiave e screenshot non toccati.
- Il testo promozionale si può cambiare senza versione nuova: va mandato ad Apple solo con la 1.3.

### Non verificato
Nessun madrelingua; lunghezze nel selettore dell'SE da provare con T-027.
