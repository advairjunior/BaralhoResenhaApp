import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baralho_resenha_app/dominio/recorte_da_selfie.dart';
import 'package:baralho_resenha_app/infraestrutura/camera_do_app.dart';
import 'package:baralho_resenha_app/telas/selfie.dart';

import 'apoio.dart';
import 'apoio/camera_falsa.dart';

Future<void> _tirarEUsar(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Tirar foto'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Usar foto'));
  await tester.pumpAndSettle();
}

void main() {
  late CameraFalsa camera;

  setUp(() {
    camera = CameraFalsa();
    fabricaDeCamera = () => camera;
    sorteioDaCareta = Random(1);
  });

  group('recorte da selfie', () {
    test('foto em pé no 9:16 recorta o círculo da moldura', () {
      final recorte = recorteDaSelfie(900, 1600, comMoldura: true);

      expect(recorte.lado, closeTo(900 * diametroDaMoldura, 0.001));
      expect(recorte.x + recorte.lado / 2, closeTo(450, 0.001));
      expect(recorte.y + recorte.lado / 2, closeTo(1600 * centroYDaMoldura, 0.001));
    });

    test('foto deitada considera só o miolo que apareceu na prévia', () {
      final recorte = recorteDaSelfie(1920, 1080, comMoldura: true);
      const visivel = 1080 * 9 / 16;

      expect(recorte.lado, closeTo(visivel * diametroDaMoldura, 0.001));
      expect(recorte.x + recorte.lado / 2, closeTo(960, 0.001));
      expect(recorte.y + recorte.lado, lessThanOrEqualTo(1080));
    });

    test('foto da câmera do sistema usa o quadrado do centro', () {
      expect(recorteDaSelfie(1200, 1600, comMoldura: false), const Recorte(0, 200, 1200));
    });
  });

  testWidgets('selfie tirada na entrada sobe junto com a criação da sala', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['POST /api/salas'] = {'codigo': 'ABCD', 'token': 'tk-ana'}
      ..respostas['PUT /api/salas/ABCD/jogadores/eu/foto'] = visaoJson()
      ..respostas['GET /api/salas/ABCD'] = visaoJson();
    await abrirApp(tester, servidor);

    await tester.tap(find.byKey(const Key('botao-selfie')));
    await tester.pumpAndSettle();
    expect(camera.iniciadas, [LenteDaCamera.frontal]);
    expect(find.text('Hora da selfie!'), findsOneWidget);
    expect(find.text('Tema da careta:'), findsOneWidget);
    await _tirarEUsar(tester);

    expect(find.text('Ficou ótima! Toque para trocar'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.tap(find.text('Criar uma sala'));
    await tester.pumpAndSettle();

    expect(find.text('Entrar sem foto'), findsNothing);
    expect(servidor.rotas, ['POST /api/salas', 'PUT /api/salas/ABCD/jogadores/eu/foto', 'GET /api/salas/ABCD']);
    expect(servidor.fotos.single, pngMinimo);
    await fecharApp(tester);
  });

  testWidgets('quem aceita o convite tira a selfie antes de entrar', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['POST /api/salas'] = {'codigo': 'ABCD', 'token': 'tk-ana'}
      ..respostas['PUT /api/salas/ABCD/jogadores/eu/foto'] = visaoJson()
      ..respostas['GET /api/salas/ABCD'] = visaoJson();
    await abrirApp(tester, servidor);

    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.tap(find.text('Criar uma sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar selfie'));
    await tester.pumpAndSettle();
    await _tirarEUsar(tester);

    expect(servidor.fotos, hasLength(1));
    expect(find.text('Sala de espera'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('desistir da câmera não entra na sala', (tester) async {
    final servidor = ServidorFalso();
    await abrirApp(tester, servidor);

    await tester.enterText(find.widgetWithText(TextField, 'Seu nome'), 'Ana');
    await tester.tap(find.text('Criar uma sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar câmera'));
    await tester.pumpAndSettle();

    expect(servidor.recebidas, isEmpty);
    expect(find.text('Criar uma sala'), findsOneWidget);
  });

  testWidgets('na sala de espera, tocar na própria foto troca a selfie', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson()
      ..respostas['PUT /api/salas/ABCD/jogadores/eu/foto'] = visaoJson(jogadores: [
        jogadorJson('ana', 'Ana', anfitriao: true, foto: '/api/salas/ABCD/fotos/f1'),
        jogadorJson('bia', 'Bia'),
      ]);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: {'sala_ABCD': 'tk-ana'});

    await tester.tap(find.byKey(const Key('minha-selfie')));
    await tester.pumpAndSettle();
    await _tirarEUsar(tester);

    expect(servidor.fotos, hasLength(1));
    final foto = tester.widget<Image>(find.byType(Image).first).image as NetworkImage;
    expect(foto.url, 'http://teste/api/salas/ABCD/fotos/f1');
    await fecharApp(tester);
  });

  testWidgets('câmera sem permissão oferece a câmera do celular', (tester) async {
    camera = CameraFalsa(falharAoIniciar: true);
    await abrirApp(tester, ServidorFalso());

    await tester.tap(find.byKey(const Key('botao-selfie')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível abrir a câmera.'), findsOneWidget);
    expect(find.text('Usar a câmera do celular'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
  });
}
