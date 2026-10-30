import 'package:baralho_resenha_app/infraestrutura/som.dart';
import 'package:baralho_resenha_app/infraestrutura/tocador_de_som.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _batata({required String comABatata, Map<String, dynamic>? revelacao}) => visaoJson(
      euId: 'ana',
      souAnfitriao: true,
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'BatataQuente', texto: 'Marcas de cerveja', revelacao: revelacao),
        'pedeResposta': false,
        'fila': ['ana', 'bia', 'caio'],
        'comABatata': comABatata,
      },
    );

const _estourouNaBia = {
  'jaFizeram': [],
  'nuncaFizeram': [],
  'votos': [],
  'perderam': ['bia'],
  'contaAHistoria': null,
};

void main() {
  setUp(sonsTocados.clear);

  group('🥔 Batata quente', () {
    testWidgets('quem está com a batata fala e toca em Falei para passar', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _batata(comABatata: 'ana')
        ..respostas['POST /api/salas/ABCD/batata'] = _batata(comABatata: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('passar-batata')));
      expect(find.text('A batata está com você! Fale uma e passe.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('passar-batata')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/batata');
      expect(servidor.recebidas.last.corpo, {'rodada': 1});
      expect(find.byKey(const Key('passar-batata')), findsNothing);
      expect(find.text('A batata está com Bia'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a turma vê com quem está a batata e quem vem depois', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _batata(comABatata: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('A batata está com Bia'));
      expect(find.text('Depois: Caio'), findsOneWidget);
      expect(find.byKey(const Key('passar-batata')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('quando estoura, todo mundo vê na mão de quem e ouve o estouro', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _batata(comABatata: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      servidor.respostas['GET /api/salas/ABCD'] = _batata(comABatata: 'bia', revelacao: _estourouNaBia);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      await rolarAte(tester, find.byKey(const Key('batata-estourou')));
      expect(find.text('💥 Estourou na mão de Bia!'), findsOneWidget);
      expect(find.text('Bia leva 1 ponto.'), findsOneWidget);
      expect(sonsTocados, [Som.estouro]);
      await fecharApp(tester);
    });
  });
}
