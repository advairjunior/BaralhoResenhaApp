import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _carta({String? minhaResposta, Map<String, dynamic>? revelacao}) => visaoJson(
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      modos: ['IssoOuAquilo'],
      rodada: {
        ...rodadaJson(modo: 'IssoOuAquilo', texto: 'Férias: praia ou montanha?', minhaResposta: minhaResposta, revelacao: revelacao),
        'pedeResposta': true,
        'opcoes': ['Praia', 'Montanha'],
      },
    );

Map<String, dynamic> _revelacao({required List<String> praia, required List<String> montanha, List<String> perderam = const []}) => {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [],
      'perderam': perderam,
      'contaAHistoria': null,
      'lados': [praia, montanha],
    };

void main() {
  group('⚖️ Isso ou aquilo', () {
    testWidgets('cada um escolhe uma das duas em segredo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta()
        ..respostas['POST /api/salas/ABCD/respostas'] = _carta(minhaResposta: '1');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('opcao-1')));
      expect(find.text('Escolha em segredo:'), findsOneWidget);
      expect(find.text('Praia'), findsOneWidget);
      await tester.tap(find.byKey(const Key('opcao-1')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': '1'});
      expect(find.text('0 de 3 escolheram'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('na revelação, quem ficou na minoria leva ponto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] =
            _carta(revelacao: _revelacao(praia: ['ana', 'bia'], montanha: ['caio'], perderam: ['caio']));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('lados')));
      expect(find.text('Praia · 2'), findsOneWidget);
      expect(find.text('Montanha · 1'), findsOneWidget);
      expect(find.text('Ficou na minoria: Caio leva 1 ponto'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('empate ou todo mundo igual, ninguém leva', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta(revelacao: _revelacao(praia: ['ana', 'bia', 'caio'], montanha: []));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('lados')));
      expect(find.text('Todo mundo do mesmo lado: ninguém leva.'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
