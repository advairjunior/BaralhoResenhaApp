import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
];

Map<String, dynamic> _comRegra({
  required String modo,
  required Map<String, dynamic> desafio,
  String euId = 'ana',
  List<String> vacilaram = const [],
}) =>
    visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Carta',
      jogadores: _mesa,
      rodada: {
        ...rodadaJson(modo: modo, texto: modo == 'RegraRelampago' ? 'Caio só pode falar cantando.' : 'Beba se usa óculos.'),
        'vacilaram': vacilaram,
      },
      regra: {
        'texto': 'Caio só pode falar cantando.',
        'rodadasRestantes': 3,
        'alvo': 'caio',
        'isca': desafio['tipo'],
        'desafio': desafio,
      },
    );

const _entrevista = {
  'tipo': 'Entrevista',
  'quem': 'bia',
  'para': 'caio',
  'textos': ['Qual foi a pior viagem da sua vida?', 'Qual seu talento escondido?', 'Qual seu maior medo bobo?'],
};

const _pergunta = {
  'tipo': 'Conversa',
  'quem': null,
  'para': 'bia',
  'textos': ['Como anda o trabalho?'],
};

void main() {
  group('Regra com isca', () {
    testWidgets('na carta da regra, o app sorteia quem entrevista e as perguntas', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comRegra(modo: 'RegraRelampago', desafio: _entrevista);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('Qual seu maior medo bobo?'));
      expect(find.text('🎤 Bia entrevista Caio'), findsOneWidget);
      expect(find.text('Qual foi a pior viagem da sua vida?'), findsOneWidget);
      expect(find.text('Caio responde seguindo a regra!'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('nas cartas seguintes vem uma pergunta e quem criou a sala marca o vacilo', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _comRegra(modo: 'BebaSe', desafio: _pergunta)
        ..respostas['POST /api/salas/ABCD/vacilo'] =
            _comRegra(modo: 'BebaSe', desafio: _pergunta, vacilaram: ['caio']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('🎤 Pergunta para Bia'), findsOneWidget);
      expect(find.text('Como anda o trabalho?'), findsOneWidget);
      await tester.tap(find.text('🚨 Alguém vacilou?'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('vacilou-caio')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/vacilo');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'jogadorId': 'caio'});
      expect(find.text('🚨 Vacilou: Caio'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem não criou a sala só vê quem vacilou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] =
            _comRegra(modo: 'BebaSe', desafio: _pergunta, euId: 'bia', vacilaram: ['caio']);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('🚨 Vacilou: Caio'), findsOneWidget);
      expect(find.text('🚨 Alguém vacilou?'), findsNothing);
      await fecharApp(tester);
    });
  });
}
