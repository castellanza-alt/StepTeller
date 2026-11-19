# T-025 NASTY: controllo delle battute nelle 9 lingue
**Assegnato a:** Traduttore **Base:** `main` **Stato:** fatto 19/11/2026, PR da unire

## Perché
D-046: NASTY esce in tutte le lingue. Le battute sono state riscritte da ChatGPT (GPT-6.2 Astra) e stanno in
`docs/design/T-021-nasty/catalogo/lingue/` (un JSON per lingua, 196 righe, stessi id dell'italiano
`../catalogo-approvato.json`). Il controllo automatico è superato; nessuno le ha ancora lette. Regole in D-044 e D-045
e in testa a `docs/design/T-021-nasty/battute-nasty-corte.md`.

## Cosa fare (ramo `lang/T-025-nasty`, worktree `/Volumes/SSD/Developer/neat-lang`)
Per ogni lingua, tutte le 196 righe:
1. **Genere:** nessuna forma maschile o femminile riferita a chi legge. Riformula dove c'è.
2. **Divieti:** niente corpo, peso, aspetto, salute, malattie, disabilità, età, famiglia, sesso, religione,
   provenienza. Mai «zero passi». Si colpisce solo il fatto che cammina poco.
3. **Livelli:** id `P…` senza parolacce; id `N…` con parolacce e insulti naturali per un madrelingua, non tradotti
   alla lettera e non ammorbiditi. Segnala quelli che in quella cultura passano il segno (bestemmie, insulti a
   gruppi), e sostituiscili.
4. **Nomignolo** («soprammobile»): uno solo per lingua, sempre uguale; scrivilo nel glossario.
5. **Termini fissi** del glossario (`localizzazione/GLOSSARIO.md`): Jolly, serie, obiettivo, passi.
6. **Forma:** al massimo 12 parole (CJK: lunghezza equivalente, `ko` N132 da accorciare), ore scritte come si usa,
   notifiche «titolo / testo» con titolo entro 30 caratteri, segnaposti identici all'italiano.
7. Correggi direttamente i JSON; per ogni lingua scrivi nell'Esito quante righe hai cambiato e le 5 battute di cui
   sei meno sicuro. Aggiorna `lingue/LEGGIMI.md`. PR verso `main`, non unirla.

## Non fare
Non cambiare l'italiano né gli id. Non scrivere a William. Solo SSD; a fine turno niente acceso.

## Esito
Traduttore, 19/11/2026, ramo `lang/T-025-nasty`. Lette tutte le 196 righe nelle 9 lingue. In generale le
battute di ChatGPT sono buone e non ammorbidite: le parolacce del livello N ci sono e suonano naturali, il livello P è
pulito, il nomignolo è già uguale in ogni lingua, nessuna forma di genere riferita a chi legge.

Correzioni ricorrenti:
- **Fatti inventati** (regola 1): il robot aspirapolvere in N029 in tutte le lingue, il telecomando o il cuscino in
  N010 (ES, FR, DE, ZH-Hans), le pubblicità in TV (DE N083). Sostituiti con battute sul solo stare fermi.
- **ES «meta» → «objetivo»**, il termine dell'app (glossario): 24 righe, concordanze comprese.
- **ZH: contatore 枚** per 护身符/護身符 (era 个/個).
- **Aspetto**: PT N140 «Continua feio» (feio = brutto) sostituito.
- **Ammorbidite** rispetto all'italiano: N051 in ES, FR, DE («salvare la giornata» → «non fare schifo»).
- Frasi rotte o poco chiare (ES N015, N017, N024; PT N077, N105; JA N050; FR N111), 4 righe oltre le 12 parole, `ko`
  N132 accorciata come chiesto.

| Lingua | Righe cambiate | Le 5 battute di cui sono meno sicuro |
|---|---|---|
| EN | 3 | N012 «Thank fuck your couch has Wi-Fi» (troppo britannica?); N024 «I'd laugh, but you'd call that applause»; N065 «You've rehearsed enough»; N029 «Sitting on your ass, pure and simple»; N143 «Hands off me. Get your ass up.» |
| ES | 33 | N017 «Nada lo es, carajo» («carajo» è più latinoamericano); N032 «Entre uno y otro casi me desinstalo»; N066 «El sofá destapa la botella»; N085 «Felicidades, ya moviste algo»; P015 «¿Ya incluye la vuelta?» |
| FR | 8 | N061 «Tu perds encore à domicile»; N032 «compter les coussins»; N113 «j’ai failli signaler un bug»; N105 «faire suivre ton courrier»; P058 «Oui, je marche» (gioco di parole voluto) |
| DE | 4 | N020 «Für so langes Parken zahlt man normalerweise»; N061 «Schon wieder zu Hause verloren»; N056 «Geh dich draußen schämen»; N064 «Dafür hättest du mich nicht gebraucht»; N083 (riscritta da me) |
| PT-BR | 7 | N036 «te exibe no grupo da mobília»; N133 «Terceirizou essa porra também?»; N132 «Vai recorrer?»; P009 «Palmas. Uma hoje, outra amanhã»; N049 (riscritta da me) |
| JA | 4 | N014 «「サボった」って言ってやるのも甘いな»; N023 «毎度どうも»; N061 «ホームで負けてやんの»; N057 «グズ»; in generale poche parolacce vere (17 righe su 137): in giapponese la cattiveria sta nel registro rozzo |
| KO | 3 | N118 «싼 똥» (scatologica, forse troppo); N014 «운동 기구»; N010 «소파랑 한 세트냐»; N061 «안방에서 졌네»; N111 «뽀록» (gergo) |
| ZH-Hans | 5 | N012 «不然你怎么活？»; N036 «沙发出去吹牛»; N135 «送锦旗»; N105 «收货地址»; N116 «操蛋» |
| ZH-Hant | 6 | N001 «幹，有夠廢» (幹 forte per Taiwan?); N010 «顧攤»; N105 «戶籍遷來»; N020 «停車單»; N050 «秒針» |

Non verificato: la resa comica vera la può giudicare solo un madrelingua (non c'è nel team); lunghezze a schermo con
T-023. Nessuna bestemmia né insulto a gruppi trovato. Glossario aggiornato (sezione 5), `lingue/LEGGIMI.md` aggiornato.
