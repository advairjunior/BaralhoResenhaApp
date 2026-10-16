import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _tribunal({
  String euId = 'bia',
  bool elogio = false,
  Map<String, dynamic>? revelacao,
  String? minhaResposta,
}) =>
    visaoJson(
      euId: euId,
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'Tribunal',
          texto: elogio ? 'Ana recebe olhares quando passa na rua?' : 'Ana tem cara de machão alfa?',
          revelacao: revelacao,
          minhaResposta: minhaResposta,
        ),
        'alvo': 'ana',
        'elogio': elogio,
      },
    );

Map<String, dynamic> _veredito({required bool condenado, bool elogio = false}) => {
      'jaFizeram': condenado ? ['bia', 'caio'] : ['bia'],
      'nuncaFizeram': condenado ? [] : ['caio'],
      'votos': [],
      'perderam': condenado && !elogio ? ['ana'] : [],
      'contaAHistoria': null,
      'elogio': elogio,
      'escolhidos': condenado ? ['ana'] : [],
    };

/// Passa o tambor e a foto do suspense.
Future<void> passarSuspense(WidgetTester tester) async {
  for (var passo = 0; passo < 8; passo++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  group('Tribunal da Turma', () {
    testWidgets('jurado vota sim ou não em segredo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _tribunal()
        ..respostas['POST /api/salas/ABCD/respostas'] = _tribunal(minhaResposta: 'sim');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('👍 SIM OU 👎 NÃO, EM SEGREDO'), findsOneWidget);
      expect(find.text('0 de 2 responderam'), findsOneWidget);
      await rolarAte(tester, find.text('👍 Sim'));
      await tester.tap(find.text('👍 Sim'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'sim'});
      await fecharApp(tester);
    });

    testWidgets('réu só espera o veredito', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _tribunal(euId: 'ana');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('reu-esperando')));
      expect(find.text('A turma está te julgando…'), findsOneWidget);
      expect(find.text('👍 Sim'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('maioria sim condena e mostra o placar, sem dizer quem votou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _tribunal(revelacao: _veredito(condenado: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      await passarSuspense(tester);

      await rolarAte(tester, find.byKey(const Key('placar-do-tribunal')));
      expect(find.text('Culpado(a)! 🔨'), findsOneWidget);
      expect(find.text('Ana bebe 🍺'), findsOneWidget);
      expect(find.text('👍 2   ·   👎 0'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('no elogio, quem a turma confirma distribui goles', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _tribunal(elogio: true, revelacao: _veredito(condenado: true, elogio: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      await passarSuspense(tester);

      expect(find.text('💛 ELOGIO · A TURMA DECIDE'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('placar-do-tribunal')));
      expect(find.text('A turma concorda! 💛'), findsOneWidget);
      expect(find.text('Ana 💛 distribui 2 goles'), findsOneWidget);
      await fecharApp(tester);
    });
  });

  group('Quem é mais provável', () {
    testWidgets('sem votação, a tela conta até 3 para a turma apontar', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(
          fase: 'Carta',
          jogadores: _mesa,
          rodada: {
            ...rodadaJson(modo: 'MaisProvavel', texto: 'Quem é mais provável de roncar?'),
            'pedeResposta': false,
            'votacao': false,
          },
        )
        ..respostas['POST /api/salas/ABCD/apontado'] = visaoJson(fase: 'Carta', jogadores: _mesa, rodada: {
            ...rodadaJson(modo: 'MaisProvavel', texto: 'Quem é mais provável de roncar?', beberam: ['bia']),
            'pedeResposta': false,
            'votacao': false,
          });
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('👉 TODO MUNDO APONTA NO 3'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('contar-ate-tres')));
      await tester.tap(find.byKey(const Key('contar-ate-tres')));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text('APONTEM! 👉'), findsOneWidget);
      expect(find.text('Toque em quem a turma apontou:'), findsOneWidget);
      expect(find.textContaining('Me pegou'), findsNothing);
      await rolarAte(tester, find.byKey(const Key('apontar-bia')));
      await tester.tap(find.byKey(const Key('apontar-bia')));
      await tester.pumpAndSettle();
      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/apontado');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'jogadorId': 'bia'});
      await fecharApp(tester);
    });

    testWidgets('no elogio, o mais votado leva e distribui goles', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(
          fase: 'Revelada',
          jogadores: _mesa,
          rodada: {
            ...rodadaJson(modo: 'MaisProvavel', texto: 'Quem tem o sorriso mais bonito?', revelacao: {
              'jaFizeram': [],
              'nuncaFizeram': [],
              'votos': [
                {'jogadorId': 'caio', 'votos': 3},
              ],
              'perderam': [],
              'contaAHistoria': null,
              'elogio': true,
              'escolhidos': ['caio'],
            }),
            'votacao': true,
            'elogio': true,
          },
        );
      // Outra sala: o suspense da ABCD já passou em testes anteriores.
      servidor.respostas['GET /api/salas/XYZW'] = servidor.respostas['GET /api/salas/ABCD']!;
      await abrirApp(tester, servidor, rota: '/sala/XYZW', guardado: {'sala_XYZW': 'tk'}, esperarAcalmar: false);

      await passarSuspense(tester);
      await rolarAte(tester, find.text('💛 distribui 3 goles'));
      expect(find.text('💛 distribui 3 goles'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
