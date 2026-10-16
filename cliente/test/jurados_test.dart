import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _jurados({
  required String euId,
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
          modo: 'Jurados',
          texto: 'De 1 a 5 estrelas: o quanto Caio se veste bem?',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'alvo': 'caio',
      },
    );

Map<String, dynamic> _resultado({required double media, required List<int> notas, bool aprovado = false, bool reprovado = false}) => {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [],
      'perderam': [if (reprovado) 'caio'],
      'contaAHistoria': null,
      'elogio': aprovado,
      'escolhidos': [if (aprovado) 'caio'],
      'media': media,
      'notas': notas,
    };

void main() {
  group('Jurados', () {
    testWidgets('jurado dá a nota em estrelas, em segredo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _jurados(euId: 'bia')
        ..respostas['POST /api/salas/ABCD/respostas'] = _jurados(euId: 'bia', minhaResposta: '4');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('estrela-4')));
      expect(find.byKey(const Key('estrela-1')), findsOneWidget);
      expect(find.byKey(const Key('estrela-5')), findsOneWidget);
      await tester.tap(find.byKey(const Key('estrela-4')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': '4'});
      expect(find.text('Sua nota: ⭐⭐⭐⭐'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem está sendo avaliado só espera', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _jurados(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Os jurados estão te avaliando…'), findsOneWidget);
      expect(find.byKey(const Key('estrela-4')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('a revelação mostra a média e as notas sem dizer quem deu', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] =
            _jurados(euId: 'ana', revelacao: _resultado(media: 4.5, notas: [4, 5], aprovado: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Aprovado(a) pelos jurados! 🏆'));
      expect(find.text('⭐ 4,5'), findsOneWidget);
      expect(find.text('Notas: 4 · 5'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('nota baixa: reprovado(a) leva o ponto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] =
            _jurados(euId: 'ana', revelacao: _resultado(media: 1.5, notas: [1, 2], reprovado: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Reprovado(a) pelos jurados! 😬'));
      expect(find.text('⭐ 1,5'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
