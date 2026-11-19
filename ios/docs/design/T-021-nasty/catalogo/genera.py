# Genera catalogo.json, catalogo.md e pagina.html dal catalogo scritto qui sotto.
import json, html
N = {  # livello 3, NASTY
"Pochi passi": """{passi} passi. Fai schifo.
{passi} passi. Che vergogna.
Solo {passi} passi. Alzati, cazzo.
{passi} passi. Muovi il culo.
{passi} passi su {obiettivo}. Ridicolo.
{passi} passi. Complimenti al divano.
{passi} passi. Sei un soprammobile con il telefono.
{passi} passi. Pochi. Troppo pochi. Come sempre.
{passi} passi. Non ci siamo. Non ci siamo mai.
{passi} passi. Non ti muovi da ore. Fai pena.
{passi} passi. Avevi detto {obiettivo}. Stronzate.
{passi} passi. Questa è sedentarietà con il wifi.
{passi} passi. Vivi sul divano. Si vede dai numeri.
{passi} passi. Chiamarla sedentarietà è un complimento.
{passi} passi. Mi vergogno io per te.
Sei al {percento}% dell'obiettivo. Il resto è divano.
{passi} passi. Camminare non è il tuo forte. Niente lo è.
Mancano {mancano} passi. Smetti di leggere e cammina.
Fai schifo. Scusa, volevo dire: {passi} passi. È lo stesso.
{passi} passi. Non è una giornata: è una sosta.
{passi} passi. Imbarazzante.
{passi} passi. Davvero? Davvero.
{passi} passi. Il divano ringrazia.
{passi} passi. Fai ridere. Non in senso buono.
{passi} passi. Una miseria.
{passi} passi. Ti serve un'app per fare così poco?
{passi} passi. Mi fai perdere tempo.
{passi} passi. E la chiami giornata.
{passi} passi. Sedentarietà allo stato puro.
{passi} passi. Muoviti, soprammobile.
{passi} passi. Non valgono un cazzo.
{passi} passi. Mi annoio perfino a contarli.
{passi} passi. Il tuo obiettivo ride di te.
{passi} passi. Bel lavoro di merda.
{passi} passi. Esci di casa, cazzo.
{passi} passi. Sei l'orgoglio del divano.
{passi} passi su {obiettivo}. Nemmeno ci provi.
{passi} passi. Poltrire è l'unica cosa che fai bene.
{passi} passi. Che pena.
{percento}% dell'obiettivo. Voto: fai schifo.
{passi} passi. Datti una mossa o disinstallami.
{passi} passi. Vergogna pura.
{passi} passi. Ti manca tutto: {mancano} passi.
{passi} passi. Una nullità con le scarpe.""",
"Mattina e pomeriggio": """Mezzogiorno, {passi} passi. Mattinata sprecata.
Sono le 11. {passi} passi. Cominciamo male.
{passi} passi a metà giornata. Sveglia, soprammobile.
Mattina finita. {passi} passi. Il divano è già in vantaggio.
Sono le 16. {passi} passi. Ti stai arrendendo.
Pomeriggio. {passi} passi. Il tempo passa, tu no.
Ore 17. {passi} passi. Ultima occasione per non fare schifo.
Ore 15. {passi} passi. Metà giornata buttata.""",
"Sera": """Sono le 19. {passi} passi. Giornata buttata.
{passi} passi a sera. Bella merda.
Ore 20. {passi} passi. Il divano ha vinto ancora.
È sera. {passi} passi. Vergognati e cammina.
Mancano {mancano} passi. {minuti} minuti. Alza il culo adesso.
{minuti} minuti e ci arrivi. Oppure resti una nullità. Scegli.
Ore 19. Mancano {mancano} passi. Sbrigati, nullità.
{passi} passi e la giornata è finita. Uno schifo.
Sera. {passi} passi. Anche oggi hai perso.
{minuti} minuti. Solo {minuti}. E non li fai, vero?
Ultima ora. {mancano} passi. Fuori, cazzo.
Giornata chiusa a {passi} passi. Fai pena.
{passi} passi oggi. Dormi pure: è quello che fai meglio.
Fine giornata: {passi} passi. Il divano festeggia.""",
"A metà e quasi": """Metà obiettivo. Metà di niente è niente. Cammina.
Mancano {mancano} passi. Se molli ora sei una testa di cazzo.
{mancano} passi. Pochi. Falli, per una volta.
Metà. E adesso molli, come sempre?
Sei a metà. Non fermarti, testa di cazzo.
{percento}%. L'altra metà non si fa da sola.
Mancano {mancano} passi. Evita la solita figura di merda.
Quasi. "Quasi" non vale un cazzo.
{mancano} passi. Li fa chiunque. Dimostralo.
Ti mancano {minuti} minuti. Muoviti.
{mancano} passi al traguardo. Se molli, fai schifo il doppio.""",
"Obiettivo scelto o cambiato": """Obiettivo: {obiettivo} passi. Che ambizione di merda.
{obiettivo} passi? Li fa chiunque. Tu, forse.
Hai abbassato l'obiettivo. Vigliaccata.
Obiettivo abbassato. Così non cammini: ti arrendi.
{obiettivo} passi. Obiettivo da divano.
{obiettivo} passi al giorno. Ti piace vincere facile.
Obiettivo {obiettivo}. Ridicolo, come i tuoi passi.
Abbassato a {obiettivo}. Complimenti per la resa.
Obiettivo abbassato. Hai mollato senza nemmeno camminare.
Obiettivo abbassato. Più tempo per il divano. Che tristezza.
Hai abbassato l'obiettivo. Di nuovo. Fai pena.
Obiettivo alzato a {obiettivo}. Vediamo quanto dura.
{obiettivo} passi. Tanto non li fai.
Obiettivo alzato. Parole. Ora i passi.""",
"Jolly e serie": """Ieri pochi passi. Ti ha salvato un Jolly. Non te lo meriti.
Jolly finiti. Ora cammini o perdi tutto.
Serie persa. {serie} giorni buttati. Colpa tua.
Serie a zero. Complimenti al divano. Ricomincia.
Jolly usato. Ieri hai fatto schifo.
Un Jolly in meno. Ne restano {jolly}. Poi è finita.
Ti ha salvato un Jolly. Tu non salvi niente.
Jolly guadagnato. Lo sprecherai presto.
{serie} giorni di fila. Non rovinarla come al solito.
Serie finita. Bastava camminare.
Serie persa a {serie} giorni. Che spreco.
{serie} giorni buttati. Per il divano.
Serie persa. Il divano ha vinto. Ancora.
Giorno uno. Di nuovo. Fai pena.
Stasera rischi la serie. Mancano {mancano} passi. Muoviti.
Ultimo Jolly bruciato. Adesso cammini davvero.""",
"Quando ce la fai": """Obiettivo raggiunto. Era ora, cazzo.
{obiettivo} passi fatti. Per una volta non fai schifo.
Obiettivo raggiunto. Non ci credevo. Nemmeno tu.
Fatto. Domani uguale, o torni una merda.
Record. Vedi che non sei solo un soprammobile?
Obiettivo raggiunto. Miracolo.
Fatto. Non abituarti ai complimenti.
{obiettivo} passi. Finalmente, cazzo.
Obiettivo raggiunto. Oggi il divano piange.
Ce l'hai fatta. Domani scommetto di no.
Fatto. Un giorno non cancella gli altri.
Obiettivo raggiunto. Era il minimo.
Record. Allora gli altri giorni era pigrizia.
Nuovo record. Quindi prima facevi schifo apposta.
{passi} passi. Ok, oggi sto zitto.
Doppio dell'obiettivo. Chi sei?
{passi} passi. Per oggi non fai schifo.""",
"Notifiche": """Alzati / {passi} passi. Non bastano. Non bastano mai.
Ehi, soprammobile / {passi} passi su {obiettivo}. Muoviti.
Fai schifo / {passi} passi. Mancano {mancano}. Fuori, adesso.
Ancora sul divano? / {passi} passi. Indovinato.
Sedentarietà / Oggi ne sei il simbolo: {passi} passi.
Brutte notizie / {passi} passi. La brutta notizia sei tu.
Sveglia / {passi} passi. Il divano non è un lavoro.
Vergogna / {passi} passi su {obiettivo}. Altro da aggiungere?
Muoviti / Mancano {mancano} passi. Non si fanno da soli.
Promemoria / Fai ancora schifo. {passi} passi.
Notizia / {passi} passi. Il divano ringrazia.
Che pena / {percento}% dell'obiettivo. Alzati.
Sono le 18 / {passi} passi. Ultima occasione, soprammobile.
Alza il culo / {passi} passi non sono una giornata.
Ancora lì? / {passi} passi. Come un'ora fa.
Niente di nuovo / {passi} passi. Fai ancora schifo.""",
"Se tocchi il cuore": """Non toccarmi. Cammina.
Toccare non conta. Camminare sì.
Giù le mani. Su il culo.
Mi apri e non cammini. Fai pena.
Guardarmi non aumenta i passi.""",
}
P = {  # livello 2, Piccante: niente parolacce
"Pochi passi": """{passi} passi. Notevole. Per un soprammobile.
{passi} passi. Il divano ti saluta.
{passi} passi. Si può fare di meno? Non credo.
{passi} passi. Che fatica, immagino.
{passi} passi su {obiettivo}. Ottimista, l'obiettivo.
{passi} passi. Non ti stanchi mai di stare lì?
{passi} passi. Prendila con calma, eh.
{passi} passi. Il divano è fiero di te.
{passi} passi. Applausi. Lenti.
{passi} passi. Una giornata intensa, vedo.
{passi} passi. Mi aspettavo poco. Hai fatto meno.
Sei al {percento}%. Il resto lo fa il divano?
{passi} passi. Bella giornata da soprammobile.
{passi} passi. Non esagerare, mi raccomando.
{passi} passi. Davvero tutto qui?
Mancano {mancano} passi. Così, per dire.
{passi} passi. Le scarpe si annoiano.
{passi} passi. Coraggio: la porta si apre.""",
"Mattina, pomeriggio, sera": """Mezzogiorno, {passi} passi. Partenza lenta. Lentissima.
Ore 16. {passi} passi. Con calma, eh.
Sono le 19. {passi} passi. Il divano vince ancora.
Sera. Mancano {mancano} passi. Che si fa?
{minuti} minuti e ci arrivi. O no?
{passi} passi a fine giornata. Complimenti alla costanza.
Ore 20. {passi} passi. Ci riproviamo domani, immagino.""",
"A metà e quasi": """Metà. Qui di solito ti fermi. Sorprendimi.
Sei a metà. Il divano chiama: non rispondere.
Mancano {mancano} passi. Mollare ora sarebbe da te.
Quasi. "Quasi" non conta.
{mancano} passi. Dai, perfino tu.""",
"Obiettivo scelto o cambiato": """{obiettivo} passi. Ambizioso, per un soprammobile.
{obiettivo} passi. Ti vuoi bene, vedo.
Obiettivo abbassato. Che sorpresa.
Abbassato a {obiettivo}. Il divano approva.
Obiettivo alzato. Vediamo quanto dura.
{obiettivo} passi. Certo. Ci credo.""",
"Jolly e serie": """Jolly usato. Ieri ti ho coperto io.
Ne restano {jolly}. Non contarci troppo.
Jolly guadagnato. Dura poco, con te.
{serie} giorni di fila. Non rovinare tutto.
Serie persa. Bastava una passeggiata.
{serie} giorni, poi il divano. Classico.
Giorno uno. Vi conoscete già.""",
"Quando ce la fai": """Obiettivo raggiunto. Segno la data.
Fatto. Sono quasi colpito.
Obiettivo raggiunto. Allora sai camminare.
Ce l'hai fatta. Non montarti la testa.
Record. Quindi quando vuoi, puoi.
Record. Il divano ci è rimasto male.
{passi} passi. Oggi non ho niente da dire.""",
"Notifiche": """Ehi / {passi} passi. Il divano non scappa.
Promemoria / Mancano {mancano} passi. Così, per sapere.
Tutto bene? / {passi} passi. Dal divano, immagino.
Sono le 18 / {passi} passi. C'è ancora tempo. Poco.
Novità / Nessuna: {passi} passi.
Coraggio / {minuti} minuti a piedi. Ce la fai perfino tu.""",
"Se tocchi il cuore": """Toccarmi non conta come passo.
Sì, funziono. Tu?
Guardarmi non fa salire i passi.""",
}
cat=[]
for lev,pref,d in (("NASTY","N",N),("Piccante","P",P)):
    i=0
    for sit,txt in d.items():
        for l in txt.split("\n"):
            l=l.strip()
            if not l: continue
            i+=1
            cat.append({"id":f"{pref}{i:03d}","livello":lev,"situazione":sit,"testo":l})
ids=[c["id"] for c in cat]; assert len(ids)==len(set(ids))
dup=[t for t in set(c["livello"]+c["testo"] for c in cat) if sum(1 for c in cat if c["livello"]+c["testo"]==t)>1]
assert not dup, dup
long=[c for c in cat if len(c["testo"].replace("/"," ").split())>14]
json.dump(cat,open("catalogo.json","w"),ensure_ascii=False,indent=1)
md=["# NEAT NASTY — catalogo delle battute","","Generato da `genera.py`. Livello 3 (NASTY) e livello 2 (Piccante). William scarta le battute dalla pagina",
"pubblicata; gli scarti stanno nel database della pagina.",""]
cur=None
for c in cat:
    k=(c["livello"],c["situazione"])
    if k!=cur: md+=["",f"## {c['livello']} — {c['situazione']}"]; cur=k
    md.append(f"- `{c['id']}` «{c['testo']}»")
open("catalogo.md","w").write("\n".join(md)+"\n")
print(len(cat), sum(c["livello"]=="NASTY" for c in cat), sum(c["livello"]=="Piccante" for c in cat), "lunghe:", [c["id"] for c in long])
