# NEAT — glossario delle traduzioni

Lo tiene il **Traduttore** (dal 18/11/2026, T-014). Raccoglie come i termini fissi di NEAT sono **già** tradotti
nelle 10 lingue, presi dai fogli e dai cataloghi (non inventati): foglio «Glossario» e foglio «Testi» di
`NEAT_testi_tradotti.xlsx` (da cui `scripts/cataloghi.py` genera i cataloghi `*.xcstrings`), `NEAT_store_tradotto.xlsx`,
`NEAT_novita.xlsx`. Le regole di prima (prompt per ChatGPT in questa cartella) restano valide.

Regola di fondo (D-005): si traduce solo italiano approvato da William. Le bozze portano nella colonna «Note del
traduttore» la scritta `BOZZA T-0xx` finché l'italiano non è approvato.

## 1. Termini fissi

| Italiano | EN | ES | FR | DE | PT-BR | JA | KO | ZH-Hans | ZH-Hant |
|---|---|---|---|---|---|---|---|---|---|
| NEAT | NEAT | NEAT | NEAT | NEAT | o NEAT | NEAT | NEAT | NEAT | NEAT |
| Jolly | Joker (pl. Jokers) | Comodín (pl. Comodines) | Joker (pl. Jokers) | Joker (pl. Joker) | Coringa (pl. Coringas) | おまもり (contatore 個) | 지킴이 (contatore 개) | 护身符 (contatore 枚) | 護身符 (contatore 枚) |
| serie / streak | streak | racha | série | Serie | sequência | 連続記録 | 연속 기록 | 连续记录 | 連續紀錄 |
| di fila | in a row | seguido(s) | d’affilée | in Folge | seguido(s) | {n}日連続 | {n}일 연속 | 连续{n}天 | 連續{n}天 |
| obiettivo | goal | objetivo | objectif | Ziel | meta | 目標 | 목표 | 目标 | 目標 |
| chiudere / raggiungere l'obiettivo | reach your goal | alcanzar tu objetivo | atteindre ton objectif | dein Ziel erreichen | atingir sua meta | 目標を達成する | 목표를 달성하다 | 达成目标 | 達成目標 |
| passi | steps | pasos | pas | Schritte (abbr. SCHR.) | passos | 歩 / 歩数 | 걸음 / 걸음 수 | 步 / 步数 | 步 / 步數 |
| promemoria (serale) | (evening) reminder | recordatorio (nocturno) | rappel (du soir) | (Abend)erinnerung | lembrete (noturno) | (夜の)リマインダー | (저녁) 알림 | (晚间)提醒 | (晚間)提醒 |
| Notifiche (sezione, 1.2) | Notifications | Notificaciones | Notifications | Mitteilungen | Notificações | 通知 | 알림 | 通知 | 通知 |
| Salute (app Apple) | Health | Salud | Santé | Health | Saúde (no Saúde) | ヘルスケア | 건강 (건강 앱) | 健康 («健康») | 健康 (「健康」) |
| Backup | Backup | Copia de seguridad | Sauvegarde | Backup | Backup | バックアップ | 백업 | 备份 | 備份 |
| iCloud | iCloud | iCloud | iCloud | iCloud | iCloud (o iCloud) | iCloud | iCloud | iCloud | iCloud |
| account Apple | Apple Account | cuenta de Apple | compte Apple | Apple Account | Conta Apple | Apple Account | Apple 계정 | Apple 账户 | Apple 帳號 |
| tappeto | treadmill | cinta de correr | tapis de course | Laufband | esteira | トレッドミル | 러닝머신 | 跑步机 | 跑步機 |
| Storico | History | Historial | Historique | Verlauf | Histórico | 履歴 | 기록 | 历史记录 | 歷史紀錄 |
| Impostazioni | Settings | Ajustes | Réglages | Einstellungen | Ajustes | 設定 | 설정 | 设置 | 設定 |
| FATTO! | DONE! | ¡LISTO! | FAIT ! | FERTIG! | FEITO! | やった！ | 해냈다! | 搞定！ | 搞定！ |

Unità: km, km/h, MI, mph restano uguali in tutte le lingue; «K» per le migliaia anche in JA/KO/ZH. Numeri, date, mesi:
li formatta iOS. Cinese tradizionale = variante di Taiwan.

## 2. Tono per lingua

| Lingua | Forma | Note |
|---|---|---|
| EN | «you», diretto, frasi corte | |
| ES | «tú» (tus, alcanzas) | spagnolo neutro, «¡…!» davanti |
| FR | «tu» (ton, tes) | spazio prima di `! ? : ;`, apostrofo tipografico `’` |
| DE | «du» (dein, deine) | |
| PT-BR | «você» (sua, seu) | brasiliano: meta, esteira, celular |
| JA | misto: です・ます nelle Impostazioni e in VoiceOver, colloquiale (〜よ, 〜だよ) nell'introduzione e nelle notifiche | vedi incoerenza 3.4 |
| KO | 해요체 (〜요) | VoiceOver di Home e festa in 합니다체: vedi 3.5 |
| ZH-Hans / ZH-Hant | «你» | punteggiatura a tutta larghezza (：，。！) |

MAIUSCOLO dove l'italiano è maiuscolo (titoli manga); JA/KO/ZH ignorano il maiuscolo. Il «Limite» è in caratteri,
segnaposto sostituiti da numeri tipici (2 cifre, passi a 5).

## 3. Incoerenze trovate (non corrette, da decidere)

1. **`set.reminder.section`** (corretta in T-014): l'italiano è diventato «Notifiche» in T-011, ma **tutte** le 9 lingue
   dicevano ancora «Evening reminder», «Recordatorio nocturno»…
2. **EN, apostrofo**: quasi ovunque `'` (isn't, today's), ma `’` in `set.backup.note` («streak’s»). Va scelto uno.
3. **ES, obiettivo**: nell'app e nel glossario «objetivo», nella descrizione dello store «meta» («llegar a tu meta»,
   «alcanzas tu meta»).
4. **JA, tono**: Impostazioni e VoiceOver in です・ます, introduzione e notifiche (`n.*`) colloquiali con よ / だよ.
   I testi 1.2 seguono le notifiche (colloquiale) per le notifiche e i pop-up, です・ます per la nota delle Impostazioni.
5. **KO, registro**: `home.steps.vo` e `party.vo` in 합니다체, il resto in 해요체.
6. **KO, «알림»**: lo stesso termine per «promemoria» (`intro.4.kicker`, prima la sezione «저녁 알림») e ora per la sezione «Notifiche».
   Si capisce, ma il glossario del foglio dà 알림 = promemoria.
7. **EN/ES/FR/PT, Jolly disponibili**: `top.jolly.vo` «Jokers available», `st.jolly.vo` «Jokers ready» (ES disponibles /
   listos ecc.). Due parole per la stessa cosa in VoiceOver.
8. **Account Apple, maiuscole**: ES «cuenta de Apple» e FR «compte Apple» in minuscolo, mentre Apple scrive il nome con
   la maiuscola («Cuenta de Apple», «Compte Apple»); da verificare sulle pagine Apple prima di cambiarlo.
9. **ZH, spazi attorno alle parole latine**: «Apple 账户», «NEAT 备份», «使用 iCloud» con lo spazio; «无需打开App», «iCloud中»,
   «打开NEAT» senza. Nei testi della 1.2 si usa lo spazio («App 内», «iOS 会»); i testi più vecchi sono da uniformare.
10. **ES, `top.jolly`**: «COMODINES» ha 9 caratteri contro un limite di 8 (già annotato nel foglio, da guardare a
    schermo).
11. **Italiano (non mio da cambiare)**: «serie» e «streak» convivono nell'italiano; nelle traduzioni c'è un solo
    termine per lingua, come chiede il glossario.

## 4. Testi della 1.2 (T-014)

Italiano approvato da William il 19/11/2026. Righe tradotte nelle 9 lingue (nota «T-014 (Traduttore, 19/11)»):
`set.reminder.section`, `set.notify.toggle`, `set.notify.note`, `set.season.toggle`, `set.season.note`, 17 righe
`jolly.*` e 4 `jolly.gift.*` (pop-up), 9 righe `notif.*` (notifiche): 35 righe.
Scelte che valgono anche dopo:
- Pop-up: William ha visto parole uscire dal riquadro. Le targhette (`jolly.count`, `jolly.left`, una riga) e le frasi
  (2 righe) restano vicine alla lunghezza dell'italiano: dove EN/ES/FR/DE/PT erano molto più lunghe sono state
  accorciate (es. EN «YOU HAVE {n} JOKERS», DE «JETZT {n} JOKER», FR «ENCORE {n} JOKERS»).
- Dove l'app passa i numeri come testo e non come plurale (`{serie}`, `{n}` in `notif.jollyEarned.body`,
  `notif.jollyUsed.body`, `jolly.*.vo`), le lingue con il plurale usano la forma «Jokers left: {n}», «Jokers
  available: {n}», che regge anche con 1.
- Le righe `.one` / `.other` in JA/KO/ZH: iOS usa solo `.other`, quindi la frase di `.other` deve stare bene anche con 1.
- Controllo automatico (19/11): nessuna riga ha l'italiano fuori dalla colonna italiana, salvo parole uguali nelle due
  lingue già prima della 1.2 (Tema, Sistema, Backup, Serie, Privacy, Media).
