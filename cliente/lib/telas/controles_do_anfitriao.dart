import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

/// Puxar a próxima carta é com quem criou a sala: com todo mundo podendo,
/// vira bagunça. Para os outros fica o aviso de quem eles estão esperando.
class ProximaCarta extends StatelessWidget {
  const ProximaCarta({
    super.key,
    required this.visao,
    required this.aoTocar,
    this.rotulo = 'Próxima carta',
  });

  final VisaoDaSala visao;
  final VoidCallback aoTocar;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    if (visao.souAnfitriao) {
      return FilledButton(key: const Key('proxima-carta'), onPressed: aoTocar, child: Text(rotulo));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacoBaralho.medio),
      child: Text(
        'Esperando ${visao.anfitriao?.nome ?? 'quem criou a sala'} puxar a próxima carta 🃏',
        key: const Key('esperando-anfitriao'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: CoresBaralho.textoApagado),
      ),
    );
  }
}
