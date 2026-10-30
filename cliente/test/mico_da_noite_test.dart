import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

const _micos = [
  'Cante o refrão de uma música escolhida pela turma.',
  'Dance sem música por 20 segundos.',
  'Faça um discurso de Oscar para a turma.',
];

Map<String, dynamic> _fim({String euId = 'ana', int? meuVoto, int? escolhido, List<int> votos = const []}) => {
      ...visaoJson(
        fase: 'Fim',
        euId: euId,
        souAnfitriao: euId == 'ana',
        semAlcool: true,
        jogadores: [
          jogadorJson('ana', 'Ana', anfitriao: true, pontos: 2),
          jogadorJson('bia', 'Bia', pontos: 9, goles: 3),
          jogadorJson('caio', 'Caio', pontos: 4),
        ],
      ),
      'momentos': [],
      'premios': [],
      'resumo': {'cartas': 30, 'minutos': 60, 'goles': 5, 'pontos': 0},
      'mico': {
        'pagadores': ['bia'],
        'opcoes': _micos,
        'votaram': meuVoto == null ? 0 : 1,
        'eleitores': 2,
        'meuVoto': meuVoto,
        'escolhido': escolhido,
        'votos': votos,
      },
    };

void main() {
  group('🤡 Mico da noite', () {
    testWidgets('a turma vota em qual mico quem mais pontuou vai pagar', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _fim()
        ..respostas['POST /api/salas/ABCD/mico'] = _fim(meuVoto: 1);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('mico-da-noite')));
      expect(find.text('🤡 Mico da noite'), findsOneWidget);
      expect(find.text('Bia fechou a noite com mais pontos e paga um mico. Vote em qual:'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mico-1')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/mico');
      expect(servidor.recebidas.last.corpo, {'opcao': 1});
      expect(find.text('Votaram 1 de 2'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem paga só espera a turma escolher', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _fim(euId: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('mico-da-noite')));
      expect(find.text('Você fechou a noite com mais pontos. A turma está escolhendo o seu mico…'), findsOneWidget);
      expect(find.byKey(const Key('mico-0')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('escolhido, o mico aparece grande para todo mundo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _fim(meuVoto: 1, escolhido: 1, votos: [0, 2, 0]);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('mico-escolhido')));
      expect(find.text('Bia paga:'), findsOneWidget);
      expect(find.text('Dance sem música por 20 segundos.'), findsOneWidget);
      expect(find.text('2 votos'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('na sala sem álcool o resumo conta prendas', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _fim();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('prendas'), findsOneWidget);
      expect(find.text('goles'), findsNothing);
      await fecharApp(tester);
    });
  });
}
