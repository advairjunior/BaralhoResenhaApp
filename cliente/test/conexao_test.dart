import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk-ana'};

Map<String, dynamic> _comCaioSemConexao({bool souAnfitriao = true}) => visaoJson(
  fase: 'Carta',
  souAnfitriao: souAnfitriao,
  rodada: rodadaJson(),
  jogadores: [
    jogadorJson('ana', 'Ana', anfitriao: true),
    jogadorJson('bia', 'Bia'),
    jogadorJson('caio', 'Caio', conectado: false),
  ],
);

void main() {
  testWidgets('o placar mostra quem ficou sem conexão', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comCaioSemConexao();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byTooltip('Placar'));
    await tester.pumpAndSettle();

    expect(find.text('📵 Sem conexão'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('quem criou a sala tira quem caiu, com confirmação', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _comCaioSemConexao()
      ..respostas['DELETE /api/salas/ABCD/jogadores/caio'] = visaoJson(fase: 'Carta', rodada: rodadaJson());
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byTooltip('Placar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar da sala'));
    await tester.pumpAndSettle();
    expect(find.text('Tirar Caio da sala?'), findsOneWidget);
    await tester.tap(find.text('Tirar'));
    await tester.pumpAndSettle();

    expect(servidor.rotas, contains('DELETE /api/salas/ABCD/jogadores/caio'));
    await fecharApp(tester);
  });

  testWidgets('só quem criou a sala vê o botão de tirar', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comCaioSemConexao(souAnfitriao: false);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byTooltip('Placar'));
    await tester.pumpAndSettle();

    expect(find.text('📵 Sem conexão'), findsOneWidget);
    expect(find.text('Tirar da sala'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('sem internet, o celular avisa que está tentando voltar e some ao voltar', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson(fase: 'Carta', rodada: rodadaJson());
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    expect(find.text('Sem conexão, tentando voltar…'), findsNothing);

    final resposta = servidor.respostas['GET /api/salas/ABCD']!;
    servidor.respostas['GET /api/salas/ABCD'] = Exception('caiu a internet');
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.text('Sem conexão, tentando voltar…'), findsOneWidget);
    // Continua na sala: falta de internet não é perder a sala.
    expect(find.text('Eu nunca dormi no sofá depois de uma briga.'), findsOneWidget);

    servidor.respostas['GET /api/salas/ABCD'] = resposta;
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.text('Sem conexão, tentando voltar…'), findsNothing);
    await fecharApp(tester);
  });
}
