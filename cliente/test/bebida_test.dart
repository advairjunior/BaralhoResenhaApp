import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _soAnaFez({required int cofrinho, List<String> bebemAgora = const []}) => visaoJson(
      fase: 'Revelada',
      ritmo: 'Devagar',
      jogadores: [
        jogadorJson('ana', 'Ana', anfitriao: true, pontos: 5, goles: 1, cofrinho: cofrinho),
        jogadorJson('bia', 'Bia'),
      ],
      rodada: rodadaJson(bebemAgora: bebemAgora, revelacao: {
        'jaFizeram': ['ana'],
        'nuncaFizeram': ['bia'],
        'votos': [],
        'perderam': ['ana'],
        'contaAHistoria': 'ana',
      }),
    );

void main() {
  group('Cofrinho de goles', () {
    testWidgets('no Devagar, quem a carta pega ganha ponto no cofrinho e não bebe', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _soAnaFez(cofrinho: 2);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Só Ana fez · +1 ponto · 2/3 🍺'), findsOneWidget);
      expect(find.byKey(const Key('hora-do-gole')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('quando o cofrinho enche, a tela avisa que é hora do gole', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _soAnaFez(cofrinho: 0, bebemAgora: ['ana']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Só Ana fez · bebe 🍺'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('hora-do-gole')));
      expect(find.text('🍺 Cofrinho cheio! Ana bebe agora.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('placar mostra goles de verdade e quanto falta no cofrinho', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _soAnaFez(cofrinho: 2);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byTooltip('Placar'));
      await tester.pumpAndSettle();

      expect(find.text('1 gole'), findsOneWidget);
      expect(find.text('5 pontos · cofrinho 2/3'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala escolhe o ritmo da bebida', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(ritmo: 'Devagar')
        ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson(ritmo: 'Normal');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('ritmo-normal')));
      expect(find.text('1 gole a cada 3 pontos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ritmo-normal')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo!['ritmo'], 'Normal');
      await fecharApp(tester);
    });
  });
}
