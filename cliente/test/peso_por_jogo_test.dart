import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _comPesos({List<String> muito = const [], List<String> pouco = const []}) {
  final visao = visaoJson(modos: ['EuNunca', 'BebaSe', 'Tribunal']);
  (visao['configuracao'] as Map<String, dynamic>)
    ..['muito'] = muito
    ..['pouco'] = pouco;
  return visao;
}

void main() {
  group('Peso por jogo', () {
    testWidgets('"Mais Tribunal, menos Beba se" vai para o servidor', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comPesos()
        ..respostas['PUT /api/salas/ABCD/configuracao'] = _comPesos(muito: ['Tribunal']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('peso-tribunal-muito')));
      await tester.tap(find.byKey(const Key('peso-tribunal-muito')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'PUT /api/salas/ABCD/configuracao');
      expect(servidor.recebidas.last.corpo!['muito'], ['Tribunal']);
      expect(servidor.recebidas.last.corpo!.containsKey('pouco'), isFalse);
      await fecharApp(tester);
    });

    testWidgets('mudar de Muito para Pouco tira do Muito', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comPesos(muito: ['BebaSe'])
        ..respostas['PUT /api/salas/ABCD/configuracao'] = _comPesos(pouco: ['BebaSe']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('peso-bebaSe-pouco')));
      await tester.tap(find.byKey(const Key('peso-bebaSe-pouco')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo!['pouco'], ['BebaSe']);
      expect(servidor.recebidas.last.corpo!.containsKey('muito'), isFalse);
      await fecharApp(tester);
    });

    testWidgets('jogo desligado não mostra o peso', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comPesos();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('zona-segura')));
      expect(find.byKey(const Key('peso-tribunal-muito')), findsOneWidget);
      expect(find.byKey(const Key('peso-jurados-muito')), findsNothing);
      await fecharApp(tester);
    });
  });
}
