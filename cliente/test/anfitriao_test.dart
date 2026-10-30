import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _bebaSe({required bool souAnfitriao}) => visaoJson(
      euId: souAnfitriao ? 'ana' : 'bia',
      souAnfitriao: souAnfitriao,
      fase: 'Carta',
      jogadores: _mesa,
      rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se você usa óculos.'),
    );

void main() {
  testWidgets('quem não criou a sala não puxa, não pula nem tira carta', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _bebaSe(souAnfitriao: false);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.byKey(const Key('esperando-anfitriao')));
    expect(find.text('Esperando Ana puxar a próxima carta 🃏'), findsOneWidget);
    expect(find.byKey(const Key('proxima-carta')), findsNothing);
    expect(find.byKey(const Key('tira-essa')), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('quem criou a sala puxa a próxima carta', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _bebaSe(souAnfitriao: true)
      ..respostas['POST /api/salas/ABCD/proxima'] = _bebaSe(souAnfitriao: true);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.byKey(const Key('tira-essa')), findsOneWidget);
    await rolarAte(tester, find.byKey(const Key('proxima-carta')));
    await tester.tap(find.byKey(const Key('proxima-carta')));
    await tester.pumpAndSettle();

    expect(servidor.rotas, contains('POST /api/salas/ABCD/proxima'));
    await fecharApp(tester);
  });

  testWidgets('na votação, guest não vê pular nem revelar', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        euId: 'bia',
        souAnfitriao: false,
        fase: 'Carta',
        jogadores: _mesa,
        rodada: {...rodadaJson(modo: 'MaisProvavel', texto: 'Quem é mais provável de roncar?'), 'votacao': true},
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('Pular carta'), findsNothing);
    expect(find.text('Revelar agora'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('revelação da votação mostra a foto e o nome de todo mundo', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/QWER'] = {
        ...visaoJson(
          fase: 'Revelada',
          jogadores: _mesa,
          rodada: {
            ...rodadaJson(modo: 'MaisProvavel', texto: 'Quem é mais provável de roncar?', revelacao: {
              'jaFizeram': [],
              'nuncaFizeram': [],
              'votos': [
                {'jogadorId': 'caio', 'votos': 2},
                {'jogadorId': 'bia', 'votos': 1},
              ],
              'perderam': ['caio'],
              'contaAHistoria': null,
              'escolhidos': ['caio'],
            }),
            'votacao': true,
          },
        ),
        'codigo': 'QWER',
      };
    await abrirApp(tester, servidor, rota: '/sala/QWER', guardado: {'sala_QWER': 'tk'}, esperarAcalmar: false);
    for (var passo = 0; passo < 8; passo++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await rolarAte(tester, find.byKey(const Key('votos-de-todos')));
    expect(find.text('2 votos'), findsOneWidget);
    expect(find.text('1 voto'), findsOneWidget);
    expect(find.text('0 votos'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('Rodada de Elogios não tem "Me pegou" nem gole', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Carta',
        jogadores: _mesa,
        rodada: rodadaJson(modo: 'Elogios', texto: 'Cada um diz em que Bia é imbatível.'),
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.textContaining('RODADA DE ELOGIOS'), findsOneWidget);
    expect(find.text('NINGUÉM BEBE, TODO MUNDO SE ACHA'), findsOneWidget);
    expect(find.textContaining('Me pegou'), findsNothing);
    await rolarAte(tester, find.text('Pronto! Próxima carta'));
    expect(find.text('Pronto! Próxima carta'), findsOneWidget);
    await fecharApp(tester);
  });
}
