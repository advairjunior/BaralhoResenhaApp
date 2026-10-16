import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio', respondeu: true),
];

Map<String, dynamic> _jokenpo({
  String euId = 'bia',
  String? minhaResposta,
  List<String> empates = const [],
  Map<String, dynamic>? revelacao,
}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'MaisProvavel',
          texto: 'Pedra, papel e tesoura: Bia contra Caio. Escolham no celular, em segredo!',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'votacao': true,
        'duelistas': ['bia', 'caio'],
        'jokenpo': true,
        'empates': empates,
      },
    );

void main() {
  group('Pedra, papel e tesoura', () {
    testWidgets('quem está no duelo escolhe em segredo no celular', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _jokenpo()
        ..respostas['POST /api/salas/ABCD/respostas'] = _jokenpo(minhaResposta: 'pedra');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('✊✋✌️ PEDRA, PAPEL E TESOURA'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('jogar-pedra')));
      await tester.tap(find.byKey(const Key('jogar-pedra')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'pedra'});
      expect(find.text('Escolhido! Caio já jogou também.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a turma só torce e vê o empate', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _jokenpo(euId: 'ana', empates: ['tesoura']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Torce aí! 📣'));
      expect(find.byKey(const Key('jogar-pedra')), findsNothing);
      expect(find.text('Deu empate (✌️ x ✌️)! Joguem de novo.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('na revelação aparecem as duas mãos e quem venceu', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _jokenpo(euId: 'ana', revelacao: {
          'jaFizeram': [],
          'nuncaFizeram': [],
          'votos': [],
          'perderam': ['bia'],
          'contaAHistoria': null,
          'escolhidos': ['caio'],
          'jogadas': {'bia': 'pedra', 'caio': 'papel'},
        });
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
      for (var passo = 0; passo < 8; passo++) {
        await tester.pump(const Duration(seconds: 1));
      }

      await rolarAte(tester, find.byKey(const Key('resultado-do-jokenpo')));
      expect(find.text('👑 Caio venceu!'), findsOneWidget);
      expect(find.text('✊'), findsOneWidget);
      expect(find.text('✋'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
