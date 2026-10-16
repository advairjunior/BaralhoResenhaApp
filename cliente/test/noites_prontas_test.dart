import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

void main() {
  group('Noites prontas', () {
    testWidgets('um toque deixa a noite inteira configurada', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson()
        ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('noite-brincadeiras')));
      await tester.tap(find.byKey(const Key('noite-brincadeiras')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'PUT /api/salas/ABCD/configuracao');
      expect(servidor.recebidas.last.corpo, {
        'nivel': 'Resenha',
        'modos': ['MaisProvavel', 'RegraRelampago', 'Elogios', 'Correio', 'ImagemEAcao'],
        'zonaSegura': true,
        'esquentar': false,
        'ritmo': 'Devagar',
        'cartasNaManga': true,
        'passarSozinho': true,
      });
      await fecharApp(tester);
    });

    testWidgets('a noite escolhida aparece marcada', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(
          nivel: 'Resenha',
          modos: ['EuNunca', 'MaisProvavel', 'BebaSe', 'RegraRelampago', 'Tribunal'],
          ritmo: 'Devagar',
        );
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('noite-classica')));
      expect(find.text('✓ Resenha clássica'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a noite Raiz pede confirmação, como o Baralho Original', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson()
        ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('noite-raiz')));
      await tester.tap(find.byKey(const Key('noite-raiz')));
      await tester.pumpAndSettle();
      expect(find.textContaining('A turma toda topou?'), findsOneWidget);
      await tester.tap(find.text('Melhor não'));
      await tester.pumpAndSettle();

      expect(servidor.rotas, isNot(contains('PUT /api/salas/ABCD/configuracao')));
      await fecharApp(tester);
    });
  });
}
