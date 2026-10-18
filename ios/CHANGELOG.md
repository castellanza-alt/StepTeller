# Changelog

## 0.6.0 — 18 ottobre 2026
- L'app si chiama **NEAT** (nome sotto l'icona, Salute e widget). Bundle ID, dati salvati e link `stepteller://`
  restano quelli di prima.
- Home sugli iPhone bassi (es. SE, 375 × 667): la tela si adatta all'altezza, strada e cursore restano visibili.
- Nuovo stile «Dan Dan Dan» (handoff Home + Storico): inchiostro, rosso come unico accento, font Anton, linee
  cinetiche, vignette storte. Tema **giorno** e **notte** con palette e illustrazioni proprie; in Impostazioni → Tema:
  Sistema (predefinito), Orario (giorno 7–19), Giorno, Notte.
- Home: illustrazione a tutto schermo, passi di oggi, minuti mancanti e cursore della velocità che scorre sulla strada
  disegnata (3–16 km/h a scatti di 0,5, tocco aptico a ogni scatto). I minuti restano quelli del modello di cadenza
  tarato. A obiettivo chiuso: «FATTO!» e niente cursore. Tocco sul numero per correggere i passi; «USA SALUTE» e
  avviso senza dati restano.
- Navigazione con il bottone rosso in alto a sinistra (Home ↔ Storico); niente più barra in basso.
- Storico: serie con fiamma, Jolly pronti, serie più lunga, prossimo Jolly (15 tacche), istogrammi a parallelogrammi
  (Settimana = somma, Mese/Anno/Sempre = media giornaliera; Anno e Sempre ora mostrano medie giornaliere, non totali),
  Passi · Km, record con la nuova scheda «Serie» (con le date).
- Medie giornaliere: contano i giorni conclusi (oggi escluso), dal primo giorno con dati.
- Tolti: tapis roulant illustrato e relativa opzione, calendario, dettagli Jolly maturati/usati.
- Festa dell'obiettivo ridisegnata nello stesso stile.
- Nuova icona Liquid Glass fatta con Icon Composer (`App/AppIcon.icon`): la suola rossa in primo piano su raggi manga,
  con varianti giorno, notte, colorata e trasparente.
- Widget nello stesso stile: piccolo e nuovo **medio** (passi, serie, Jolly, minuti e km che mancano alla velocità scelta
  in Home), tondo e rettangolare sul blocco schermo; giorno/notte secondo l'aspetto del telefono; un tocco apre la Home.

## 0.5.4 — 10 ottobre 2026
- Nuova icona dell'app (impronte e percorso tratteggiato, scelta da Will).
- Tappeto nascosto: la card non lascia più il vuoto a destra; passi mancanti e distanza diventano numeri a destra
  dei minuti.

## 0.5.3 — 9 ottobre 2026
- Storico e Streak senza riquadri: periodi e Passi/Km come testo, grafico libero, totale in evidenza con distanza,
  media e giorni a obiettivo affiancati, record e righe della streak separati da linee sottili.
- Barra del giorno in corso piena e tenue invece che contornata.

## 0.5.2 — 9 ottobre 2026
- Tapis roulant di nuovo a destra nella card; minuti e passi a sinistra.
- Impostazioni → Aspetto: «Mostra il tapis roulant» (acceso di default).
- Widget sul blocco schermo: tondo (arco con i passi), rettangolare (anello con l'omino e i passi) e in linea.

## 0.5.1 — 9 ottobre 2026
- Arco dei passi sempre di 270°: a obiettivo chiuso arriva a fondo scala e si ferma (niente anello), anche nel widget.
- Numero dei passi centrato nell'arco e ridotto quando serve: «10.729» non viene più troncato in «10.7…».
- Streak e Jolly senza pillole, solo icona e numero; la fiamma è colorata solo con streak > 0.
- La streak scatta appena Salute supera l'obiettivo, senza aspettare la rilettura dello storico.
- A obiettivo chiuso la card del tappeto sparisce (niente più «Fatto», anche nel widget): resta l'arco a fondo scala.
- Festa «Obiettivo raggiunto» alla prima apertura dopo aver chiuso l'obiettivo del giorno (una volta al giorno,
  solo con i passi di Salute): l'arco si riempie, spunta, scintille e vibrazione; si chiude da sola o con un tocco.

## 0.5.0 — 8 ottobre 2026
- Nuova struttura: **Oggi** (passi nell'arco, minuti sul tappeto con foto a sinistra, selettore di velocità) e **Storico**
  con selettore Storico | Streak e barra in basso con sfondo sfumato.
- Storico: settimana/mese/anno/sempre (passi o km), totali, media, giorni a obiettivo, calendario del mese,
  record personali (giorno, settimana, mese, anno). Dati da Salute, niente archivio proprio.
- Streak e Jolly: parte da 0 con 3 Jolly al primo avvio; 1 Jolly ogni 15 giorni riusciti; il Jolly si spende da solo
  e salva la streak senza farla crescere (il conto dei 15 giorni riparte da 0). Nessun Jolly se la streak è a 0.
- Obiettivo nelle Impostazioni (default 10.000), vale da oggi; lo storico degli obiettivi è conservato.
- Il promemoria serale avvisa se stasera si usa un Jolly o se la streak si interrompe.
- Il tappeto è ora l'illustrazione scelta da Will (senza sfondo né ombra), con il nastro animato riallineato.

## 0.4.0 — 8 ottobre 2026
- Widget piccolo «Passi di oggi» (tema scuro): arco di 270° con i passi, avanzamento e, nell'apertura, i minuti a piedi
  che mancano stimati a 4 km/h; stato «Fatto» a obiettivo chiuso. Legge Salute direttamente; a telefono bloccato usa
  l'ultimo valore salvato dall'app (App Group `group.it.castellanza.stepteller`, anche per obiettivo e taratura).

## 0.2.0 — 8 ottobre 2026
- Foto del Technogym di Will al posto del disegno, con il nastro animato sopra.
- Taratura automatica da Salute: allenamenti di camminata/corsa degli ultimi 90 giorni (≥ 10 min, scarto degli anomali,
  punti per fascia di velocità). Se non ci sono abbastanza allenamenti resta la taratura manuale in `Calibration`.
- Promemoria serale (default 20:30, modificabile dalla campanella): minuti reali se l'obiettivo non è chiuso,
  aggiornati da Salute anche in background (consegna oraria).
- Permessi Salute estesi: passi, distanza, allenamenti (sempre sola lettura).

## 0.1.0 — 8 ottobre 2026 (prima build, non ancora provata su iPhone)
- App SwiftUI con lo stesso modello della web app v4.0 e lo stesso aspetto (tappeto, orb, pannello in vetro, cursore).
- Passi di oggi da Apple Salute (sola lettura), aggiornamento in primo piano e al cambio di giorno.
- Correzione manuale dei passi con «Usa Salute»; obiettivo e velocità persistiti.
- Nucleo `StepTellerCore` con test golden; CI iOS e distribuzione TestFlight.
