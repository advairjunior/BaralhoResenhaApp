import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

/// Roda de Música: a ordem é Bia, Caio, Ana.
Map<String, dynamic> _roda({required String euId, String? daVez, List<String> travaram = const []}) => visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'Musica', texto: 'Abertura de novela! Bia começa e cada um canta uma diferente.'),
        'fila': ['bia', 'caio', 'ana'],
        'travaram': travaram,
        'pendentes': [
          if (daVez != null) {'jogadorId': daVez, 'motivo': 'Cantar'},
        ],
      },
    );

void main() {
  group('Roda de Música', () {
    testWidgets('quem está na vez canta e toca em Cantei', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _roda(euId: 'bia', daVez: 'bia')
        ..respostas['POST /api/salas/ABCD/pronto'] = _roda(euId: 'bia', daVez: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('🎤 Vez de Bia cantar!'), findsOneWidget);
      expect(find.text('1 de 3'), findsOneWidget);
      await rolarAte(tester, find.text('🎤 Cantei'));
      await tester.tap(find.text('🎤 Cantei'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/pronto');
      expect(find.text('🎤 Vez de Caio cantar!'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala marca que travou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _roda(euId: 'ana', daVez: 'caio')
        ..respostas['POST /api/salas/ABCD/travou'] = _roda(euId: 'ana', daVez: 'ana', travaram: ['caio']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('😵 Travou'));
      await tester.tap(find.text('😵 Travou'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'jogadorId': 'caio'});
      expect(find.text('😵 Travou: Caio'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quando a roda fecha, avisa', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _roda(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('A roda fechou! 🎶'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
