import 'dart:async';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'visual.dart';

/// Votações cujo suspense já passou neste aparelho: a atualização da sala
/// não repete o tambor.
final _jaMostrados = <String>{};

/// Votação com teatro: tambor, "e o mais votado é…" e a
/// foto gigante. Toque pula.
class SuspenseDaVotacao extends StatefulWidget {
  const SuspenseDaVotacao({
    super.key,
    required this.chave,
    required this.maisVotados,
    this.chamada = 'E o mais votado é…',
    this.resultado,
    this.tempoDoTambor = const Duration(milliseconds: 1800),
    this.tempoDoResultado = const Duration(milliseconds: 2800),
  });

  /// As falas certas para cada jogo: votação, elogio ou veredito do tribunal.
  factory SuspenseDaVotacao.da({
    Key? key,
    required VisaoDaSala visao,
    required Rodada rodada,
    required Revelacao revelacao,
  }) {
    final chave = '${visao.codigo}-${rodada.numero}';
    if (rodada.modo == ModoDeJogo.tribunal) {
      final reu = visao.jogador(rodada.alvo ?? '');
      final condenado = reu != null && revelacao.perderam.contains(reu.id);
      final elogiado = reu != null && revelacao.escolhidos.contains(reu.id);
      return SuspenseDaVotacao(
        key: key,
        chave: chave,
        maisVotados: [?reu],
        chamada: 'O veredito da turma é…',
        resultado: switch ((revelacao.elogio, condenado)) {
          (false, true) => 'CULPADO(A)! ${destinoDoPego(visao, reu!)}',
          (false, false) => 'ABSOLVIDO(A)! 😇',
          (true, true) => 'A TURMA DISSE NÃO! ${destinoDoPego(visao, reu!)}',
          (true, false) when elogiado => '💛 SIM! E ${distribuiGoles(visao, 2).substring(3)}',
          (true, false) => 'Ninguém votou 😅',
        },
      );
    }
    if (rodada.modo == ModoDeJogo.impostor) {
      final impostor = visao.jogador(revelacao.impostor ?? '');
      return SuspenseDaVotacao(
        key: key,
        chave: chave,
        maisVotados: [?impostor],
        chamada: 'E o impostor era…',
        resultado: revelacao.pegaram ? 'PEGARAM! 🕵️' : 'ESCAPOU! 😈',
      );
    }
    final ids = revelacao.escolhidos.isNotEmpty ? revelacao.escolhidos : revelacao.perderam;
    if (rodada.duelo) {
      return SuspenseDaVotacao(
        key: key,
        chave: chave,
        maisVotados: [for (final id in revelacao.escolhidos) ?visao.jogador(id)],
        chamada: 'E quem venceu o duelo é…',
        resultado: revelacao.escolhidos.length == 1 ? '👑 Venceu!' : 'Empate! 🤝',
      );
    }
    return SuspenseDaVotacao(
      key: key,
      chave: chave,
      maisVotados: [for (final id in ids) ?visao.jogador(id)],
      chamada: revelacao.elogio ? 'E quem leva é…' : 'E o mais votado é…',
      resultado: revelacao.elogio
          ? distribuiGoles(visao, 3)
          : switch (ids) {
              [final id] => visao.jogador(id) == null
                  ? null
                  : destinoDoPego(visao, visao.jogador(id)!).replaceFirst('bebe 🍺', 'bebe! 🍺'),
              _ => switch ((visao.configuracao.pontosPorGole, visao.configuracao.semAlcool)) {
                  (1, true) => 'todos pagam prenda! 🎟️',
                  (1, false) => 'todos bebem! 🍺',
                  _ => '+1 ponto para todos!',
                },
            },
    );
  }

  /// Sala e rodada: identifica a votação.
  final String chave;
  final List<Jogador> maisVotados;

  /// Frase do tambor.
  final String chamada;

  /// Frase embaixo do nome; sem ela, "bebe!".
  final String? resultado;
  final Duration tempoDoTambor;
  final Duration tempoDoResultado;

  @override
  State<SuspenseDaVotacao> createState() => _SuspenseDaVotacaoState();
}

enum _Etapa { tambor, resultado, fim }

class _SuspenseDaVotacaoState extends State<SuspenseDaVotacao> with TickerProviderStateMixin {
  // Criados já no início: criar no dispose (suspense pulado) quebrava ao fechar a tela.
  late final AnimationController _batida;
  late final AnimationController _entrada;
  Timer? _relogio;
  var _etapa = _Etapa.fim;

  @override
  void initState() {
    super.initState();
    _batida = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    if (widget.maisVotados.isEmpty || !_jaMostrados.add(widget.chave)) return;
    _batida.repeat(reverse: true);
    _etapa = _Etapa.tambor;
    _relogio = Timer(widget.tempoDoTambor, () {
      if (!mounted) return;
      // O tambor para de bater: animação parada não gasta bateria.
      _batida.stop();
      setState(() => _etapa = _Etapa.resultado);
      _entrada.forward();
      _relogio = Timer(widget.tempoDoResultado, _encerrar);
    });
  }

  void _encerrar() {
    _relogio?.cancel();
    if (_etapa == _Etapa.tambor) _batida.stop();
    if (mounted) setState(() => _etapa = _Etapa.fim);
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _batida.dispose();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_etapa == _Etapa.fim) return const SizedBox.shrink();
    final empate = widget.maisVotados.length > 1;
    return GestureDetector(
      key: const Key('suspense'),
      behavior: HitTestBehavior.opaque,
      onTap: _encerrar,
      child: ColoredBox(
        // Opaco: nada da revelação por baixo pode estragar a surpresa.
        color: CoresBaralho.fundo,
        child: Center(
          child: _etapa == _Etapa.tambor
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.15).animate(_batida),
                    child: const Text('🥁', style: TextStyle(fontSize: 88)),
                  ),
                  const SizedBox(height: EspacoBaralho.grande),
                  Text(widget.chamada,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                ])
              : ScaleTransition(
                  scale: CurvedAnimation(parent: _entrada, curve: Curves.elasticOut),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (empate)
                      const Text('Empate!', style: TextStyle(fontSize: 22, color: CoresBaralho.ambar)),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: EspacoBaralho.base,
                      runSpacing: EspacoBaralho.base,
                      children: [
                        for (final jogador in widget.maisVotados)
                          AvatarDoJogador(
                            jogador: jogador,
                            tamanho: empate ? 120 : 200,
                            destaque: CoresBaralho.maisProvavel,
                          ),
                      ],
                    ),
                    const SizedBox(height: EspacoBaralho.base),
                    Text(
                      widget.maisVotados.map((j) => j.nome).join(' e '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.resultado ??
                          (empate ? 'todos bebem! 🍺' : (widget.maisVotados.single.semAlcool ? '+1 ponto ⭐' : 'bebe! 🍺')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, color: CoresBaralho.ambar),
                    ),
                  ]),
                ),
        ),
      ),
    );
  }
}
