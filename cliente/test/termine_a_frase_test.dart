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

const _frases = ['na fila do INSS', 'no velório', 'no churrasco da sogra'];

Map<String, dynamic> _termine({
  bool escrevendo = true,
  String? minhaResposta,
  int? minhaFrase,
  Map<String, dynamic>? revelacao,
}) =>
    visaoJson(
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          modo: 'TermineAFrase',
          texto: 'O pior lugar para um primeiro encontro é…',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'escrevendo': escrevendo && revelacao == null,
        'frases': escrevendo ? <String>[] : _frases,
        'minhaFrase': minhaFrase,
      },
    );

final _revelacao = {
  'jaFizeram': [],
  'nuncaFizeram': [],
  'votos': [],
  'perderam': [],
  'contaAHistoria': null,
  'escolhidos': ['caio'],
  'elogio': true,
  'frases': [
    {'texto': 'no churrasco da sogra', 'votos': 3, 'autor': 'caio'},
    {'texto': 'no velório', 'votos': 1, 'autor': null},
    {'texto': 'na fila do INSS', 'votos': 0, 'autor': null},
  ],
};

void main() {
  group('✍️ Termine a frase', () {
    testWidgets('cada um completa a frase em segredo, com até 40 letras', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _termine()
        ..respostas['POST /api/salas/ABCD/respostas'] = _termine(minhaResposta: 'no velório');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('O pior lugar para um primeiro encontro é…'), findsOneWidget);
      await rolarAte(tester, find.byKey(const Key('frase')));
      expect(tester.widget<TextField>(find.byKey(const Key('frase'))).maxLength, 40);
      await tester.enterText(find.byKey(const Key('frase')), 'no velório');
      await tester.tap(find.text('Enviar frase'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'no velório'});
      expect(find.text('Sua frase: "no velório" ✓'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('na votação as frases aparecem sem autor e a sua não dá para votar', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _termine(escrevendo: false, minhaFrase: 1)
        ..respostas['POST /api/salas/ABCD/respostas'] =
            _termine(escrevendo: false, minhaFrase: 1, minhaResposta: '2');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('frase-2')));
      expect(find.text('Vote em segredo na melhor:'), findsOneWidget);
      expect(find.text('no velório · a sua'), findsOneWidget);
      await tester.tap(find.byKey(const Key('frase-1')));
      await tester.pumpAndSettle();
      expect(servidor.rotas, isNot(contains('POST /api/salas/ABCD/respostas')));

      await tester.tap(find.byKey(const Key('frase-2')));
      await tester.pumpAndSettle();
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': '2'});
      await fecharApp(tester);
    });

    testWidgets('na revelação só a vencedora mostra quem escreveu', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _termine(escrevendo: false, revelacao: _revelacao);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.byKey(const Key('frase-vencedora')), findsOneWidget);
      expect(find.text('no churrasco da sogra'), findsOneWidget);
      expect(find.text('✍️ Caio escreveu a melhor e distribui goles!'), findsOneWidget);
      expect(find.text('no velório'), findsOneWidget);
      expect(find.text('3 votos'), findsOneWidget);
      expect(find.text('1 voto'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
