import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _comMao({
  List<String> mao = const ['Escudo', 'PassaABola'],
  List<String> pegos = const ['ana'],
  List<Map<String, dynamic>> usos = const [],
  List<String> ganharam = const [],
}) =>
    {
      ...visaoJson(
        fase: 'Carta',
        jogadores: _mesa,
        rodada: {
          ...rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.', euBebi: pegos.contains('ana'), beberam: pegos),
          'pegos': pegos,
          'usos': usos,
          'ganharam': ganharam,
        },
      ),
      'minhaMao': mao,
    };

void main() {
  group('Cartas na manga', () {
    testWidgets('quem a carta pegou usa o Escudo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comMao()
        ..respostas['POST /api/salas/ABCD/carta-na-manga'] = _comMao(mao: ['PassaABola'], pegos: []);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('manga-escudo')));
      expect(find.text('🃏 Sua mão'), findsOneWidget);
      await tester.tap(find.byKey(const Key('manga-escudo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar 🛡️'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/carta-na-manga');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'carta': 'Escudo', 'alvo': null});
      await fecharApp(tester);
    });

    testWidgets('Passa a bola pede em quem jogar', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comMao()
        ..respostas['POST /api/salas/ABCD/carta-na-manga'] = _comMao(mao: ['Escudo'], pegos: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('manga-passaABola')));
      await tester.tap(find.byKey(const Key('manga-passaABola')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('alvo-ana')), findsNothing);
      await tester.tap(find.byKey(const Key('alvo-bia')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'carta': 'PassaABola', 'alvo': 'bia'});
      await fecharApp(tester);
    });

    testWidgets('quem a carta não pegou guarda o Escudo para depois', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comMao(pegos: []);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('manga-escudo')));
      await tester.tap(find.byKey(const Key('manga-escudo')));
      await tester.pumpAndSettle();

      expect(find.text('Usar 🛡️'), findsNothing);
      expect(servidor.rotas, isNot(contains('POST /api/salas/ABCD/carta-na-manga')));
      await fecharApp(tester);
    });

    testWidgets('a mesa inteira vê quem usou carta e quem ganhou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comMao(usos: [
          {'quem': 'bia', 'carta': 'BatataQuente', 'alvo': 'ana', 'goles': 3},
        ], ganharam: ['caio']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('🥔 Bia jogou a batata quente em Ana: 3 goles!'));
      expect(find.text('🃏 Caio ganhou uma carta na manga'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
