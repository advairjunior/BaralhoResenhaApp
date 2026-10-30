import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _chutaAi({String? minhaResposta, Map<String, dynamic>? revelacao, List<String> ganharam = const []}) =>
    visaoJson(
      euId: 'ana',
      souAnfitriao: true,
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'ChutaAi',
          texto: 'Quantos quilômetros tem uma maratona?',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'ganharam': ganharam,
      },
    );

Map<String, dynamic> _revelacao({bool naMosca = false}) => {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [],
      'perderam': ['caio'],
      'contaAHistoria': null,
      'escolhidos': ['bia'],
      'elogio': true,
      'respostaCerta': 42.195,
      'chutes': [
        {'jogadorId': 'bia', 'valor': naMosca ? 42.195 : 40},
        {'jogadorId': 'ana', 'valor': 30},
        {'jogadorId': 'caio', 'valor': 100},
      ],
    };

void main() {
  group('🎯 Chuta aí', () {
    testWidgets('cada um chuta um número em segredo, com vírgula do teclado', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _chutaAi()
        ..respostas['POST /api/salas/ABCD/respostas'] = _chutaAi(minhaResposta: '42.195');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('chute')));
      expect(find.text('Chute em segredo:'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('chute')), '42,195');
      await rolarAte(tester, find.text('Chutar'));
      await tester.tap(find.text('Chutar'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/respostas');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': '42.195'});
      expect(find.text('Seu chute: 42,195'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('sem número, não manda', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _chutaAi();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Chutar'));
      await tester.tap(find.text('Chutar'));
      await tester.pumpAndSettle();

      expect(servidor.rotas, isNot(contains('POST /api/salas/ABCD/respostas')));
      expect(find.text('Chute um número.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('na revelação aparecem a resposta certa e os chutes, do mais perto ao mais longe', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _chutaAi(revelacao: _revelacao());
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('revelacao-chutes')));
      expect(find.text('42,195'), findsOneWidget);
      expect(find.text('Bia'), findsWidgets);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Mais perto: Bia distribui goles · Mais longe: Caio leva 1 ponto'), findsOneWidget);
      expect(find.textContaining('Na mosca'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('quem acerta na mosca ganha destaque', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _chutaAi(revelacao: _revelacao(naMosca: true), ganharam: ['bia']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('revelacao-chutes')));
      expect(find.text('🎯 Na mosca! Bia ganhou uma carta na manga.'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
