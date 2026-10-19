import 'package:baralho_resenha_app/infraestrutura/som.dart';
import 'package:baralho_resenha_app/infraestrutura/tocador_de_som.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

const _revelacao = {
  'jaFizeram': ['bia'],
  'nuncaFizeram': ['ana'],
  'votos': [],
  'perderam': ['bia'],
  'contaAHistoria': null,
};

Map<String, dynamic> _euNunca({bool revelada = false}) => visaoJson(
      fase: revelada ? 'Revelada' : 'Carta',
      rodada: rodadaJson(minhaResposta: 'nunca', revelacao: revelada ? _revelacao : null),
    );

Map<String, dynamic> _bebaSe({List<String> vacilaram = const []}) => visaoJson(
      fase: 'Carta',
      rodada: {...rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.'), 'vacilaram': vacilaram},
    );

/// Espera a consulta seguinte (a cada 6 s) trazer a sala nova.
Future<void> _proximaConsulta(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(sonsTocados.clear);

  testWidgets('a revelação toca para todo mundo', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _euNunca();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    expect(sonsTocados, isEmpty);

    servidor.respostas['GET /api/salas/ABCD'] = _euNunca(revelada: true);
    await _proximaConsulta(tester);

    expect(sonsTocados, [Som.revelacao]);
    await fecharApp(tester);
  });

  testWidgets('vacilo marcado toca a sirene', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _bebaSe();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    servidor.respostas['GET /api/salas/ABCD'] = _bebaSe(vacilaram: ['bia']);
    await _proximaConsulta(tester);
    // A mesma marcação na consulta seguinte não toca de novo.
    await _proximaConsulta(tester);

    expect(sonsTocados, [Som.vacilo]);
    await fecharApp(tester);
  });

  testWidgets('o cronômetro chegando a zero toca o fim do tempo', (tester) async {
    Map<String, dynamic> comCronometro(int? restanteMs) => visaoJson(
          fase: 'Carta',
          rodada: {
            ...rodadaJson(modo: 'Elogios', texto: 'Cada um diz uma qualidade da Bia em 5 segundos.'),
            'cronometroSegundos': 5,
            'cronometroRestanteMs': restanteMs,
          },
        );
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = comCronometro(5000);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado, esperarAcalmar: false);
    servidor.respostas['GET /api/salas/ABCD'] = comCronometro(0);

    await tester.pump(const Duration(seconds: 3));
    expect(sonsTocados, isEmpty);
    await tester.pump(const Duration(seconds: 3));

    expect(sonsTocados, [Som.tempo]);
    await fecharApp(tester);
  });

  testWidgets('dá para desligar o som pelo menu, e o celular lembra', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _euNunca();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🔇 Desligar som e vibração'));
    await tester.pumpAndSettle();
    servidor.respostas['GET /api/salas/ABCD'] = _euNunca(revelada: true);
    await _proximaConsulta(tester);

    expect(sonsTocados, isEmpty);
    expect((await SharedPreferences.getInstance()).getBool('som_ligado'), isFalse);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('🔊 Ligar som e vibração'), findsOneWidget);
    await fecharApp(tester);
  });
}
