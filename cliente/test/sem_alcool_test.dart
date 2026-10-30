import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

/// Eu Nunca revelado: só a Bia fez e o cofrinho dela encheu.
Map<String, dynamic> _biaPagaPrenda({
  String euId = 'ana',
  List<Map<String, String>> pendentes = const [],
  String ritmo = 'Devagar',
}) =>
    visaoJson(
      fase: 'Revelada',
      euId: euId,
      souAnfitriao: euId == 'ana',
      ritmo: ritmo,
      semAlcool: true,
      jogadores: [
        jogadorJson('ana', 'Ana', anfitriao: true, pontos: 2, cofrinho: 2),
        jogadorJson('bia', 'Bia', pontos: 7, goles: 1),
      ],
      rodada: {
        ...rodadaJson(bebemAgora: ['bia'], revelacao: {
          'jaFizeram': ['bia'],
          'nuncaFizeram': ['ana'],
          'votos': [],
          'perderam': ['bia'],
          'contaAHistoria': 'bia',
        }),
        'prendas': {
          'bia': ['Imite alguém da mesa até a turma adivinhar quem é.'],
        },
        'pendentes': pendentes,
      },
    );

void main() {
  group('🧃 Sala sem álcool', () {
    testWidgets('quem criou a sala liga o "sem álcool" e o ritmo vira de prendas', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(ritmo: 'Devagar')
        ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson(ritmo: 'Devagar', semAlcool: true);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('sala-sem-alcool')));
      await tester.tap(find.byKey(const Key('sala-sem-alcool')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo!['semAlcool'], true);
      await rolarAte(tester, find.byKey(const Key('ritmo-normal')));
      expect(find.text('1 prenda a cada 7 pontos'), findsOneWidget);
      expect(find.text('1 gole a cada 7 pontos'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('cofrinho cheio mostra a prenda de quem paga, sem falar em gole', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _biaPagaPrenda();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Só Bia fez · paga prenda 🎟️'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('hora-da-prenda')));
      expect(find.text('🎟️ Prenda para Bia'), findsOneWidget);
      expect(find.text('Imite alguém da mesa até a turma adivinhar quem é.'), findsOneWidget);
      // O 🍺 do nível Resenha e do Eu Nunca é o desenho da carta; o que some é a ordem de beber.
      expect(find.textContaining('bebe'), findsNothing);
      expect(find.textContaining('gole'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('no Raiz a prenda também aparece, porque cada uma é diferente', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _biaPagaPrenda(ritmo: 'Raiz');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('hora-da-prenda')));
      expect(find.text('Imite alguém da mesa até a turma adivinhar quem é.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem paga confirma com "Paguei" e a mesa espera a prenda', (tester) async {
      const pendentes = [
        {'jogadorId': 'bia', 'motivo': 'Beber'},
      ];
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _biaPagaPrenda(euId: 'bia', pendentes: pendentes);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
      await rolarAte(tester, find.text('🎟️ Paguei ✓'));
      expect(find.text('🎟️ Paguei ✓'), findsOneWidget);
      await fecharApp(tester);

      final daAna = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _biaPagaPrenda(pendentes: pendentes);
      await abrirApp(tester, daAna, rota: '/sala/ABCD', guardado: _logado);
      await rolarAte(tester, find.text('Esperando: Bia pagar a prenda 🎟️'));
      expect(find.text('Esperando: Bia pagar a prenda 🎟️'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('o placar conta prendas', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _biaPagaPrenda();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byTooltip('Placar'));
      await tester.pumpAndSettle();

      expect(find.text('1 prenda'), findsOneWidget);
      expect(find.text('2 pontos · cofrinho 2/7'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('no Chuta aí, quem chegou mais perto passa uma prenda', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(
          fase: 'Revelada',
          semAlcool: true,
          jogadores: [
            jogadorJson('ana', 'Ana', anfitriao: true),
            jogadorJson('bia', 'Bia'),
            jogadorJson('caio', 'Caio'),
          ],
          rodada: {
            ...rodadaJson(modo: 'ChutaAi', texto: 'Quantos quilômetros tem uma maratona?', revelacao: {
              'jaFizeram': [],
              'nuncaFizeram': [],
              'votos': [],
              'perderam': ['caio'],
              'contaAHistoria': null,
              'escolhidos': ['bia'],
              'elogio': true,
              'respostaCerta': 42.195,
              'chutes': [
                {'jogadorId': 'bia', 'valor': 40},
                {'jogadorId': 'ana', 'valor': 30},
                {'jogadorId': 'caio', 'valor': 100},
              ],
            }),
            'pedeResposta': true,
            'prendaParaDar': 'Fale só rimando até a próxima carta.',
          },
        );
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('prenda-para-dar')));
      expect(find.text('💛 Bia escolhe quem paga esta prenda'), findsOneWidget);
      expect(find.text('Fale só rimando até a próxima carta.'), findsOneWidget);
      expect(find.textContaining('goles'), findsNothing);
      await fecharApp(tester);
    });
  });
}
