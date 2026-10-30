import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'visual.dart';

/// O jogo se explica sozinho: ninguém precisa ensinar ninguém na mesa.
class ComoJoga {
  const ComoJoga({required this.chave, required this.titulo, required this.passos});

  /// Identifica a dica de primeira vez (um jogo pode ter jeitos diferentes).
  final String chave;
  final String titulo;
  final List<String> passos;
}

ComoJoga comoJoga(Rodada rodada) {
  final dose = rodada.goles == null
      ? null
      : '🍺 Esta carta é dose de verdade: quem for pego bebe ${rodada.goles} goles, fora do cofrinho.';
  final (chave, titulo, passos) = switch (rodada) {
    Rodada(modo: ModoDeJogo.euNunca) => ('euNunca', ModoDeJogo.euNunca.titulo, [
        'Todo mundo responde em segredo no celular: "Já fiz" ou "Nunca fiz".',
        'Quando todos responderem, o app revela quem já fez.',
        'Quem já fez leva 1 ponto no cofrinho.',
        'Virada: se a maioria já fez, quem leva é quem nunca fez! E se todo mundo fez, ninguém leva.',
        'Se só uma pessoa fez, ela conta a história para a turma!',
        'Carta 🎤 CONTA ESSA: todo mundo que já fez conta a sua, um de cada vez. A foto de quem está na vez aparece e a pessoa toca em "Contei".',
      ]),
    Rodada(jokenpo: true) => ('jokenpo', 'Pedra, papel e tesoura', [
        'Só as duas pessoas da carta jogam: cada uma escolhe pedra, papel ou tesoura no celular, em segredo.',
        'Pedra ganha da tesoura, tesoura ganha do papel e papel ganha da pedra.',
        'Empatou? Joguem de novo, na mesma carta.',
        'Quem perder leva o ponto (ou a dose da carta). Quem ganhar ganha uma carta na manga.',
        'O resto da turma só torce.',
      ]),
    Rodada(duelo: true) => ('duelo', 'Duelo', [
        'As duas pessoas da carta se apresentam: dançam, imitam, contam, o que a carta pedir.',
        'O resto da turma vota em segredo em quem mandou melhor. Quem está no duelo não vota.',
        'Quem perder leva 1 ponto. Quem ganhar ganha uma carta na manga.',
      ]),
    Rodada(modo: ModoDeJogo.maisProvavel, elogio: true) => ('elogio', 'Elogio da turma', [
        'Vote em segredo em quem merece o elogio da carta. Vale votar em você.',
        'Quem a turma escolher não bebe: distribui goles e ganha uma carta na manga.',
      ]),
    Rodada(modo: ModoDeJogo.maisProvavel, votacao: true) => ('votacao', 'Votação', [
        'Vote em segredo em quem tem mais a cara da carta. Vale votar em você.',
        'Quando todos votarem, o app mostra quem levou mais votos.',
        'Quem levar mais votos leva 1 ponto (empate: todos os mais votados).',
      ]),
    Rodada(modo: ModoDeJogo.maisProvavel) => ('apontar', 'Aponta no 3', [
        'Quem criou a sala toca em "Contar até 3" e a contagem aparece em todos os celulares ao mesmo tempo.',
        'No "APONTEM!", todo mundo aponta junto para quem tem mais a cara da carta.',
        'Quem criou a sala marca no app quem foi mais apontado: essa pessoa leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.bebaSe) => ('bebaSe', ModoDeJogo.bebaSe.titulo, [
        'Alguém lê a carta em voz alta.',
        'Se a carta te pegou, toque em "Me pegou!" no seu celular; se não, em "Não". Vale a honestidade!',
        'Cada "Me pegou" é 1 ponto no cofrinho.',
      ]),
    Rodada(modo: ModoDeJogo.regraRelampago) => ('regra', ModoDeJogo.regraRelampago.titulo, [
        'A regra vale nesta carta e nas próximas. Sem isca, por 3 cartas.',
        'Com entrevista, pergunta, missão ou piada: vem uma carta comum e depois a ⚡ vez da regra com a pergunta, 3 vezes. Siga o que ela pedir: é isso que faz a regra acontecer.',
        'Quebrou a regra? Quem criou a sala marca em "🚨 Alguém vacilou?" e a pessoa leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.tribunal) => ('tribunal', ModoDeJogo.tribunal.titulo, [
        'A pessoa da carta é o réu: ela só espera.',
        'O resto da turma vota em segredo: 👍 sim ou 👎 não.',
        'Maioria sim (ou empate) condena: o réu leva 1 ponto. Ninguém fica sabendo quem votou o quê.',
        'Na carta de elogio é ao contrário: maioria sim, o réu distribui goles; maioria não, o réu leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.musica) => ('musica', ModoDeJogo.musica.titulo, [
        'A carta dá o tema. Quem está na foto começa; embaixo aparece quem vem depois.',
        'Na sua vez, o celular vibra e mostra "É a sua vez de cantar!". Cantou? Toque em "Cantei · próximo!". Não vale repetir música.',
        'Travou, esqueceu a letra ou repetiu? Qualquer um da turma toca em "Travou" e a pessoa leva 1 ponto.',
        'Aparece de vez em quando, como surpresa: não tira o lugar das outras brincadeiras.',
      ]),
    Rodada(modo: ModoDeJogo.impostor) => ('impostor', ModoDeJogo.impostor.titulo, [
        'Todo mundo recebeu a mesma palavra no celular, menos um: o impostor, que só sabe o tema.',
        'Na ordem da tela, cada um fala uma pista em voz alta. Uma palavra só, sem entregar demais!',
        'O impostor finge que sabe: ouve as pistas e inventa a dele.',
        'Depois, todo mundo vota em segredo em quem acha que é o impostor.',
        'Pegaram (ele sozinho no topo)? O impostor leva 1 ponto. Empatou ou erraram? Ele escapa, ganha uma carta na manga, e quem votou errado leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.jurados) => ('jurados', ModoDeJogo.jurados.titulo, [
        'O app elegeu a pessoa da carta: ela só espera a nota.',
        'O resto da turma é jurado: cada um dá de 1 a 5 estrelas, em segredo.',
        'Média 4 ou mais: aprovado(a)! A pessoa distribui goles e ganha uma carta na manga.',
        'Média 2 ou menos: reprovado(a), leva 1 ponto. No meio, fica por isso mesmo.',
        'As notas aparecem sem dizer quem deu qual.',
      ]),
    Rodada(modo: ModoDeJogo.elogios) => ('elogios', ModoDeJogo.elogios.titulo, [
        'Façam o que a carta pede para a pessoa da vez.',
        'Ninguém bebe nesta carta: todo mundo sai se achando.',
        'Quando acabar, quem criou a sala passa para a próxima.',
      ]),
    Rodada(modo: ModoDeJogo.correio) => ('correio', ModoDeJogo.correio.titulo, [
        'A pessoa da foto fica de fora e não vê a pergunta.',
        'O resto escreve um bilhete curto (até 20 letras) respondendo a carta, em segredo.',
        'Anônimo de verdade: ninguém sabe quem escreveu o quê, nem quem criou a sala.',
        'No fim, todo mundo lê junto, e a pessoa da foto escolhe o bilhete favorito.',
      ]),
    Rodada(modo: ModoDeJogo.termineAFrase) => ('termineAFrase', ModoDeJogo.termineAFrase.titulo, [
        'A carta dá o começo. Cada um completa no celular, em segredo, com até 40 letras.',
        'Quando todo mundo escreve, as frases aparecem embaralhadas e sem autor.',
        'Vote na melhor. Não vale votar na sua.',
        'Só a mais votada revela quem escreveu: essa pessoa distribui goles e ganha uma carta na manga. '
            'As outras continuam anônimas.',
      ]),
    Rodada(modo: ModoDeJogo.duasVerdades) => ('duasVerdades', ModoDeJogo.duasVerdades.titulo, [
        'A pessoa da vez escreve no celular três frases sobre o tema da carta: duas verdades e uma mentira.',
        'Ela marca qual é a mentira. Só ela sabe; a turma vê as três frases.',
        'O resto vota em segredo em qual é a mentira. Vale perguntar e encarar antes de votar!',
        'Quem errou leva 1 ponto. Se ninguém acertou, a pessoa da vez distribui goles.',
        'Depois, a pessoa da vez conta a história das verdades (e de onde tirou a mentira) e toca em "🎤 Contei".',
      ]),
    Rodada(modo: ModoDeJogo.chutaAi) => ('chutaAi', ModoDeJogo.chutaAi.titulo, [
        'A carta faz uma pergunta com resposta em número. Cada um chuta no celular, em segredo.',
        'Vale vírgula: 42,5. Dá para trocar o chute até todo mundo chutar.',
        'Na revelação aparecem a resposta certa e todos os chutes, do mais perto ao mais longe.',
        'Quem chutou mais longe leva 1 ponto. Quem chegou mais perto distribui goles. '
            'Acertou na mosca? Ganha uma carta na manga.',
      ]),
    Rodada(modo: ModoDeJogo.batataQuente) => ('batataQuente', ModoDeJogo.batataQuente.titulo, [
        'A carta dá a categoria ("marcas de cerveja"). A batata começa com quem a carta chamou.',
        'Com a batata, fale uma coisa da categoria em voz alta e toque em "Falei!": ela passa para o próximo.',
        'Repetiu ou travou? A turma não deixa passar: só toca em "Falei!" quem falou uma que vale.',
        'Ninguém sabe quando estoura, nem quem criou a sala. Estourou na sua mão? Leva 1 ponto.',
        'Ninguém joga o celular: a batata é só na tela.',
      ]),
    Rodada(modo: ModoDeJogo.issoOuAquilo) => ('issoOuAquilo', ModoDeJogo.issoOuAquilo.titulo, [
        'A carta dá duas opções. Cada um escolhe a sua no celular, em segredo.',
        'Dá para trocar até todo mundo escolher.',
        'Na revelação aparece quem escolheu cada lado. Quem ficou na minoria leva 1 ponto.',
        'Empate ou todo mundo do mesmo lado: ninguém leva.',
      ]),
    Rodada(modo: ModoDeJogo.quemSouEu) => ('quemSouEu', ModoDeJogo.quemSouEu.titulo, [
        'Todo mundo vê no celular quem a pessoa da vez é, menos ela. Pode ser qualquer coisa: '
            'objeto, bicho, comida, famoso, personagem, lugar…',
        'A pessoa da vez só sabe a categoria. Ela pergunta em voz alta e a turma só responde sim ou não.',
        'Quem criou a sala dá o "Valendo!": são 90 segundos.',
        'Acertou? Ganha uma carta na manga. O tempo acabou? Leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.palavraProibida) => ('palavraProibida', ModoDeJogo.palavraProibida.titulo, [
        'Só quem explica vê a palavra e as quatro palavras proibidas.',
        'Explique falando, sem dizer a palavra, as proibidas, pedaços delas nem fazer mímica.',
        if (rodada.times.length > 1)
          'Os times jogam ao mesmo tempo, com a mesma palavra: ganha quem acertar primeiro. O time que perder leva 1 ponto.'
        else
          'A turma toda tenta adivinhar. Ninguém acertou no tempo? Quem explicou leva 1 ponto.',
        'Quem criou a sala dá o "Valendo!" no cronômetro de 60 segundos e marca quem acertou.',
      ]),
    Rodada(modo: ModoDeJogo.imagemEAcao) => ('mimica', ModoDeJogo.imagemEAcao.titulo, [
        'Só quem faz a mímica vê a palavra. Dá para dizer a dica: a categoria e o número de palavras.',
        'Não vale falar, soletrar nem apontar para objetos.',
        if (rodada.times.length > 1)
          'Os times jogam ao mesmo tempo, com a mesma palavra: ganha quem acertar primeiro. O time que perder leva 1 ponto.'
        else
          'A turma toda tenta adivinhar. Ninguém acertou no tempo? Quem fez a mímica leva 1 ponto.',
        'Quem criou a sala dá o "Valendo!" no cronômetro de 60 segundos e marca quem acertou.',
      ]),
  };
  return ComoJoga(chave: chave, titulo: titulo, passos: [...passos, ?dose]);
}

/// Pontos e goles (ou prendas), do jeito que a noite está configurada.
String explicacaoDosPontos(ConfiguracaoDoJogo configuracao) => switch (configuracao) {
      ConfiguracaoDoJogo(semAlcool: true, pontosPorGole: 1) =>
        '🧃 Sala sem álcool: ninguém bebe. Cada vez que a carta te pega, você paga uma prenda, '
            'que aparece na tela. Pagou? Toque em "Paguei". '
            'No fim, quem fechou com mais pontos paga o 🤡 Mico da noite, escolhido pela turma.',
      ConfiguracaoDoJogo(semAlcool: true, :final pontosPorGole) =>
        '🧃 Sala sem álcool: ninguém bebe. Cada vez que a carta te pega, você ganha 1 ponto no cofrinho. '
            'A cada $pontosPorGole pontos, o cofrinho enche e você paga uma prenda, que aparece na tela. '
            'Pagou? Toque em "Paguei". No fim, quem fechou com mais pontos paga o 🤡 Mico da noite, '
            'escolhido pela turma.',
      ConfiguracaoDoJogo(pontosPorGole: 1) =>
        'Ritmo Raiz: cada ponto no cofrinho é 1 gole. Quem joga sem álcool só soma pontos.',
      ConfiguracaoDoJogo(:final pontosPorGole) => 'Cada vez que a carta te pega, você ganha 1 ponto no cofrinho. '
          'A cada $pontosPorGole pontos, o cofrinho enche e você bebe 1 gole. '
          'Quem joga sem álcool só soma pontos.',
    };

String _tituloDosPontos(VisaoDaSala visao) =>
    visao.configuracao.semAlcool ? '🎟️ Pontos e prendas' : '🍺 Pontos e goles';

Future<void> abrirComoJoga(BuildContext context, VisaoDaSala visao, Rodada rodada) {
  final ajuda = comoJoga(rodada);
  return _folha(context, [
    Text('Como joga: ${ajuda.titulo}', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: EspacoBaralho.medio),
    for (final (indice, passo) in ajuda.passos.indexed) _Passo(numero: indice + 1, texto: paraASala(visao, passo)),
    const SizedBox(height: EspacoBaralho.base),
    _Secao(titulo: _tituloDosPontos(visao), texto: explicacaoDosPontos(visao.configuracao)),
    if (visao.configuracao.cartasNaManga)
      const _Secao(
        titulo: '🃏 Cartas na manga',
        texto: 'Toque numa carta da sua mão para ver o que ela faz e quando dá para usar.',
      ),
    _Secao(
      titulo: '👑 Quem passa as cartas',
      texto: 'Só ${visao.anfitriao?.nome ?? 'quem criou a sala'} puxa a próxima carta, pula e revela antes da hora.',
    ),
    if (visao.configuracao.passarSozinho)
      _Secao(
        titulo: '⏩ A carta passa sozinha',
        texto: 'Quando todo mundo responde e quem tem que '
            '${visao.configuracao.semAlcool ? 'pagar a prenda' : 'beber'} (ou contar a história) confirma, '
            'a próxima carta vem em 3 segundos. Precisa de mais tempo? Toque em "⏸️ Segura aí".',
      ),
  ]);
}

/// O resumo do jogo inteiro, para quem nunca jogou.
Future<void> abrirComoFunciona(BuildContext context, VisaoDaSala visao) {
  return _folha(context, [
    Text('Como funciona o Baralho da Resenha', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: EspacoBaralho.medio),
    const _Passo(numero: 1, texto: 'Cada um joga no próprio celular. Todo mundo vê a mesma carta ao mesmo tempo.'),
    _Passo(
      numero: 2,
      texto: 'Só ${visao.anfitriao?.nome ?? 'quem criou a sala'} passa as cartas. '
          'O resto responde, vota ou marca "Me pegou!" quando a carta pedir.',
    ),
    const _Secao(
      titulo: '👑 O comando',
      texto: 'Quem passa as cartas pode passar o comando para outra pessoa pelo menu. '
          'Se o celular dela apagar ou ficar sem bateria, o comando passa sozinho para o próximo da mesa.',
    ),
    const _Passo(numero: 3, texto: 'Embaixo de toda carta tem "ⓘ Como joga" explicando aquele jogo.'),
    const _Passo(numero: 4, texto: 'No fim da noite saem os prêmios e o mural com as fotos de reação.'),
    const SizedBox(height: EspacoBaralho.base),
    _Secao(titulo: _tituloDosPontos(visao), texto: explicacaoDosPontos(visao.configuracao)),
    if (!visao.configuracao.semAlcool)
      const _Secao(
        titulo: '🍺 Dose de verdade',
        texto: 'Carta com o selo "DOSE DE VERDADE" manda beber de verdade, fora do cofrinho.',
      ),
    if (visao.configuracao.cartasNaManga)
      const _Secao(
        titulo: '🃏 Cartas na manga',
        texto: 'Cada um começa com uma carta especial, estilo Uno, e ganha mais vencendo. '
            'Toque nelas para ver o que fazem.',
      ),
    const _Secao(
      titulo: '😂 Reações',
      texto: 'Embaixo de toda carta dá para reagir com um toque. Ninguém vê quem reagiu, '
          'e a carta que mais rendeu vira a Carta da noite nos prêmios.',
    ),
    const _Secao(
      titulo: '🔊 Som, voz e vibração',
      texto: 'A revelação, o vacilo e o fim do tempo tocam no celular. O celular de quem está no comando '
          'lê cada carta em voz alta, com um personagem diferente a cada vez. '
          'Quer silêncio? Desligue no menu ⋮.',
    ),
    const _Secao(
      titulo: '👎 Tira essa',
      texto: 'Carta que ninguém quer jogar? Quem criou a sala tira, e ela sai do baralho da noite.',
    ),
    const _Secao(
      titulo: '📵 Caiu da sala?',
      texto: 'Abra o link e entre de novo com o mesmo nome: você volta com seus pontos e cartas. '
          'A mesa não espera por quem caiu, e quem foi embora de vez sai pelo placar, '
          'pela mão de quem está no comando.',
    ),
  ]);
}

Future<void> _folha(BuildContext context, List<Widget> filhos) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, rolagem) => ListView(
          controller: rolagem,
          padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
          children: [
            ...filhos,
            const SizedBox(height: EspacoBaralho.base),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi 👍')),
          ],
        ),
      ),
    );

class _Passo extends StatelessWidget {
  const _Passo({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: CoresBaralho.ambarEscuro,
            child: Text('$numero', style: const TextStyle(fontSize: 12, color: CoresBaralho.ambar)),
          ),
          const SizedBox(width: EspacoBaralho.medio),
          Expanded(child: Text(texto, style: const TextStyle(height: 1.4))),
        ]),
      );
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: EspacoBaralho.medio),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(texto, style: const TextStyle(color: CoresBaralho.textoSecundario, height: 1.4)),
        ]),
      );
}

/// Na primeira vez que um jogo aparece neste celular, uma faixa curta convida
/// a ver como joga. Some na próxima carta do mesmo jogo.
class DicaDePrimeiraVez extends StatefulWidget {
  const DicaDePrimeiraVez({super.key, required this.visao, required this.rodada});

  final VisaoDaSala visao;
  final Rodada rodada;

  @override
  State<DicaDePrimeiraVez> createState() => _DicaDePrimeiraVezState();
}

class _DicaDePrimeiraVezState extends State<DicaDePrimeiraVez> {
  static const _chave = 'dicas_vistas';
  bool _mostrar = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final preferencias = await SharedPreferences.getInstance();
    final vistas = preferencias.getStringList(_chave) ?? const [];
    final chave = comoJoga(widget.rodada).chave;
    if (vistas.contains(chave)) return;
    await preferencias.setStringList(_chave, [...vistas, chave]);
    if (mounted) setState(() => _mostrar = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_mostrar) return const SizedBox.shrink();
    final ajuda = comoJoga(widget.rodada);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
      child: Material(
        color: CoresBaralho.ambarEscuro,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const Key('dica-primeira-vez'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => abrirComoJoga(context, widget.visao, widget.rodada),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio, vertical: EspacoBaralho.pequeno),
            child: Text(
              '💡 Primeira vez de ${ajuda.titulo}? Toque e veja como joga',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
