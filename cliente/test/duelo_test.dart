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

Map<String, dynamic> _duelo({String euId = 'ana', String? minhaResposta, Map<String, dynamic>? revelacao}) => visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'MaisProvavel',
          texto: 'Duelo de dancinha: Bia contra Caio, 10 segundos cada. Quem dançou melhor?',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'votacao': true,
        'duelistas': ['bia', 'caio'],
      },
    );

void main() {
  group('Duelo', () {
    testWidgets('a turma vota só entre os dois do duelo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duelo()
        ..respostas['POST /api/salas/ABCD/respostas'] = _duelo(minhaResposta: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('⚔️ DUELO · A TURMA VOTA'), findsOneWidget);
      expect(find.text('QUEM É MAIS PROVÁVEL'), findsNothing);
      await rolarAte(tester, find.text('0 de 2 votaram'));
      expect(find.text('Quem mandou melhor?'), findsOneWidget);
      expect(find.byKey(const Key('votar-bia')), findsOneWidget);
      expect(find.byKey(const Key('votar-caio')), findsOneWidget);
      expect(find.byKey(const Key('votar-duda')), findsNothing);

      await tester.tap(find.byKey(const Key('votar-bia')));
      await tester.pumpAndSettle();
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'bia'});
      await fecharApp(tester);
    });

    testWidgets('quem está no duelo não vota: se apresenta', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _duelo(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Você está no duelo! Capricha 🔥'));
      expect(find.byKey(const Key('votar-bia')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('na revelação aparecem os dois com os votos e quem perdeu leva o ponto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duelo(revelacao: {
          'jaFizeram': [],
          'nuncaFizeram': [],
          'votos': [
            {'jogadorId': 'bia', 'votos': 2},
            {'jogadorId': 'caio', 'votos': 0},
          ],
          'perderam': ['caio'],
          'contaAHistoria': null,
          'escolhidos': ['bia'],
        });
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      for (var passo = 0; passo < 8; passo++) {
        await tester.pump(const Duration(seconds: 1));
      }

      await rolarAte(tester, find.byKey(const Key('resultado-do-duelo')));
      expect(find.text('👑 Bia venceu o duelo!'), findsOneWidget);
      expect(find.text('2 votos'), findsOneWidget);
      expect(find.text('0 votos'), findsOneWidget);
      expect(find.text('bebe 🍺'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
