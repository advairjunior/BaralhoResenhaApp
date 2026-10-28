import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

const _frases = ['Já perdi um voo dormindo', 'Já fui para o Japão', 'Já dormi no aeroporto'];

Map<String, dynamic> _duasVerdades({
  String euId = 'ana',
  bool escritas = false,
  int? minhaMentira,
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
          modo: 'DuasVerdades',
          texto: 'Caio: duas verdades e uma mentira sobre viagens.',
          minhaResposta: minhaResposta,
          revelacao: revelacao,
        ),
        'pedeResposta': true,
        'alvo': 'caio',
        'afirmacoes': escritas ? _frases : <String>[],
        'minhaMentira': minhaMentira,
      },
    );

Map<String, dynamic> _revelacao({required bool ninguemAcertou}) => {
      'jaFizeram': [],
      'nuncaFizeram': [],
      'votos': [],
      'perderam': ninguemAcertou ? ['ana', 'bia'] : ['bia'],
      'contaAHistoria': null,
      'escolhidos': ninguemAcertou ? ['caio'] : [],
      'elogio': ninguemAcertou,
      'mentira': 1,
      'votosNasAfirmacoes': ninguemAcertou ? [2, 0, 0] : [1, 1, 0],
      'acertaram': ninguemAcertou ? [] : ['ana'],
    };

void main() {
  group('🤥 Duas verdades e uma mentira', () {
    testWidgets('a pessoa da vez escreve três frases e marca a mentira', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duasVerdades(euId: 'caio')
        ..respostas['POST /api/salas/ABCD/duas-verdades'] =
            _duasVerdades(euId: 'caio', escritas: true, minhaMentira: 1);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      for (final (indice, frase) in _frases.indexed) {
        await rolarAte(tester, find.byKey(Key('afirmacao-escrever-$indice')));
        await tester.enterText(find.byKey(Key('afirmacao-escrever-$indice')), frase);
      }
      await rolarAte(tester, find.byKey(const Key('marcar-mentira-1')));
      await tester.tap(find.byKey(const Key('marcar-mentira-1')));
      await tester.pumpAndSettle();
      await rolarAte(tester, find.text('Mostrar para a turma'));
      await tester.tap(find.text('Mostrar para a turma'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/duas-verdades');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'frases': _frases, 'mentira': 1});
      expect(find.text('A turma está tentando achar a sua mentira…'), findsOneWidget);
      expect(find.text('🤥 Já fui para o Japão'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('sem marcar a mentira, não manda', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _duasVerdades(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      for (final (indice, frase) in _frases.indexed) {
        await rolarAte(tester, find.byKey(Key('afirmacao-escrever-$indice')));
        await tester.enterText(find.byKey(Key('afirmacao-escrever-$indice')), frase);
      }
      await rolarAte(tester, find.text('Mostrar para a turma'));
      await tester.tap(find.text('Mostrar para a turma'));
      await tester.pumpAndSettle();

      expect(servidor.rotas, isNot(contains('POST /api/salas/ABCD/duas-verdades')));
      expect(find.text('Marque qual das três é a mentira.'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('a turma espera as frases e depois vota em qual é a mentira', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duasVerdades()
        ..respostas['POST /api/salas/ABCD/respostas'] = _duasVerdades(escritas: true, minhaResposta: '2');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Caio está escrevendo três frases…'));
      expect(find.byKey(const Key('afirmacao-0')), findsNothing);

      servidor.respostas['GET /api/salas/ABCD'] = _duasVerdades(escritas: true);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      await rolarAte(tester, find.byKey(const Key('afirmacao-2')));
      expect(find.text('Qual é a mentira? Vote em segredo:'), findsOneWidget);
      await tester.tap(find.byKey(const Key('afirmacao-2')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': '2'});
      await fecharApp(tester);
    });

    testWidgets('na revelação a mentira aparece marcada, com os votos', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duasVerdades(escritas: true, revelacao: _revelacao(ninguemAcertou: false));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('revelacao-mentira')));
      expect(find.text('🤥 Já fui para o Japão'), findsOneWidget);
      expect(find.text('Acertou: Ana · Errou e leva 1 ponto: Bia'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('ninguém acertou: a pessoa da vez distribui goles', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _duasVerdades(escritas: true, revelacao: _revelacao(ninguemAcertou: true));
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('revelacao-mentira')));
      expect(find.text('🎭 Ninguém acertou! Caio enganou a turma inteira e distribui goles.'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
