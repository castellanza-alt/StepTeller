# T-029 Collaudo della 1.3 (la voce di NEAT: Piccante e Senza pietà)
**Assegnato a:** QA **Base:** `main` dopo il merge della #56 **Stato:** assegnato 19/11/2026

## Perché
La 1.3 porta la voce di NEAT (D-044…D-047, progetto `docs/design/T-022-nasty-progetto.md`, grafica
`docs/design/T-023-nasty-grafica.md`, testi `docs/design/T-026-nasty-testi.md`, lavoro del Developer
`tasks/T-027-nasty-app.md`). William ha approvato cuori, animazioni (riferimento:
https://claude.ai/artifact/2TVrWv75kUHJfDLsu76SyH) e testi. Dopo il collaudo: build TestFlight per la sua prova.
Il collaudo guarda anche **com'è**, non solo se funziona.

## Cosa fare (ramo `qa/T-029`, worktree `/Volumes/SSD/Developer/neat-qa`)
1. **Di serie:** installazione nuova → Senza pietà, cuore e fumetto in Home. Aggiornamento dalla 1.2 (installa la
   1.2 da un commit precedente o simula i dati senza il campo) → Senza pietà e la prima battuta «Da oggi parlo…»,
   una volta sola. Chi ha già scelto un livello lo tiene. iCloud e Backup vecchi e nuovi.
2. **Cuore:** i due aspetti, giorno e notte; battito, «quando parla», tocchi a rotazione e rabbia crescente, a
   confronto con la pagina di riferimento; «Riduci movimento»; VoiceOver; fluidità. Con Normale non c'è niente e
   l'app è identica alla 1.2.
3. **Battute:** giuste per la situazione (pochi passi, ore, metà, quasi, raggiunto, record, doppio, obiettivo
   alzato/abbassato, Jolly usato/guadagnato/finiti, serie persa, giorno uno); numeri veri; **mai** una battuta con
   «{passi}» sotto i 50 passi; nessuna ripetizione ravvicinata; nessun segnaposto a vista; ore coerenti con l'ora.
   Piccante: nessuna parolaccia.
4. **Notifiche roast** con `-stepteller.debugNow` e passi finti: solo tra le 10 e le 20, almeno 90 minuti tra due,
   numero secondo livello e manopola, ferme a obiettivo raggiunto, riprogrammate ai passi nuovi; promemoria serale e
   avvisi di obiettivo e Jolly con la voce; con Normale tornano i testi della 1.2.
5. **Catalogo dal sito:** scaricamento, file rotto o assente (resta il precedente), modalità aereo, con Normale
   nessuna richiesta di rete. Controlla con un proxy o dai log che la richiesta non porti dati.
6. **Lingue:** tutte e 10, su SE e 17 Pro Max: selettore a tre segmenti, fumetto, pop-up, festa, introduzione,
   Impostazioni; nessun testo fuori dai riquadri, nessun testo rimasto in italiano; caratteri asiatici resi bene.
7. **Non regressioni** di 1.2 e 1.1: Natale (data a dicembre: cuore e slitta convivono?), Jolly regalo, pop-up,
   Backup, introduzione, widget.
8. Rapporto `comms/qa/T-029.md`: esito, difetti (bloccanti o no) con screenshot, cosa William deve provare sul
   telefono. PR col solo rapporto, non unirla.

## Disco
Solo SSD: file pesanti in `/Volumes/SSD/Temp/NEAT/`, cancellati a fine compito; a fine turno niente acceso.

## Non fare
Non correggere il codice, non unire, nessuna build TestFlight. Non scrivere a William.

## Esito
**19/11/2026, QA.** Collaudo sul Simulatore (17 Pro, SE, 17 Pro Max). Rapporto `comms/qa/T-029.md` con 14 screenshot,
ramo `qa/T-029`. **Nessun difetto bloccante.**
- **Funziona**:
  - Senza pietà di serie, anche dopo l'aggiornamento dalla 1.2, con la prima battuta;
  - cuore e animazioni come la pagina approvata;
  - battute giuste, niente numero dei passi sotto i 50;
  - Piccante senza parolacce;
  - promemoria con la voce;
  - catalogo scaricato, e con Normale niente rete;
  - 10 lingue;
  - Natale insieme alla voce;
  - 151 test.
- **Notifiche roast**: le regole (10–20, 90 minuti, quantità) le ho provate sul nucleo, non dal vivo.
- **Medio, strumento**: `debugNow` non sposta l'ora della voce.
- **Minori**:
  - ripetizioni nei pop-up e nel promemoria;
  - doppio e record senza precedenza;
  - la battuta del tocco resta nel fumetto.
- Provato da William: no.
