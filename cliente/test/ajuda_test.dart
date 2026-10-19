import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _tribunal() => visaoJson(
      euId: 'bia',
      souAnfitriao: false,
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'Tribunal', texto: 'Ana tem cara de quem dorme de meia?'),
        'alvo': 'ana',
        'pedeResposta': true,
      },
    );

Map<String, dynamic> _comMao({List<String> pegos = const [], List<Map<String, dynamic>> usos = const []}) => {
      ...visaoJson(
        fase: 'Carta',
        jogadores: _mesa,
        rodada: {
          ...rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.', beberam: const ['ana'], euBebi: true),
          'pegos': pegos,
          'usos': usos,
        },
      ),
      'minhaMao': ['Escudo'],
    };

void main() {
  group('O jogo se explica sozinho', () {
    testWidgets('ⓘ Como joga explica o jogo da carta', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _tribunal();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('como-joga')));
      await tester.tap(find.byKey(const Key('como-joga')));
      await tester.pumpAndSettle();

      expect(find.text('Como joga: Tribunal da Turma'), findsOneWidget);
      expect(find.textContaining('O resto da turma vota em segredo'), findsOneWidget);
      expect(find.textContaining('cofrinho'), findsWidgets);
      await fecharApp(tester);
    });

    testWidgets('na primeira vez de um jogo aparece a dica; depois, não', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _tribunal();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
      expect(find.text('💡 Primeira vez de Tribunal da Turma? Toque e veja como joga'), findsOneWidget);
      await fecharApp(tester);

      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: {
        ..._logado,
        'dicas_vistas': ['tribunal'],
      });
      expect(find.textContaining('Primeira vez'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('tocar numa carta na manga mostra a ficha, mesmo sem poder usar', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comMao();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('manga-escudo')));
      await tester.tap(find.byKey(const Key('manga-escudo')));
      await tester.pumpAndSettle();

      expect(find.text('O que faz'), findsOneWidget);
      expect(find.text('Quando dá para usar'), findsOneWidget);
      expect(find.text('⏳ A carta não te pegou: guarde a sua para depois.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('o guia mostra todas as cartas na manga e como ganhar mais', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comMao();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('guia-das-cartas')));
      await tester.tap(find.byKey(const Key('guia-das-cartas')));
      await tester.pumpAndSettle();

      for (final nome in ['Escudo', 'Passa a bola', 'Devolve', 'Batata quente', 'Dobra']) {
        expect(find.textContaining(nome), findsWidgets);
      }
      expect(find.text('Como ganhar mais'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a sala de espera explica como funciona o jogo', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byTooltip('Como funciona o jogo'));
      await tester.pumpAndSettle();

      expect(find.text('Como funciona o Baralho da Resenha'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('o resumo do jogo explica o que fazer quando alguém cai da sala', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byTooltip('Como funciona o jogo'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('📵 Caiu da sala?'), 200, scrollable: find.byType(Scrollable).last);

      expect(find.textContaining('entre de novo com o mesmo nome'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quando a carta passa de mão, o "Pegou" mostra para onde foi', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comMao(pegos: ['bia'], usos: [
          {'quem': 'ana', 'carta': 'PassaABola', 'alvo': 'bia'},
        ]);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Pegou: Ana → 🎯 passou para Bia'));
      await fecharApp(tester);
    });
  });
}
