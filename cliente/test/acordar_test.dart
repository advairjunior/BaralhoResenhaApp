import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _aviso = '☕ Acordando o baralho… Na primeira sala da noite o servidor leva até 1 minuto para acordar.';

void main() {
  testWidgets('abrir o app já acorda o servidor enquanto a pessoa digita o nome', (tester) async {
    final servidor = ServidorFalso();
    await abrirApp(tester, servidor);

    expect(servidor.acordou, 1);
  });

  testWidgets('criar a sala demorando avisa que o servidor está acordando', (tester) async {
    final servidor = ServidorFalso()
      ..atraso = const Duration(seconds: 20)
      ..respostas['POST /api/salas'] = {'codigo': 'ABCD', 'token': 'tk-ana'}
      ..respostas['GET /api/salas/ABCD'] = visaoJson(jogadores: [jogadorJson('ana', 'Ana', anfitriao: true)]);
    await abrirApp(tester, servidor);
    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.tap(find.text('Criar uma sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar sem foto'));

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(_aviso), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(_aviso), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Sala de espera'), findsOneWidget);
    await fecharApp(tester);
  });
}
