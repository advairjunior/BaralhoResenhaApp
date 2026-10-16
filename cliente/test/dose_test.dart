import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _dose({List<String> bebemAgora = const [], bool euBebi = false}) => visaoJson(
      fase: 'Carta',
      ritmo: 'Devagar',
      rodada: {
        ...rodadaJson(
          modo: 'BebaSe',
          texto: 'Ana conta a pior viagem que já fez com a turma ou bebe 2.',
          bebemAgora: bebemAgora,
          euBebi: euBebi,
        ),
        'goles': 2,
      },
    );

void main() {
  testWidgets('carta que manda beber 2 avisa que é dose de verdade', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _dose()
      ..respostas['POST /api/salas/ABCD/bebi'] = _dose(bebemAgora: ['ana'], euBebi: true);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('🍺 DOSE DE VERDADE · BEBE 2'), findsOneWidget);
    await rolarAte(tester, find.text('Me pegou! Bebe 2 🍺'));
    await tester.tap(find.text('Me pegou! Bebe 2 🍺'));
    await tester.pumpAndSettle();

    await rolarAte(tester, find.byKey(const Key('hora-do-gole')));
    expect(find.text('🍺 Dose! Ana bebe 2 agora.'), findsOneWidget);
    await fecharApp(tester);
  });
}
