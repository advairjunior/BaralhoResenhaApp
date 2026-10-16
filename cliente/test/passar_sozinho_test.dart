import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
];

Map<String, dynamic> _bebaSe({
  List<String> prontos = const [],
  int? passaEmMs,
  String? seguradaPor,
  String euId = 'bia',
  bool euBebi = false,
}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.'),
        'prontos': prontos,
        'passaEmMs': passaEmMs,
        'seguradaPor': seguradaPor,
        'euBebi': euBebi,
      },
    );

Map<String, dynamic> _revelada({String euId = 'bia', List<Map<String, String>> pendentes = const []}) => visaoJson(
      euId: euId,
      souAnfitriao: false,
      fase: 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(revelacao: {
          'jaFizeram': ['ana'],
          'nuncaFizeram': ['bia'],
          'votos': [],
          'perderam': ['ana'],
          'contaAHistoria': null,
        }),
        'pendentes': pendentes,
      },
    );

void main() {
  group('Passar a carta sozinho', () {
    testWidgets('no Beba se dá para responder que não me pegou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _bebaSe()
        ..respostas['POST /api/salas/ABCD/pronto'] = _bebaSe(prontos: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Não 👍'));
      await tester.tap(find.text('Não 👍'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(servidor.recebidas.last.corpo, {'rodada': 1});
      expect(find.text('Responderam: 1 de 2 · falta Ana'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala também tem o "Não" no Beba se', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _bebaSe(euId: 'ana');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Não 👍'));
      expect(find.text('Não 👍'), findsOneWidget);
      expect(find.text('Me pegou! 🍺'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem marcou "Me pegou" por engano troca para "Não"', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _bebaSe(euBebi: true)
        ..respostas['POST /api/salas/ABCD/bebi'] = _bebaSe(prontos: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Não 👍'));
      await tester.tap(find.text('Não 👍'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/bebi');
      expect(find.text('Não ✓'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('depois da revelação só quem tem pendência confirma', (tester) async {
      final pendentes = [
        {'jogadorId': 'bia', 'motivo': 'Beber'},
        {'jogadorId': 'ana', 'motivo': 'Historia'},
      ];
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada(pendentes: pendentes)
        ..respostas['POST /api/salas/ABCD/pronto'] = _revelada(pendentes: [pendentes[1]]);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Pronto ✓'), findsNothing);
      await rolarAte(tester, find.text('🍺 Bebi ✓'));
      await tester.tap(find.text('🍺 Bebi ✓'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(find.text('Esperando: Ana contar a história 🎤'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem não tem pendência só vê quem a mesa está esperando', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada(pendentes: [
          {'jogadorId': 'ana', 'motivo': 'Beber'},
        ]);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Esperando: Ana beber 🍺'));
      expect(find.text('🍺 Bebi ✓'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('com todo mundo pronto, a carta passa sozinha em 3 segundos', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _bebaSe(prontos: ['ana', 'bia'], passaEmMs: 3000)
        ..respostas['POST /api/salas/ABCD/passar-sozinho'] = _bebaSe();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      await tester.pump(const Duration(milliseconds: 300));

      await rolarAte(tester, find.text('⏸️ Segura aí'));
      expect(find.textContaining('Próxima carta em'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(servidor.rotas, contains('POST /api/salas/ABCD/passar-sozinho'));
      await fecharApp(tester);
    });

    testWidgets('qualquer um segura a carta', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _bebaSe(prontos: ['ana', 'bia'], passaEmMs: 3000)
        ..respostas['POST /api/salas/ABCD/segurar'] = _bebaSe(prontos: ['ana', 'bia'], seguradaPor: 'Bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      await tester.pump(const Duration(milliseconds: 300));

      await rolarAte(tester, find.text('⏸️ Segura aí'));
      await tester.tap(find.text('⏸️ Segura aí'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(servidor.rotas, contains('POST /api/salas/ABCD/segurar'));
      expect(find.text('⏸️ Bia segurou a carta. Ana passa quando quiser.'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
