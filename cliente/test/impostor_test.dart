import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
  jogadorJson('duda', 'Duda'),
];

Map<String, dynamic> _impostor({
  String euId = 'ana',
  bool souImpostor = false,
  String? minhaResposta,
  Map<String, dynamic>? revelacao,
}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'Impostor',
          texto: souImpostor && revelacao == null ? '🕵️ Você é o impostor!' : 'Pizza',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'dica': 'Tema: Comida',
        'fila': ['caio', 'ana', 'duda', 'bia'],
        'souImpostor': souImpostor,
      },
    );

Map<String, dynamic> _revelacao({required bool pegaram}) => {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [
        {'jogadorId': pegaram ? 'duda' : 'bia', 'votos': 3},
        {'jogadorId': pegaram ? 'bia' : 'duda', 'votos': 1},
      ],
      'perderam': pegaram ? ['duda'] : ['ana', 'caio'],
      'contaAHistoria': null,
      'escolhidos': [pegaram ? 'duda' : 'bia'],
      'impostor': 'duda',
      'pegaram': pegaram,
    };

Future<void> _passarDoSuspense(WidgetTester tester) async {
  for (var passo = 0; passo < 8; passo++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('quem não é o impostor vê a palavra, o tema e a ordem das pistas', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _impostor();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('🕵️ TEM UM IMPOSTOR NA MESA'), findsOneWidget);
    await rolarAte(tester, find.byKey(const Key('ordem-das-pistas')));
    expect(find.text('Pistas, nesta ordem: Caio → Você → Duda → Bia'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('o impostor só vê o tema e vota em quem acha que sabe menos', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _impostor(euId: 'duda', souImpostor: true)
      ..respostas['POST /api/salas/ABCD/respostas'] =
          _impostor(euId: 'duda', souImpostor: true, minhaResposta: 'bia');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('🕵️ Você é o impostor!'), findsOneWidget);
    expect(find.text('Pizza'), findsNothing);
    await rolarAte(tester, find.byKey(const Key('votar-bia')));
    // Ninguém vota em si mesmo.
    expect(find.byKey(const Key('votar-duda')), findsNothing);
    await tester.tap(find.byKey(const Key('votar-bia')));
    await tester.pumpAndSettle();

    final enviada = servidor.recebidas.lastWhere((r) => r.rota == 'POST /api/salas/ABCD/respostas');
    expect(enviada.corpo, {'rodada': 1, 'resposta': 'bia'});
    await fecharApp(tester);
  });

  testWidgets('a turma pegou o impostor', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _impostor(revelacao: _revelacao(pegaram: true));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
    await _passarDoSuspense(tester);

    await rolarAte(tester, find.byKey(const Key('resultado-do-impostor')));
    expect(find.text('Pegaram! Duda era o impostor 🕵️'), findsOneWidget);
    expect(find.text('A palavra era: Pizza'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('o impostor escapou e quem votou errado leva', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _impostor(revelacao: _revelacao(pegaram: false));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
    await _passarDoSuspense(tester);

    await rolarAte(tester, find.byKey(const Key('resultado-do-impostor')));
    expect(find.text('Duda era o impostor e escapou! 😈'), findsOneWidget);
    expect(find.textContaining('Quem votou errado:'), findsOneWidget);
    await fecharApp(tester);
  });
}
