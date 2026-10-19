import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _jogo(List<int> pontos) => visaoJson(
      fase: 'Carta',
      jogadores: [
        jogadorJson('ana', 'Ana', anfitriao: true, pontos: pontos[0]),
        jogadorJson('bia', 'Bia', pontos: pontos[1]),
        jogadorJson('caio', 'Caio', pontos: pontos[2]),
        jogadorJson('duda', 'Duda', pontos: pontos[3]),
      ],
      rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.'),
    );

void main() {
  testWidgets('a faixa em cima da carta mostra os três mais pegos até agora', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _jogo([2, 5, 0, 1]);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('🏆 Bia 5 · Ana 2 · Duda 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('placar-ao-vivo')));
    await tester.pumpAndSettle();
    expect(find.text('🏆 Placar da noite'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('antes de alguém ser pego não tem faixa', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _jogo([0, 0, 0, 0]);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.byKey(const Key('placar-ao-vivo')), findsNothing);
    await fecharApp(tester);
  });
}
