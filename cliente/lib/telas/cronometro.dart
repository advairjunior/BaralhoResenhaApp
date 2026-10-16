import 'dart:async';

import 'package:flutter/material.dart';

import '../tema/tema_baralho.dart';

/// "Em 5 segundos", "dancinha de 10 segundos": sem relógio, ninguém cobra.
int? segundosDaCarta(String texto) {
  final achado = RegExp(r'(\d+) segundos').firstMatch(texto);
  return achado == null ? null : int.parse(achado.group(1)!);
}

/// Cronômetro da carta, em cada celular. Tocar de novo recomeça: na rodada
/// em que cada um tem 5 segundos, é um toque por pessoa.
class Cronometro extends StatefulWidget {
  const Cronometro({super.key, required this.segundos});

  final int segundos;

  @override
  State<Cronometro> createState() => _CronometroState();
}

class _CronometroState extends State<Cronometro> {
  // Nulo = parado; 0 = acabou o tempo.
  int? _restante;
  Timer? _relogio;

  void _comecar() {
    _relogio?.cancel();
    setState(() => _restante = widget.segundos);
    _relogio = Timer.periodic(const Duration(seconds: 1), (relogio) {
      if (!mounted) return relogio.cancel();
      setState(() => _restante = _restante! - 1);
      if (_restante == 0) relogio.cancel();
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restante = _restante;
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacoBaralho.base),
      child: switch (restante) {
        null => OutlinedButton(onPressed: _comecar, child: Text('⏱️ Valendo! ${widget.segundos} segundos')),
        0 => OutlinedButton(onPressed: _comecar, child: const Text('Tempo! ⏰ Toque para o próximo')),
        _ => GestureDetector(
            onTap: _comecar,
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
      },
    );
  }
}
