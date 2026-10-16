import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
];

Map<String, dynamic> _bebaSe({List<String> prontos = const [], int? passaEmMs, String? seguradaPor}) => visaoJson(
      euId: 'bia',
      souAnfitriao: false,
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.'),
        'prontos': prontos,
        'passaEmMs': passaEmMs,
        'seguradaPor': seguradaPor,
      },
    );

Map<String, dynamic> _revelada({List<String> prontos = const []}) => visaoJson(
      euId: 'bia',
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
        'prontos': prontos,
      },
    );

void main() {
  group('Passar a carta sozinho', () {
    testWidgets('no Beba se dá para responder que não me pegou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _bebaSe()
        ..respostas['POST /api/salas/ABCD/pronto'] = _bebaSe(prontos: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Não me pegou 👍'));
      await tester.tap(find.text('Não me pegou 👍'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(servidor.recebidas.last.corpo, {'rodada': 1});
      expect(find.text('Responderam: 1 de 2 · falta Ana'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('depois da revelação cada um marca Pronto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada()
        ..respostas['POST /api/salas/ABCD/pronto'] = _revelada(prontos: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Pronto ✓'));
      await tester.tap(find.text('Pronto ✓'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(find.text('Prontos: 1 de 2 · falta Ana'), findsOneWidget);
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
