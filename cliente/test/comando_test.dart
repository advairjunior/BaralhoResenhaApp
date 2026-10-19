import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

List<Map<String, dynamic>> _mesa({String comando = 'ana'}) => [
      jogadorJson('ana', 'Ana', anfitriao: comando == 'ana'),
      jogadorJson('bia', 'Bia', anfitriao: comando == 'bia'),
      jogadorJson('caio', 'Caio', anfitriao: comando == 'caio'),
    ];

Map<String, dynamic> _jogo({String euId = 'ana', String comando = 'ana'}) => visaoJson(
      euId: euId,
      souAnfitriao: euId == comando,
      fase: 'Carta',
      jogadores: _mesa(comando: comando),
      rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se você usa óculos.'),
    );

void main() {
  testWidgets('no jogo, quem está no comando passa o comando pelo menu', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _jogo()
      ..respostas['POST /api/salas/ABCD/comando'] = _jogo(comando: 'bia');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passar o comando 👑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bia'));
    await tester.pumpAndSettle();

    final enviada = servidor.recebidas.lastWhere((r) => r.rota == 'POST /api/salas/ABCD/comando');
    expect(enviada.corpo, {'jogadorId': 'bia'});
    expect(find.text('Esperando Bia puxar a próxima carta 🃏'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('quem não está no comando não vê "Passar o comando"', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _jogo(euId: 'bia');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Passar o comando 👑'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('na sala de espera, quem criou a sala passa o comando', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(jogadores: _mesa())
      ..respostas['POST /api/salas/ABCD/comando'] = visaoJson(souAnfitriao: false, jogadores: _mesa(comando: 'caio'));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.byKey(const Key('passar-comando')));
    await tester.tap(find.byKey(const Key('passar-comando')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caio').last);
    await tester.pumpAndSettle();

    final enviada = servidor.recebidas.lastWhere((r) => r.rota == 'POST /api/salas/ABCD/comando');
    expect(enviada.corpo, {'jogadorId': 'caio'});
    await fecharApp(tester);
  });

  testWidgets('quando o comando chega sozinho, o celular avisa', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _jogo(euId: 'bia');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    // O celular da Ana sumiu: na consulta seguinte, a Bia está no comando.
    servidor.respostas['GET /api/salas/ABCD'] = _jogo(euId: 'bia', comando: 'bia');
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Agora você está no comando 👑 Você puxa as cartas.'), findsOneWidget);
    await fecharApp(tester);
  });
}
