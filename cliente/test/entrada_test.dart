import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('criar sala guarda o token e abre a sala de espera', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['POST /api/salas'] = {'codigo': 'ABCD', 'token': 'tk-ana'}
      ..respostas['GET /api/salas/ABCD'] = visaoJson(jogadores: [jogadorJson('ana', 'Ana', anfitriao: true)]);
    await abrirApp(tester, servidor);

    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.tap(find.text('Vou jogar sem álcool 🥤'));
    await tester.tap(find.text('Criar uma sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar sem foto'));
    await tester.pumpAndSettle();

    expect(servidor.recebidas.first.corpo, {'nome': 'Ana', 'semAlcool': true});
    expect(find.text('Sala de espera'), findsOneWidget);
    expect(find.text('ABCD'), findsOneWidget);
    await rolarAte(tester, find.text('Esperando a turma entrar…'));
    expect(find.text('Esperando a turma entrar…'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('sem nome não cria a sala', (tester) async {
    final servidor = ServidorFalso();
    await abrirApp(tester, servidor);

    await tester.tap(find.text('Criar uma sala'));
    await tester.pump();

    expect(servidor.recebidas, isEmpty);
    expect(find.text('Conta pra gente o seu nome.'), findsOneWidget);
  });

  testWidgets('link da sala sem token mostra o código preenchido para entrar', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['POST /api/salas/ABCD/jogadores'] = {'codigo': 'ABCD', 'token': 'tk-bia'}
      ..respostas['GET /api/salas/ABCD'] = visaoJson(euId: 'bia', souAnfitriao: false);
    await abrirApp(tester, servidor, rota: '/sala/abcd');

    expect(find.text('Criar uma sala'), findsNothing);
    final campo = tester.widget<TextField>(find.byKey(const Key('campo-codigo')));
    expect(campo.controller!.text, 'ABCD');

    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Bia');
    await tester.tap(find.text('Entrar na sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar sem foto'));
    await tester.pumpAndSettle();

    expect(servidor.rotas, contains('POST /api/salas/ABCD/jogadores'));
    await rolarAte(tester, find.text('Esperando Ana começar…'));
    expect(find.text('Esperando Ana começar…'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('token guardado de sala que acabou volta para a entrada', (tester) async {
    final servidor = ServidorFalso();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: {'sala_ABCD': 'tk-velho'});

    expect(find.text('Entrar na sala'), findsOneWidget);
    await fecharApp(tester);
  });
}
