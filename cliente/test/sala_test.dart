import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk-ana'};

void main() {
  testWidgets('anfitrião começa o jogo', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson()
      ..respostas['POST /api/salas/ABCD/comecar'] = visaoJson(fase: 'Carta', rodada: rodadaJson());
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('Começar a resenha 🍻'));
    await tester.tap(find.text('Começar a resenha 🍻'));
    await tester.pumpAndSettle();

    expect(find.text('Eu nunca dormi no sofá depois de uma briga.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('Baralho Original só entra depois de a turma topar', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson()
      ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson(nivel: 'Original');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    await rolarAte(tester, find.byKey(const Key('nivel-original')));

    await tester.tap(find.byKey(const Key('nivel-original')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Melhor não'));
    await tester.pumpAndSettle();
    expect(servidor.rotas, isNot(contains('PUT /api/salas/ABCD/configuracao')));

    await tester.tap(find.byKey(const Key('nivel-original')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bora ver!'));
    await tester.pumpAndSettle();
    expect(servidor.recebidas.last.corpo!['nivel'], 'Original');
    await fecharApp(tester);
  });

  testWidgets('convidado vê as configurações sem poder mexer', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson(euId: 'bia', souAnfitriao: false);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.byKey(const Key('nivel-picante')));
    await tester.tap(find.byKey(const Key('nivel-picante')));
    await tester.pumpAndSettle();

    expect(servidor.rotas, isNot(contains('PUT /api/salas/ABCD/configuracao')));
    expect(find.text('Só quem criou a sala muda as configurações.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('Eu Nunca envia a resposta da rodada', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(fase: 'Carta', rodada: rodadaJson())
      ..respostas['POST /api/salas/ABCD/respostas'] =
          visaoJson(fase: 'Carta', rodada: rodadaJson(minhaResposta: 'ja', respostas: 1));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.text('🙋 Já fiz'));
    await tester.pumpAndSettle();

    expect(servidor.recebidas.last.corpo, {'rodada': 1, 'resposta': 'ja'});
    expect(find.text('1 de 2 responderam'), findsOneWidget);
    expect(find.text('Resposta guardada. Dá para trocar até revelar.'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('quando só uma pessoa já fez, ela conta a história', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Revelada',
        jogadores: [
          jogadorJson('ana', 'Ana', anfitriao: true, goles: 1),
          jogadorJson('bia', 'Bia', semAlcool: true),
        ],
        rodada: rodadaJson(revelacao: {
          'jaFizeram': ['ana'],
          'nuncaFizeram': ['bia'],
          'votos': [],
          'perderam': ['ana'],
          'contaAHistoria': 'ana',
        }),
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('Ana, conta essa história!'), findsOneWidget);
    expect(find.text('Só Ana fez · bebe 🍺'), findsOneWidget);
    expect(find.text('Próxima carta'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('placar mostra goles e pontos de quem joga sem álcool', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Carta',
        jogadores: [
          jogadorJson('ana', 'Ana', anfitriao: true, goles: 3),
          jogadorJson('bia', 'Bia', semAlcool: true, goles: 1),
        ],
        rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se você usa óculos.'),
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byTooltip('Placar'));
    await tester.pumpAndSettle();

    expect(find.text('3 goles'), findsOneWidget);
    expect(find.text('1 ponto'), findsOneWidget);
    expect(find.text('Rei(nha) da noite 👑'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('regra-relâmpago ativa aparece em cima das próximas cartas', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Carta',
        rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se você usa óculos.'),
        regra: {'texto': 'Proibido falar "tipo".', 'rodadasRestantes': 2},
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.text('Proibido falar "tipo".'), findsOneWidget);
    expect(find.text('mais 2\ncartas'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('resumo diz se a noite é um jogo só ou a mistura', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    await rolarAte(tester, find.byKey(const Key('resumo-da-mistura')));
    expect(find.text('🎲 Misturando: Eu Nunca, Quem é mais provável, Beba se e Regra-relâmpago'), findsOneWidget);
    await fecharApp(tester);

    servidor.respostas['GET /api/salas/ABCD'] = visaoJson(modos: ['EuNunca']);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    await rolarAte(tester, find.byKey(const Key('resumo-da-mistura')));
    expect(find.text('🎯 Só Eu Nunca'), findsOneWidget);
    await fecharApp(tester);
  });
}
