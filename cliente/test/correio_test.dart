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

Map<String, dynamic> _correio({String euId = 'bia', String? minhaResposta, Map<String, dynamic>? revelacao, int? favorito}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'Correio',
          texto: 'O apelido de Caio num reality show.',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'alvo': 'caio',
        'favorito': favorito,
      },
    );

const _bilhetes = {
  'jaFizeram': [],
  'nuncaFizeram': [],
  'votos': [],
  'perderam': [],
  'contaAHistoria': null,
  'escolhidos': ['caio'],
  'bilhetes': ['Tio do pavê', 'Rei do churrasco', 'Sumido'],
};

void main() {
  group('Correio da Resenha', () {
    testWidgets('quem escreve vê a foto, sabe que é anônimo e manda um bilhete curto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _correio()
        ..respostas['POST /api/salas/ABCD/respostas'] = _correio(minhaResposta: 'Tio do pavê');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('📮 BILHETE ANÔNIMO'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('bilhete')));
      expect(find.textContaining('Anônimo de verdade'), findsOneWidget);
      expect(find.byKey(const Key('foto-do-correio')), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('bilhete'))).maxLength, 20);

      await tester.enterText(find.byKey(const Key('bilhete')), 'Tio do pavê');
      await rolarAte(tester, find.text('Enviar bilhete'));
      await tester.tap(find.text('Enviar bilhete'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'Tio do pavê'});
      await fecharApp(tester);
    });

    testWidgets('quem está na foto fica de fora e só espera', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _correio(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Você está de fora desta rodada 🤫'), findsOneWidget);
      expect(find.text('O apelido de Caio num reality show.'), findsNothing);
      expect(find.byKey(const Key('bilhete')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('na revelação todo mundo lê os bilhetes e quem está na foto escolhe o favorito', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _correio(euId: 'caio', revelacao: _bilhetes)
        ..respostas['POST /api/salas/ABCD/favorito'] =
            _correio(euId: 'caio', revelacao: _bilhetes, favorito: 1);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Sumido'));
      expect(find.text('Tio do pavê'), findsOneWidget);
      expect(find.text('Rei do churrasco'), findsOneWidget);
      expect(find.text('📮 Correio para Caio'), findsOneWidget);

      await tester.tap(find.text('Rei do churrasco'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/favorito');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'indice': 1});
      expect(find.text('⭐ Favorito de Caio'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
