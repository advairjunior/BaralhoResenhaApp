import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

/// Eu Nunca "conta essa" revelado: Bia e Caio já fizeram e contam nessa ordem.
Map<String, dynamic> _revelada({required String euId, String? daVez}) => visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(
          texto: 'Eu nunca gritei dormindo.',
          revelacao: {
            'jaFizeram': ['bia', 'caio'],
            'nuncaFizeram': ['ana'],
            'votos': [],
            'perderam': ['ana'],
            'contaAHistoria': null,
            'minoriaLeva': true,
            'contadores': ['bia', 'caio'],
          },
        ),
        'pendentes': [
          if (daVez != null) {'jogadorId': daVez, 'motivo': 'Historia'},
        ],
      },
    );

void main() {
  group('Conta essa', () {
    testWidgets('quem está na vez vê a própria foto e toca em Contei', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada(euId: 'bia', daVez: 'bia')
        ..respostas['POST /api/salas/ABCD/pronto'] = _revelada(euId: 'bia', daVez: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('🎤 Conta essa, Bia!'), findsOneWidget);
      expect(find.text('1 de 2'), findsOneWidget);
      await rolarAte(tester, find.text('🎤 Contei'));
      expect(find.text('🎤 Contei'), findsOneWidget);
      await tester.tap(find.text('🎤 Contei'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(find.text('🎤 Conta essa, Caio!'), findsOneWidget);
      expect(find.text('2 de 2'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala passa a vez de quem contou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _revelada(euId: 'ana', daVez: 'caio')
        ..respostas['POST /api/salas/ABCD/contou'] = _revelada(euId: 'ana');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Caio contou ✓'));
      await tester.tap(find.text('Caio contou ✓'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'jogadorId': 'caio'});
      expect(find.text('Todo mundo contou! 🎉'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem não está na vez espera', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _revelada(euId: 'caio', daVez: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Esperando Bia contar…'), findsOneWidget);
      expect(find.text('🎤 Contei'), findsNothing);
      await fecharApp(tester);
    });
  });
}
