import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../infraestrutura/som.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'visual.dart';

/// Quem é mais provável sem votação no celular: quem criou a sala toca em
/// "Contar até 3" e todos os celulares contam juntos "3… 2… 1… APONTEM!",
/// para a turma apontar ao mesmo tempo.
class ContagemParaApontar extends StatefulWidget {
  const ContagemParaApontar({super.key, required this.visao, required this.rodada, required this.aoContar});

  final VisaoDaSala visao;
  final Rodada rodada;
  final VoidCallback aoContar;

  @override
  State<ContagemParaApontar> createState() => _ContagemParaApontarState();
}

class _ContagemParaApontarState extends State<ContagemParaApontar> {
  DateTime? _fim;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _sincronizar();
  }

  @override
  void didUpdateWidget(ContagemParaApontar antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.rodada.cronometroRestanteMs != widget.rodada.cronometroRestanteMs) _sincronizar();
  }

  /// O servidor diz quanto falta; aqui vira um horário de fim neste celular.
  void _sincronizar() {
    _relogio?.cancel();
    final restante = widget.rodada.cronometroRestanteMs;
    _fim = restante == null ? null : clock.now().add(Duration(milliseconds: restante));
    if (restante == null || restante <= 0) return;
    _relogio = Timer.periodic(const Duration(milliseconds: 100), (relogio) {
      if (!mounted) return relogio.cancel();
      setState(() {});
      if (_numero == 0) {
        relogio.cancel();
        tocar(Som.tempo);
      }
    });
  }

  /// 3, 2, 1 e depois 0 = "APONTEM!"; nulo antes de contar.
  int? get _numero {
    final fim = _fim;
    if (fim == null) return null;
    final ms = fim.difference(clock.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numero = _numero;
    final souAnfitriao = widget.visao.souAnfitriao;
    if (numero == null) {
      if (!souAnfitriao) {
        return Text(
          '${widget.visao.anfitriao?.nome ?? 'Quem criou a sala'} puxa a contagem. Todo mundo aponta junto no APONTEM!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        );
      }
      return SizedBox(
        height: 72,
        child: FilledButton(
          key: const Key('contar-ate-tres'),
          onPressed: widget.aoContar,
          child: const Text('👉 Contar até 3', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    return GestureDetector(
      onTap: souAnfitriao ? widget.aoContar : null,
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
