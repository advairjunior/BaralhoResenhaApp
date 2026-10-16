import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
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
    Rodada(modo: ModoDeJogo.casaisEmJogo) => ('casais', ModoDeJogo.casaisEmJogo.titulo, [
        'Uma pessoa do casal escreve a resposta verdadeira sobre ela; o par tenta adivinhar.',
        'Depois da revelação, quem respondeu diz se o palpite acertou.',
        'Errou? O palpiteiro leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.tribunal) => ('tribunal', ModoDeJogo.tribunal.titulo, [
        'A pessoa da carta é o réu: ela só espera.',
        'O resto da turma vota em segredo: 👍 sim ou 👎 não.',
        'Maioria sim (ou empate) condena: o réu leva 1 ponto. Ninguém fica sabendo quem votou o quê.',
        'Na carta de elogio é ao contrário: maioria sim, o réu distribui goles; maioria não, o réu leva 1 ponto.',
      ]),
    Rodada(modo: ModoDeJogo.musica) => ('musica', ModoDeJogo.musica.titulo, [
        'A carta dá o tema. Quem está na foto começa e a roda segue na ordem que aparece embaixo.',
        'Cantou o seu trecho? Toque em "Cantei" e passa para o próximo. Não vale repetir música.',
        'Travou, esqueceu a letra ou repetiu? Quem criou a sala marca "Travou" e a pessoa leva 1 ponto.',
        'Quem criou a sala também passa a vez de quem está cantando sem o celular na mão.',
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

/// Pontos e goles, do jeito que a noite está configurada.
String explicacaoDosPontos(ConfiguracaoDoJogo configuracao) => switch (configuracao.pontosPorGole) {
      1 => 'Ritmo Raiz: cada ponto no cofrinho é 1 gole. Quem joga sem álcool só soma pontos.',
      final pontos => 'Cada vez que a carta te pega, você ganha 1 ponto no cofrinho. '
          'A cada $pontos pontos, o cofrinho enche e você bebe 1 gole. '
          'Quem joga sem álcool só soma pontos.',
    };

Future<void> abrirComoJoga(BuildContext context, VisaoDaSala visao, Rodada rodada) {
  final ajuda = comoJoga(rodada);
  return _folha(context, [
    Text('Como joga: ${ajuda.titulo}', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: EspacoBaralho.medio),
    for (final (indice, passo) in ajuda.passos.indexed) _Passo(numero: indice + 1, texto: passo),
    const SizedBox(height: EspacoBaralho.base),
    _Secao(titulo: '🍺 Pontos e goles', texto: explicacaoDosPontos(visao.configuracao)),
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
      const _Secao(
        titulo: '⏩ A carta passa sozinha',
        texto: 'Quando todo mundo responde e quem tem que beber (ou contar a história) confirma, '
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
    const _Passo(numero: 3, texto: 'Embaixo de toda carta tem "ⓘ Como joga" explicando aquele jogo.'),
    const _Passo(numero: 4, texto: 'No fim da noite saem os prêmios e o mural com as fotos de reação.'),
    const SizedBox(height: EspacoBaralho.base),
    _Secao(titulo: '🍺 Pontos e goles', texto: explicacaoDosPontos(visao.configuracao)),
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
      titulo: '👎 Tira essa',
      texto: 'Carta que ninguém quer jogar? Quem criou a sala tira, e ela sai do baralho da noite.',
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
