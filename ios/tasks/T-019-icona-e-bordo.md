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
