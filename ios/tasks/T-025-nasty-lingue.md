# T-025 NASTY: controllo delle battute nelle 9 lingue
**Assegnato a:** Traduttore **Base:** `main` **Stato:** assegnato 19/11/2026

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
