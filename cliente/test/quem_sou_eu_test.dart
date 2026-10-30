import 'package:baralho_resenha_app/dominio/modelos.dart';
import 'package:baralho_resenha_app/infraestrutura/voz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [jogadorJson('ana', 'Ana', anfitriao: true), jogadorJson('bia', 'Bia'), jogadorJson('caio', 'Caio')];

/// A Bia é a da vez: o servidor manda o segredo para todo mundo, menos para ela.
Map<String, dynamic> _carta({String euId = 'ana', Map<String, dynamic>? revelacao}) => visaoJson(
  euId: euId,
  souAnfitriao: euId == 'ana',
  fase: revelacao == null ? 'Carta' : 'Revelada',
  jogadores: _mesa,
  modos: ['QuemSouEu'],
  rodada: {
    ...rodadaJson(
      modo: 'QuemSouEu',
      texto: euId == 'bia' && revelacao == null ? '🙈 Quem é você?' : 'Geladeira',
      revelacao: revelacao,
    ),
    'pedeResposta': false,
    'alvo': 'bia',
    'dica': 'Objeto',
    'cronometroSegundos': 90,
  },
);

Map<String, dynamic> _resultado({required bool acertou}) => {
  'jaFizeram': [],
  'nuncaFizeram': [],
  'votos': [],
  'perderam': acertou ? [] : ['bia'],
  'contaAHistoria': null,
  'escolhidos': acertou ? ['bia'] : [],
};

void main() {
  group('🙈 Quem sou eu?', () {
    testWidgets('a pessoa da vez só sabe a categoria e ganha ideias de pergunta', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta(euId: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('quem-sou-eu')));
      expect(find.text('Você é: Objeto'), findsOneWidget);
      expect(find.textContaining('Geladeira'), findsNothing);
      expect(find.text('Dá para comer?'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a turma vê o segredo e só responde sim ou não', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('quem-sou-eu')));
      expect(find.text('Bia é: Geladeira'), findsOneWidget);
      expect(find.text('🤫 Só responda sim ou não. Não vale dar dica!'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala marca se acertou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta()
        ..respostas['POST /api/salas/ABCD/quem-sou-eu'] = _carta(revelacao: _resultado(acertou: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('✅ Acertou!'));
      await tester.tap(find.text('✅ Acertou!'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'acertou': true});
      await rolarAte(tester, find.byKey(const Key('resultado-quem-sou-eu')));
      expect(find.text('🎉 Bia acertou! Ganhou uma carta na manga.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('o tempo acabou: a pessoa da vez leva ponto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta(revelacao: _resultado(acertou: false));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('resultado-quem-sou-eu')));
      expect(find.text('Era: Geladeira'), findsOneWidget);
      expect(find.text('⏰ Não deu tempo! Bia leva 1 ponto.'), findsOneWidget);
      await fecharApp(tester);
    });

    test('a voz não lê o segredo, só chama a pessoa da vez', () {
      final fala = falaDaCarta(VisaoDaSala.deJson(_carta()));

      expect(fala, endsWith('Quem sou eu? Bia, descubra quem você é! Só vale pergunta de sim ou não.'));
      expect(fala, isNot(contains('Geladeira')));
    });
  });
}
