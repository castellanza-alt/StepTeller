# T-019 Icona di Natale più chiara e illustrazione fino in cima
**Assegnato a:** Designer (1), Developer (2) **Base:** `main` aggiornato **Stato:** assegnato 18/11/2026 — urgente,
ultime correzioni prima dell'invio della 1.2

## Perché
William ha provato la build 1.147.2 sul telefono (`comms/feedback.md` 18/11): «si va», ma «l'icona non è bella, troppo
confusa» e «la app non arriva fino a coprire tutto lo schermo» (striscia bianca in alto, tra la barra di stato e il
cielo grigio dell'illustrazione; nella Home normale non si vede perché il fondo è carta bianca).

## 1. Designer — icona nuova (ramo `design/T-019-icona`, worktree `/Volumes/SSD/Developer/neat-design`)
- Il difetto non è tecnico: a 60 pt la suola scolpita più pelliccia più pantalone più linee cinetiche sono troppi
  dettagli. Serve **un'idea sola, leggibile a colpo d'occhio sulla schermata Home**, sempre con lo stivale (D-040),
  coerente con l'icona normale (stessa famiglia), niente religione.
- Prepara **3 proposte** diverse e mettile su una tela di Claude Design (come T-015) accanto all'icona normale, a
  grandezza vera su una schermata Home di iOS chiara e scura, più la variante tinta. Mandami il link: William sceglie.
- Higgsfield ammesso nel tetto rimasto (22,5 crediti, D-040), meglio se in locale. Livelli finali in SVG come T-018.
- Dopo la scelta di William: PR con la sola cartella `.icon` in `docs/design/T-015-natale/`, non unirla.

## 2. Developer — illustrazione fino in cima (ramo `task/T-019-bordo`, worktree `/Volumes/SSD/Developer/neat-dev`)
- A Natale l'illustrazione (giorno e notte) deve coprire tutto lo schermo, anche dietro la barra di stato e in basso,
  su ogni iPhone (SE, mini, Pro Max, con e senza Dynamic Island), senza spostare strada e cursore. Verifica anche le
  bande ai lati dell'SE di T-018. Fuori stagione nessun cambiamento.
- Screenshot prima/dopo nella PR; riga nel CHANGELOG (la 1.2 è «su TestFlight»: il Director riapre la sezione se serve
  — chiedimelo prima di toccare l'intestazione); verifica come al solito; PR, non unirla.

## Disco
Solo SSD, file pesanti in `/Volumes/SSD/Temp/NEAT/`, niente acceso a fine turno.

## Non fare
Non unire, nessuna build, nessun tag, nessuna chiave. Non scrivere a William (salvo la tela, tramite me).

## Esito

### 2. Developer (18/11/2026, ramo `task/T-019-bordo`)
- Causa: la tela della Home ha fondo `paper` e l'illustrazione parte da `artTop` = 54 pt (handoff), quindi a Natale
  sopra il cielo restava una striscia di carta (bianca di giorno, blu notte di notte); sugli iPhone più alti del 390 × 844
  anche qualche punto in basso, sull'SE pure gli angoli delle bande laterali.
- Correzione (`App/Home/HomeView.swift`, `edgeFill`): solo in stagione il fondo della tela è trasparente e dietro c'è la
  stessa scena, ferma e sfumata, allargata alla larghezza dello schermo e ripetuta a specchio sopra e sotto, così cielo e
  strada continuano senza giunture fino ai bordi; il bordo alto dell'illustrazione vera sfuma in 20 pt. Strada, cursore
  e testi non si spostano. Sostituisce il riempimento laterale di T-018 (stessa scena, stessa geometria).
- Verifica: Simulatore Debug su SE (tasto Home), 17e (notch) e 17 Pro Max (Dynamic Island), giorno e notte, prima e
  dopo in `tasks/T-019/natale-*.jpg`. Fuori stagione: screenshot identici pixel per pixel su SE giorno/notte e Pro Max
  giorno; sul Pro Max di notte differenze di pochi pixel vicino al pulsante delle impostazioni, invisibili a occhio
  (`tasks/T-019/fuori-stagione.jpg`), che sembrano rumore del vetro o dell'effetto parallasse. Il mini non c'è tra i simulatori di iOS 27: a 375 × 812 la
  striscia era di 1 pt in basso più quella in alto, coperte allo stesso modo. 117 test verdi, build Debug e Release OK.
- Revisione indipendente: nessun errore di geometria; un rischio: lo sfocato a tutto schermo ora c'è su ogni iPhone in
  stagione (prima solo sull'SE) e potrebbe essere ricalcolato a ogni fotogramma della parallasse della gamba. Con
  `.drawingGroup()` la scena diventava nera e fuori posto (come in T-018), quindi non usato. Da misurare sul telefono
  (fluidità e batteria); se servisse, si limita lo sfocato alle sole strisce visibili.
