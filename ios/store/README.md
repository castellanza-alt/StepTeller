# Scheda App Store (via API)

La scheda di NEAT su App Store Connect si compila da qui, con l'API ufficiale, da GitHub Actions
(`.github/workflows/ios-store.yml` → `scripts/asc.py store-*`, codice in `scripts/asc_store.py`).
L'app si cerca per Bundle ID (`it.castellanza.stepteller`), non per nome.

## Comandi (nella prima riga del messaggio di un commit spinto su `main` o `ia/versione-0.6.2`)

Solo la prima riga conta: un tag citato nel corpo del messaggio non avvia niente.

| Tag | Cosa fa |
|---|---|
| `[store-prova]` | Legge App Store Connect e scrive nel riepilogo dell'esecuzione cosa cambierebbe, lingua per lingua. Non scrive niente. |
| `[store]` | Applica le differenze e poi rilegge tutto: «Nessuna differenza» = fatto. Rilanciarlo non duplica niente (gli screenshot uguali non si ricaricano). |
| `[store-invio]` | Collega l'ultima build 1.0 valida (o quella in `BUILD_NUMBER`) e invia in revisione. **Solo dopo l'ok di Will.** Si rifiuta se la scheda non corrisponde al repository. |

Commit senza modifiche, solo per lanciare: `git commit --allow-empty -m "ios: scheda store [store-prova]"`.

## Cosa imposta

- Lingua principale **en-US** (la vedono anche Regno Unito, Australia e Canada inglese); 12 lingue: en-US, it, es-ES,
  fr-FR, de-DE, pt-BR, ja, ko, zh-Hans, zh-Hant, più copie identiche (testi e screenshot) per es-MX (spagnolo) e
  fr-CA (francese).
- Per lingua: nome, sottotitolo, URL privacy (App Information); descrizione, parole chiave, testo promozionale,
  URL di supporto (versione 1.0, creata se manca); 6 screenshot in ordine 01…06 (sostituiscono quelli esistenti).
- Categorie Salute e fitness / Stile di vita; età: tutte le risposte «no» → 4+ (con «sì» a salute e benessere Apple mostra 9+ da iOS 26: scelta di Will, 4+)
  (scelta di Will), tutto il resto «no/nessuno»; il riepilogo mostra la classificazione calcolata da Apple; dichiarazione «nessun
  contenuto di terzi»; prezzo gratuito; disponibile in tutti i paesi, anche i nuovi.
- Note per il revisore (`note_revisore.txt`, in inglese) e contatto, copyright: dai segreti.
- Se Apple rifiuta un nome (già usato), lo script si ferma e lo riporta.

## File

| File | Contenuto |
|---|---|
| `metadata.json` | Testi per lingua, **generato** dal foglio `localizzazione/NEAT_store_tradotto.xlsx` (foglio «Store») con `python3 scripts/store_metadata.py` (serve `pip install openpyxl`). Non si modifica a mano. |
| `screenshots/<lingua>/01…06.jpg` | JPEG qualità 85 da PNG 1320 × 2868 (iPhone 6,9", tipo API `APP_IPHONE_67`), con `python3 scripts/store_screenshots.py CARTELLA` (serve `pip install pillow`); `CARTELLA` contiene le sottocartelle it, en, es, fr, de, pt-BR, ja, ko, zh-Hans, zh-Hant (oppure `it=cartella` per una lingua sola). |
| `note_revisore.txt` | Note per il revisore Apple. |
| `GUIDA_MANUALE.md` | I passi che l'API non permette (privacy, trader UE, accordi). |

**Parole chiave**: Apple le documenta come «fino a 100 byte». In giapponese, coreano e cinese un carattere vale 3 byte:
le righe del foglio superavano il limite, quindi `scripts/store_metadata.py` usa versioni accorciate
(`KEYWORD_OVERRIDES`, parole intere tolte). Lo script e `asc.py` si fermano se un campo supera i limiti
(nome e sottotitolo 30, promozionale 170, descrizione 4000 caratteri, parole chiave 100 byte).

## Segreti GitHub

Già presenti: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`. Per la scheda: `ASC_REVIEW_FIRST_NAME`,
`ASC_REVIEW_LAST_NAME`, `ASC_REVIEW_PHONE` (formato internazionale, es. `+39 …`), `ASC_REVIEW_EMAIL`, `ASC_COPYRIGHT`
(es. `2026 Nome Cognome`). Se mancano, lo script lascia quei campi com'erano e lo segnala. Il repository è pubblico:
questi valori non vanno mai nei file né nei log (lo script li mostra solo come «(impostato)»).
