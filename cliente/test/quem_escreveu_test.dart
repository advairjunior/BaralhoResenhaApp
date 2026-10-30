import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

const _respostas = ['Formiga', 'Jacaré', 'Escargot'];

Map<String, dynamic> _carta({
  bool escrevendo = false,
  String? minhaResposta,
  Map<String, dynamic>? revelacao,
}) =>
    visaoJson(
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      modos: ['QuemEscreveu'],
      rodada: {
        ...rodadaJson(
          modo: 'QuemEscreveu',
          texto: 'A comida mais estranha que você já comeu',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'escrevendo': escrevendo,
        'frases': escrevendo ? [] : _respostas,
        'minhaFrase': escrevendo ? null : 2,
        'fraseEmJogo': escrevendo ? null : 1,
      },
    );

Map<String, dynamic> _revelacao({required List<String> acertaram, required List<String> erraram, bool escapou = false}) =>
    {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [],
      'perderam': erraram,
      'contaAHistoria': null,
      'escolhidos': escapou ? ['caio'] : [],
      'elogio': escapou,
      'acertaram': acertaram,
      'frases': [
        {'texto': 'Formiga', 'votos': 0, 'autor': null},
        {'texto': 'Jacaré', 'votos': 0, 'autor': 'caio'},
        {'texto': 'Escargot', 'votos': 0, 'autor': null},
      ],
    };

void main() {
  group('✍️ Quem escreveu?', () {
    testWidgets('cada um responde em segredo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta(escrevendo: true)
        ..respostas['POST /api/salas/ABCD/respostas'] = _carta(escrevendo: true, minhaResposta: 'Escargot');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('frase')));
      expect(find.text('Responda em segredo:'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('frase')), 'Escargot');
      await tester.tap(find.text('Enviar resposta'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'Escargot'});
      expect(find.text('Sua resposta: "Escargot" ✓'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('uma resposta vai para o centro e cada um vota em quem escreveu', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta()
        ..respostas['POST /api/salas/ABCD/respostas'] = _carta(minhaResposta: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('frase-em-jogo')));
      expect(find.text('De quem é esta?'), findsOneWidget);
      expect(find.text('"Jacaré"'), findsOneWidget);
      expect(find.byKey(const Key('votar-ana')), findsNothing);
      await rolarAte(tester, find.byKey(const Key('votar-caio')));
      await tester.tap(find.byKey(const Key('votar-caio')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'caio'});
      await fecharApp(tester);
    });

    testWidgets('na revelação, quem errou leva ponto', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta(revelacao: _revelacao(acertaram: ['bia'], erraram: ['ana']));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('quem-escreveu')));
      expect(find.text('Quem escreveu: Caio'), findsOneWidget);
      expect(find.text('Acertou: Bia'), findsOneWidget);
      expect(find.text('Errou e leva 1 ponto: Ana'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('ninguém descobriu: quem escreveu escapou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] =
            _carta(revelacao: _revelacao(acertaram: [], erraram: ['ana', 'bia'], escapou: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('quem-escreveu')));
      expect(find.text('🕵️ Ninguém descobriu! Caio escapou: ganha uma carta na manga e distribui goles.'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
