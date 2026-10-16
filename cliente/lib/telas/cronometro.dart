import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

/// Cronômetro da carta ("em 5 segundos", mímica de 60 s). Quem criou a sala
/// dá o "valendo" no servidor e todos os celulares contam o mesmo tempo.
/// Tocar de novo recomeça: na rodada em que cada um tem 5 segundos, é um
/// valendo por pessoa.
class Cronometro extends StatefulWidget {
  const Cronometro({super.key, required this.visao, required this.rodada, required this.aoIniciar});

  final VisaoDaSala visao;
  final Rodada rodada;
  final VoidCallback aoIniciar;

  @override
  State<Cronometro> createState() => _CronometroState();
}

class _CronometroState extends State<Cronometro> {
  // Quando acaba, no relógio deste celular; nulo antes do valendo. (clock: os testes controlam o tempo.)
  DateTime? _fim;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _sincronizar();
  }

  @override
  void didUpdateWidget(Cronometro antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.rodada.cronometroRestanteMs != widget.rodada.cronometroRestanteMs) _sincronizar();
  }

  /// O servidor manda quanto falta; aqui vira um horário de fim neste celular.
  void _sincronizar() {
    final restante = widget.rodada.cronometroRestanteMs;
    _relogio?.cancel();
    _fim = restante == null ? null : clock.now().add(Duration(milliseconds: restante));
    if (restante != null && restante > 0) {
      _relogio = Timer.periodic(const Duration(milliseconds: 200), (relogio) {
        if (!mounted) return relogio.cancel();
        setState(() {});
        if (_segundosQueFaltam == 0) relogio.cancel();
      });
    }
  }

  int? get _segundosQueFaltam {
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
    final segundos = widget.rodada.cronometroSegundos ?? 0;
    final souAnfitriao = widget.visao.souAnfitriao;
    final faltam = _segundosQueFaltam;
    final valendo = OutlinedButton(onPressed: widget.aoIniciar, child: Text('⏱️ Valendo! $segundos segundos'));
    final Widget conteudo = switch (faltam) {
      null when souAnfitriao => valendo,
      null => Text(
          '⏱️ ${widget.visao.anfitriao?.nome ?? 'Quem criou a sala'} dá o valendo ($segundos segundos)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
      0 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Tempo! ⏰',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: CoresBaralho.coral)),
          if (souAnfitriao) TextButton(onPressed: widget.aoIniciar, child: const Text('Valendo de novo')),
        ]),
      final restante => GestureDetector(
          onTap: souAnfitriao ? widget.aoIniciar : null,
          child: Text(
            '$restante',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: restante <= 3 ? CoresBaralho.coral : CoresBaralho.ambar,
            ),
          ),
        ),
    };
    return Padding(padding: const EdgeInsets.only(bottom: EspacoBaralho.base), child: conteudo);
  }
}
