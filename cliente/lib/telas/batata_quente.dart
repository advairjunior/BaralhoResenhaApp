import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';
import 'visual.dart';

/// Quem vem depois de quem está com a batata, pulando quem caiu (como o servidor).
String? proximoDaBatata(VisaoDaSala visao, Rodada rodada) {
  final fila = rodada.fila;
  final posicao = fila.indexOf(rodada.comABatata ?? '');
  for (var passo = 1; passo < fila.length; passo++) {
    final jogador = visao.jogador(fila[(posicao + passo) % fila.length]);
    if (jogador != null && jogador.conectado) return jogador.id;
  }
  return null;
}

/// A batata na mão de alguém: quem está com ela fala e toca em "Falei!";
/// a turma vê com quem está e quem vem depois. O pavio ninguém vê.
class PainelDaBatata extends StatelessWidget {
  const PainelDaBatata({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final comigo = rodada.comABatata == visao.euId;
    final comQuem = visao.jogador(rodada.comABatata ?? '');
    final depois = proximoDaBatata(visao, rodada);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A batata pula a cada passe, para todo mundo ver que andou.
        TweenAnimationBuilder<double>(
          key: ValueKey('batata-${rodada.comABatata}'),
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, escala, filho) => Transform.scale(scale: escala, child: filho),
          child: comigo || comQuem == null
              ? const Text('🥔', textAlign: TextAlign.center, style: TextStyle(fontSize: 88))
              : Center(child: AvatarDoJogador(jogador: comQuem, tamanho: 96, destaque: CoresBaralho.batata)),
        ),
        const SizedBox(height: EspacoBaralho.medio),
        Text(
          comigo ? 'A batata está com você! Fale uma e passe.' : 'A batata está com ${comQuem?.nome ?? '…'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (!comigo && depois != null)
          Text(
            depois == visao.euId ? 'Depois: você! Pensa rápido 😅' : 'Depois: ${visao.jogador(depois)?.nome}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoSecundario),
          ),
        const SizedBox(height: EspacoBaralho.base),
        if (comigo) _BotaoFalei(key: ValueKey('falei-${rodada.numero}'), acoes: acoes),
        const SizedBox(height: EspacoBaralho.medio),
        const Text(
          '⏳ Ninguém sabe quando estoura. Repetiu ou travou? A turma não deixa passar!',
          textAlign: TextAlign.center,
          style: TextStyle(color: CoresBaralho.textoApagado, fontSize: 13),
        ),
        if (visao.souAnfitriao) ...[
          const SizedBox(height: EspacoBaralho.medio),
          TextButton(onPressed: acoes.proxima, child: const Text('Pular carta')),
        ],
      ],
    );
  }
}

/// Um toque só: o segundo chegaria com a batata já na mão de outra pessoa.
class _BotaoFalei extends StatefulWidget {
  const _BotaoFalei({super.key, required this.acoes});

  final AcoesDaSala acoes;

  @override
  State<_BotaoFalei> createState() => _BotaoFaleiState();
}

class _BotaoFaleiState extends State<_BotaoFalei> {
  var _passando = false;

  Future<void> _passar() async {
    setState(() => _passando = true);
    try {
      await widget.acoes.passarABatata();
    } finally {
      if (mounted) setState(() => _passando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: FilledButton(
        key: const Key('passar-batata'),
        style: FilledButton.styleFrom(backgroundColor: CoresBaralho.batata, foregroundColor: Colors.white),
        onPressed: _passando ? null : _passar,
        child: const Text('🗣️ Falei! Passa a batata', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Estourou: todo mundo vê na mão de quem.
class RevelacaoDaBatata extends StatelessWidget {
  const RevelacaoDaBatata({super.key, required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final queimou = revelacao.perderam.isEmpty ? null : visao.jogador(revelacao.perderam.first);
    return Column(
      key: const Key('batata-estourou'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('💥', textAlign: TextAlign.center, style: TextStyle(fontSize: 72)),
        if (queimou != null) ...[
          Center(child: AvatarDoJogador(jogador: queimou, tamanho: 96, destaque: CoresBaralho.batata)),
          const SizedBox(height: EspacoBaralho.medio),
          Text('💥 Estourou na mão de ${queimou.nome}!',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text('${queimou.nome} leva 1 ponto.',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
        ] else
          Text('💥 Estourou! Quem estava com a batata saiu da sala.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
