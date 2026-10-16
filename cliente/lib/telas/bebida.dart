import 'dart:math';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

/// Cofrinho de goles: cada vez que a carta pega alguém vale um ponto, e o
/// gole de verdade só sai quando o cofrinho enche.
extension VisualDoRitmo on RitmoDaBebida {
  String get titulo => switch (this) {
        RitmoDaBebida.devagar => '🐢 Devagar',
        RitmoDaBebida.normal => '🚶 Normal',
        RitmoDaBebida.raiz => '🔥 Raiz',
      };

  String get explicacao => switch (this) {
        RitmoDaBebida.devagar => '1 gole a cada 3 pontos',
        RitmoDaBebida.normal => '1 gole a cada 2 pontos',
        RitmoDaBebida.raiz => 'Todo ponto é gole',
      };
}

/// O que a carta fez com quem ela pegou.
String destinoDoPego(VisaoDaSala visao, Jogador jogador) {
  if (jogador.semAlcool) return '+1 ponto ⭐';
  final porGole = visao.configuracao.pontosPorGole;
  if (porGole == 1 || (visao.rodada?.bebemAgora.contains(jogador.id) ?? false)) return 'bebe 🍺';
  return '+1 ponto · ${jogador.cofrinho}/$porGole 🍺';
}

/// Elogio: quem a turma escolhe distribui goles, menos nos ritmos mais calmos.
String distribuiGoles(VisaoDaSala visao, int noRaiz) {
  final goles = max(1, noRaiz ~/ visao.configuracao.pontosPorGole);
  return goles == 1 ? '💛 distribui 1 gole' : '💛 distribui $goles goles';
}

/// Faixa de quem encheu o cofrinho nesta carta.
class HoraDoGole extends StatelessWidget {
  const HoraDoGole({super.key, required this.visao});

  final VisaoDaSala visao;

  @override
  Widget build(BuildContext context) {
    final rodada = visao.rodada;
    // No Raiz todo ponto já diz "bebe": a faixa seria repetição.
    if (rodada == null || visao.configuracao.pontosPorGole == 1) return const SizedBox.shrink();
    final nomes = [for (final id in rodada.bebemAgora) ?visao.jogador(id)?.nome];
    if (nomes.isEmpty) return const SizedBox.shrink();
    final quem = nomes.length == 1
        ? '${nomes.single} bebe'
        : '${nomes.take(nomes.length - 1).join(', ')} e ${nomes.last} bebem';
    return Container(
      key: const Key('hora-do-gole'),
      margin: const EdgeInsets.only(bottom: EspacoBaralho.base),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.ambarEscuro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresBaralho.ambar),
      ),
      child: Text('🍺 Cofrinho cheio! $quem agora.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }
}
