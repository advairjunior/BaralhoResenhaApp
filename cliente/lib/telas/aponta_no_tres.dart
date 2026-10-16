import 'dart:async';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'visual.dart';

/// Quem é mais provável sem votação no celular: quem lê a carta toca e a
/// tela conta "3… 2… 1… APONTEM!" em voz alta para a turma.
class ContagemParaApontar extends StatefulWidget {
  const ContagemParaApontar({super.key, this.passo = const Duration(milliseconds: 800)});

  /// Tempo de cada número da contagem.
  final Duration passo;

  @override
  State<ContagemParaApontar> createState() => _ContagemParaApontarState();
}

class _ContagemParaApontarState extends State<ContagemParaApontar> {
  // 3, 2, 1, depois 0 = "APONTEM!"; nulo = esperando o toque.
  int? _numero;
  Timer? _relogio;

  void _contar() {
    _relogio?.cancel();
    setState(() => _numero = 3);
    _relogio = Timer.periodic(widget.passo, (relogio) {
      if (!mounted) return relogio.cancel();
      setState(() => _numero = _numero! - 1);
      if (_numero == 0) relogio.cancel();
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numero = _numero;
    if (numero == null) {
      return SizedBox(
        height: 72,
        child: FilledButton(
          key: const Key('contar-ate-tres'),
          onPressed: _contar,
          child: const Text('👉 Contar até 3', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    return GestureDetector(
      onTap: _contar,
      child: SizedBox(
        height: 96,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (filho, animacao) => ScaleTransition(scale: animacao, child: filho),
            child: Text(
              numero > 0 ? '$numero' : 'APONTEM! 👉',
              key: ValueKey(numero),
              style: TextStyle(
                fontSize: numero > 0 ? 64 : 40,
                fontWeight: FontWeight.w700,
                color: numero > 0 ? CoresBaralho.texto : CoresBaralho.ambar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Depois do "APONTEM!": a foto e o nome de todo mundo. Quem criou a sala
/// toca em quem a turma apontou (empate, toca em mais de um).
class QuemFoiApontado extends StatelessWidget {
  const QuemFoiApontado({super.key, required this.visao, required this.rodada, required this.aoMarcar});

  final VisaoDaSala visao;
  final Rodada rodada;
  final ValueChanged<String> aoMarcar;

  @override
  Widget build(BuildContext context) {
    final marcar = visao.souAnfitriao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          marcar
              ? 'Toque em quem a turma apontou:'
              : '${visao.anfitriao?.nome ?? 'Quem criou a sala'} marca quem a turma apontou',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.medio),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.medio,
          runSpacing: EspacoBaralho.medio,
          children: [
            for (final jogador in visao.jogadores)
              _Apontavel(
                visao: visao,
                jogador: jogador,
                apontado: rodada.beberam.contains(jogador.id),
                aoTocar: marcar ? () => aoMarcar(jogador.id) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Apontavel extends StatelessWidget {
  const _Apontavel({required this.visao, required this.jogador, required this.apontado, required this.aoTocar});

  final VisaoDaSala visao;
  final Jogador jogador;
  final bool apontado;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('apontar-${jogador.id}'),
      onTap: aoTocar,
      child: SizedBox(
        width: 80,
        child: Column(children: [
          AvatarDoJogador(jogador: jogador, tamanho: 60, destaque: apontado ? CoresBaralho.ambar : null),
          const SizedBox(height: EspacoBaralho.mini),
          Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (apontado)
            Text(destinoDoPego(visao, jogador),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CoresBaralho.ambar)),
        ]),
      ),
    );
  }
}
