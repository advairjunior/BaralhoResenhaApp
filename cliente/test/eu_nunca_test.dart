import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _revelada(List<String> ja, List<String> nunca, List<String> perderam, {bool minoriaLeva = false}) =>
    visaoJson(
      fase: 'Revelada',
      jogadores: _mesa,
      rodada: rodadaJson(revelacao: {
        'jaFizeram': ja,
        'nuncaFizeram': nunca,
        'votos': [],
        'perderam': perderam,
        'contaAHistoria': null,
        'minoriaLeva': minoriaLeva,
      }),
    );

void main() {
  group('Eu Nunca com virada', () {
    testWidgets('se a maioria já fez, quem nunca fez leva', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada(['ana', 'bia'], ['caio'], ['caio'], minoriaLeva: true);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Virou! A maioria já fez, então leva quem nunca fez 😇'));
      expect(find.text('Caio'), findsWidgets);
      await fecharApp(tester);
    });

    testWidgets('se todo mundo já fez, ninguém leva', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _revelada(['ana', 'bia', 'caio'], [], []);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Todo mundo já fez! Ninguém leva ponto 🙈'));
      await fecharApp(tester);
    });
  });
}
