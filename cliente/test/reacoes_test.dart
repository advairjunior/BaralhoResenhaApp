import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _carta({Map<String, int> reacoes = const {}, String? minha}) => visaoJson(
      fase: 'Carta',
      rodada: {
        ...rodadaJson(modo: 'BebaSe', texto: 'Beba se já dormiu no cinema.'),
        'reacoes': reacoes,
        'minhaReacao': minha,
      },
    );

void main() {
  testWidgets('cada um reage na carta e vê quantos reagiram', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _carta(reacoes: {'🔥': 2})
      ..respostas['POST /api/salas/ABCD/reacao'] = _carta(reacoes: {'🔥': 2, '😂': 1}, minha: '😂');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.byKey(const Key('reacao-🔥')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('reacao-🔥')), matching: find.text('2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reacao-😂')));
    await tester.pumpAndSettle();

    final enviada = servidor.recebidas.lastWhere((r) => r.rota == 'POST /api/salas/ABCD/reacao');
    expect(enviada.corpo, {'rodada': 1, 'emoji': '😂'});
    expect(find.descendant(of: find.byKey(const Key('reacao-😂')), matching: find.text('1')), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('no fim, a carta que mais rendeu reação vira a carta da noite', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = {
        ...visaoJson(fase: 'Fim'),
        'momentos': [],
        'premios': [],
        'resumo': {
          'cartas': 12,
          'minutos': 40,
          'goles': 3,
          'pontos': 0,
          'cartaDaNoite': {
            'texto': 'Beba se já caiu da cadeira.',
            'reacoes': {'😂': 3, '💀': 1},
          },
        },
      };
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('🃏 Carta da noite'));
    expect(find.text('“Beba se já caiu da cadeira.”'), findsOneWidget);
    expect(find.text('😂 3   💀 1'), findsOneWidget);
    await fecharApp(tester);
  });
}
