import 'package:baralho_resenha_app/dominio/modelos.dart';
import 'package:baralho_resenha_app/infraestrutura/falador.dart';
import 'package:baralho_resenha_app/infraestrutura/voz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _carta({
  int numero = 1,
  String euId = 'ana',
  String modo = 'EuNunca',
  String texto = 'Eu nunca dormi no cinema.',
  Map<String, Object?> extras = const {},
}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {...rodadaJson(modo: modo, texto: texto), 'numero': numero, ...extras},
    );

VisaoDaSala _visao(Map<String, dynamic> json) => VisaoDaSala.deJson(json);

/// Espera a consulta seguinte (a cada 6 s) trazer a sala nova.
Future<void> _proximaConsulta(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(falasFeitas.clear);

  group('o que a voz fala', () {
    test('anuncia o jogo e lê a carta, sem os emojis', () {
      final fala = falaDaCarta(_visao(_carta(texto: 'Eu nunca dormi no cinema 🍿.')));

      expect(fala, endsWith('Eu Nunca! Eu nunca dormi no cinema.'));
      expect(fala, isNot(contains('🍿')));
    });

    test('na mímica não fala a palavra, só quem faz', () {
      final fala = falaDaCarta(_visao(_carta(
        modo: 'ImagemEAcao',
        texto: 'Escovar os dentes',
        extras: {
          'times': [
            {'mimico': 'ana', 'jogadores': ['ana', 'bia', 'caio']},
          ],
        },
      )));

      expect(fala, endsWith('Imagem e Ação! Ana faz a mímica.'));
      expect(fala, isNot(contains('Escovar')));
    });

    test('no Impostor não fala a palavra, só o tema', () {
      final fala = falaDaCarta(_visao(_carta(modo: 'Impostor', texto: 'Pizza', extras: {'dica': 'Tema: Comida'})));

      expect(fala, endsWith('Impostor! Tema: Comida. Cada um olha o seu celular.'));
      expect(fala, isNot(contains('Pizza')));
    });

    test('no Correio não fala a pergunta, que a pessoa da foto não pode ouvir', () {
      final fala = falaDaCarta(
          _visao(_carta(modo: 'Correio', texto: 'O apelido de Caio num reality.', extras: {'alvo': 'caio'})));

      expect(fala, endsWith('Correio da Resenha para Caio! A pergunta está no celular da turma.'));
      expect(fala, isNot(contains('apelido')));
    });

    test('o duelo é anunciado como duelo, não como "Quem é mais provável"', () {
      final fala = falaDaCarta(_visao(_carta(
        modo: 'MaisProvavel',
        texto: 'Duelo de narração: Bia contra Caio.',
        extras: {'duelistas': ['bia', 'caio']},
      )));

      expect(fala, endsWith('Duelo! Duelo de narração: Bia contra Caio.'));
    });

    test('o pedra, papel e tesoura é anunciado pelo nome', () {
      final fala = falaDaCarta(_visao(_carta(
        modo: 'MaisProvavel',
        texto: 'Quem é mais provável de chegar atrasado?',
        extras: {'duelistas': ['bia', 'caio'], 'jokenpo': true},
      )));

      expect(fala, contains('Pedra, papel e tesoura!'));
    });

    test('na Batata quente fala a categoria e com quem a batata começa', () {
      final fala = falaDaCarta(_visao(_carta(modo: 'BatataQuente', texto: 'Marcas de cerveja', extras: {'comABatata': 'bia'})));

      expect(fala, endsWith('Batata quente! Marcas de cerveja. Começa com Bia!'));
    });

    test('o "(a)" do masculino e feminino não é lido', () {
      final fala = falaDaCarta(_visao(_carta(texto: 'Eu nunca fui expulso(a) de lugar nenhum com os(as) amigos(as).')));

      expect(fala, endsWith('Eu nunca fui expulso de lugar nenhum com os amigos.'));
    });

    test('cada carta sai com um personagem, e a chamada é dele', () {
      final personagens = {for (var numero = 1; numero <= Personagem.values.length; numero++) personagemDa(numero)};

      expect(personagens, Personagem.values.toSet());
      expect(falaDaCarta(_visao(_carta(numero: 3))), startsWith(personagemDa(3).chamada));
    });
  });

  group('quem fala e quando', () {
    testWidgets('o celular de quem comanda lê a carta nova', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
      // Quem abre o app no meio da carta não ouve a carta de novo.
      expect(falasFeitas, isEmpty);

      servidor.respostas['GET /api/salas/ABCD'] = _carta(numero: 2, texto: 'Eu nunca fui expulso de um bar.');
      await _proximaConsulta(tester);

      expect(falasFeitas.single.texto, endsWith('Eu nunca fui expulso de um bar.'));
      expect(falasFeitas.single.personagem, personagemDa(2));
      // A mesma carta na consulta seguinte não fala de novo.
      await _proximaConsulta(tester);
      expect(falasFeitas, hasLength(1));
      await fecharApp(tester);
    });

    testWidgets('os outros celulares ficam quietos', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta(euId: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      servidor.respostas['GET /api/salas/ABCD'] = _carta(euId: 'bia', numero: 2);
      await _proximaConsulta(tester);

      expect(falasFeitas, isEmpty);
      await fecharApp(tester);
    });

    testWidgets('quem comanda desliga a voz pelo menu', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🗣️ Desligar a voz das cartas'));
      await tester.pumpAndSettle();
      servidor.respostas['GET /api/salas/ABCD'] = _carta(numero: 2);
      await _proximaConsulta(tester);

      expect(falasFeitas, isEmpty);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('🗣️ Ligar a voz das cartas'), findsOneWidget);
      await fecharApp(tester);
    });
  });
}
