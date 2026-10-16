import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baralho_resenha_app/infraestrutura/camera_do_app.dart';

import 'apoio.dart';
import 'apoio/camera_falsa.dart';
import 'apoio/compartilhamento_falso.dart';

const _logado = {'sala_ABCD': 'tk'};
const _comCasais = ['EuNunca', 'MaisProvavel', 'BebaSe', 'RegraRelampago', 'CasaisEmJogo'];

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true, goles: 3),
  jogadorJson('bia', 'Bia', semAlcool: true),
  jogadorJson('caio', 'Caio', goles: 1),
];

Map<String, dynamic> _cartaDoCasal({String euId = 'ana', Map<String, dynamic>? revelacao, bool? acertou}) => visaoJson(
      euId: euId,
      fase: revelacao == null ? 'Carta' : 'Revelada',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: 'CasaisEmJogo', texto: 'Qual a comida que Bia mais odeia?', revelacao: revelacao),
        'palpiteiro': 'ana',
        'alvo': 'bia',
        'acertou': acertou,
      },
    );

const _respostasDoCasal = {
  'jaFizeram': [],
  'nuncaFizeram': [],
  'votos': [],
  'perderam': [],
  'contaAHistoria': null,
  'respostaDoAlvo': 'Jiló',
  'palpiteDoPar': 'Quiabo',
};

Map<String, dynamic> _fimDaNoite({List<Map<String, dynamic>> momentos = const []}) => {
      ...visaoJson(fase: 'Fim', jogadores: _mesa),
      'momentos': momentos,
      'premios': [
        {'emoji': '🍺', 'titulo': 'Rei(nha) da noite', 'descricao': '3 goles', 'jogadores': ['ana']},
        {'emoji': '💞', 'titulo': 'Casal em sintonia', 'descricao': 'Acertaram 2 palpites', 'jogadores': ['ana', 'bia']},
      ],
      'resumo': {'cartas': 42, 'minutos': 95, 'goles': 4, 'pontos': 0},
    };

void main() {
  late CameraFalsa camera;

  setUp(() {
    camera = CameraFalsa();
    fabricaDeCamera = () => camera;
  });

  group('Casais em Jogo', () {
    testWidgets('palpiteiro escreve o chute e envia', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _cartaDoCasal()
        ..respostas['POST /api/salas/ABCD/respostas'] = _cartaDoCasal();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Enviar'));
      expect(find.text('Tente adivinhar o que Bia vai responder:'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('resposta-do-casal')), 'Quiabo');
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'Quiabo'});
      await fecharApp(tester);
    });

    testWidgets('quem não é do casal assiste', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _cartaDoCasal(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Vez do casal! Pega a pipoca 🍿'), findsOneWidget);
      expect(find.byKey(const Key('resposta-do-casal')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('na revelação quem respondeu a verdade julga o chute', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _cartaDoCasal(euId: 'bia', revelacao: _respostasDoCasal)
        ..respostas['POST /api/salas/ABCD/julgar'] =
            _cartaDoCasal(euId: 'bia', revelacao: {..._respostasDoCasal, 'perderam': ['ana']}, acertou: false);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('“Jiló”'), findsOneWidget);
      expect(find.text('“Quiabo”'), findsOneWidget);
      await tester.tap(find.text('😬 Errou'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'acertou': false});
      expect(find.text('Ana bebe 🍺'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('sem Casais em Jogo na mistura, não pede para marcar o par', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson(jogadores: _mesa);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.byKey(const Key('meu-par')), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('marcar o par na sala de espera', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(jogadores: _mesa, modos: _comCasais)
        ..respostas['PUT /api/salas/ABCD/jogadores/eu/par'] = visaoJson(modos: _comCasais, jogadores: [
          {...jogadorJson('ana', 'Ana', anfitriao: true), 'parId': 'bia'},
          {...jogadorJson('bia', 'Bia'), 'parId': 'ana'},
        ]);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('meu-par')));
      await tester.tap(find.byKey(const Key('meu-par')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bia').last);
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'parId': 'bia'});
      expect(find.text('Seu par: Bia'), findsOneWidget);
      expect(find.text('Ana 💞 Bia'), findsOneWidget);
      await fecharApp(tester);
    });
  });

  testWidgets('mais votado aparece com suspense e depois some', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Revelada',
        jogadores: _mesa,
        rodada: rodadaJson(modo: 'MaisProvavel', texto: 'Quem é mais provável de dormir no sofá?', revelacao: {
          'jaFizeram': [],
          'nuncaFizeram': [],
          'votos': [
            {'jogadorId': 'caio', 'votos': 2},
          ],
          'perderam': ['caio'],
          'contaAHistoria': null,
        }),
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);

    expect(find.text('E o mais votado é…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('bebe! 🍺'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('suspense')), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('quem conta a história tira a selfie de reação pro mural', (tester) async {
    final revelada = visaoJson(
      fase: 'Revelada',
      jogadores: _mesa,
      rodada: rodadaJson(revelacao: {
        'jaFizeram': ['ana'],
        'nuncaFizeram': ['bia', 'caio'],
        'votos': [],
        'perderam': ['ana'],
        'contaAHistoria': 'ana',
      }),
    );
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = revelada
      ..respostas['PUT /api/salas/ABCD/momentos'] = {
        ...revelada,
        'momentos': [
          {'id': 'm1', 'jogadorId': 'ana', 'nome': 'Ana', 'rodada': 1, 'texto': 'Eu nunca…', 'foto': '/api/salas/ABCD/fotos/m1'},
        ],
      };
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('Selfie de reação pro mural 📸'));
    await tester.tap(find.text('Selfie de reação pro mural 📸'));
    await tester.pumpAndSettle();
    expect(camera.iniciadas, [LenteDaCamera.frontal]);
    expect(find.text('Cara de quem vai contar essa história 🎤'), findsOneWidget);
    await tester.tap(find.byTooltip('Tirar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar foto'));
    await tester.pumpAndSettle();

    expect(servidor.rotas, contains('PUT /api/salas/ABCD/momentos'));
    expect(servidor.fotos, hasLength(1));
    await rolarAte(tester, find.text('Tirar outra selfie pro mural'));
    expect(find.text('Tirar outra selfie pro mural'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('anfitrião encerra a noite e todos veem os prêmios', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] =
          visaoJson(fase: 'Carta', jogadores: _mesa, rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se…'))
      ..respostas['POST /api/salas/ABCD/encerrar'] = _fimDaNoite();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar a noite 🏆'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver os prêmios'));
    await tester.pumpAndSettle();

    expect(servidor.rotas, contains('POST /api/salas/ABCD/encerrar'));
    expect(find.text('Prêmios da Noite'), findsOneWidget);
    expect(find.text('🍺 Rei(nha) da noite'), findsOneWidget);
    expect(find.text('Ana e Bia'), findsOneWidget);
    expect(find.text('1h35'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('fim da noite compartilha o cartão e mostra o mural', (tester) async {
    final compartilhamento = usarCompartilhamentoFalso();
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _fimDaNoite(momentos: [
        {'id': 'm1', 'jogadorId': 'caio', 'nome': 'Caio', 'rodada': 3, 'texto': 'Eu nunca dormi no sofá.', 'foto': '/f/m1'},
        {'id': 'm2', 'jogadorId': 'ana', 'nome': 'Ana', 'rodada': 4, 'texto': 'Quem é mais provável…', 'foto': '/f/m2'},
      ])
      ..respostas['GET /f/m1'] = [0xFF, 0xD8, 0xFF]
      ..respostas['GET /f/m2'] = [0xFF, 0xD8, 0xFF]
      ..respostas['POST /api/salas/ABCD/retomar'] =
          visaoJson(fase: 'Carta', jogadores: _mesa, rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se…'));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('📸 Mural da noite (2)'));
    expect(find.text('Eu nunca dormi no sofá.'), findsOneWidget);

    await rolarAte(tester, find.text('Mandar no grupo da turma'));
    await tester.tap(find.text('Mandar no grupo da turma'));
    for (var tentativa = 0; tentativa < 20 && compartilhamento.pedidos.isEmpty; tentativa++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    }
    expect(compartilhamento.pedidos.single.fileNameOverrides, ['premios-da-noite.png']);

    final pedidosDaImagem = compartilhamento.pedidos.length;
    await rolarAte(tester, find.text('Salvar todas no celular (2)'));
    await tester.tap(find.byKey(const Key('mural-m1')));
    await tester.pump();
    expect(find.text('Salvar a escolhida'), findsOneWidget);
    await tester.tap(find.text('Salvar a escolhida'));
    for (var tentativa = 0; tentativa < 20 && compartilhamento.pedidos.length == pedidosDaImagem; tentativa++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    expect(compartilhamento.pedidos.last.fileNameOverrides, ['baralho-da-resenha-caio-1.jpg']);
    // As fotos já vêm ao abrir a tela (o Safari exige salvar logo após o toque),
    // cada uma uma vez só; vai para o celular só a escolhida.
    expect(servidor.rotas.where((r) => r.startsWith('GET /f/')).toList()..sort(), ['GET /f/m1', 'GET /f/m2']);

    await rolarAte(tester, find.text('Só mais uma rodada 🍻'));
    await tester.tap(find.text('Só mais uma rodada 🍻'));
    await tester.pumpAndSettle();
    expect(find.text('Beba se…'), findsOneWidget);
    await fecharApp(tester);
  });
}
