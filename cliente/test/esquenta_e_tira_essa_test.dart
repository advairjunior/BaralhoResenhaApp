import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _naCarta({Map<String, dynamic>? esquenta, String? tiradaPor}) => {
      ...visaoJson(fase: 'Carta', rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se você usa óculos.')),
      'esquenta': esquenta,
      'cartaTiradaPor': tiradaPor,
    };

void main() {
  group('Tira essa', () {
    testWidgets('confirma, tira a carta e avisa quem tirou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _naCarta()
        ..respostas['POST /api/salas/ABCD/tirar'] = _naCarta(tiradaPor: 'Ana');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byKey(const Key('tira-essa')));
      await tester.pumpAndSettle();
      expect(find.text('Ela sai do baralho desta noite e vem outra no lugar.'), findsOneWidget);
      await tester.tap(find.text('Tira essa'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1});
      expect(find.text('👎 Ana tirou a carta anterior'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('"Deixa" não tira nada', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _naCarta();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await tester.tap(find.byKey(const Key('tira-essa')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deixa'));
      await tester.pumpAndSettle();

      expect(servidor.rotas, isNot(contains('POST /api/salas/ABCD/tirar')));
      await fecharApp(tester);
    });
  });

  group('Esquenta sozinho', () {
    Future<void> abrirCom(WidgetTester tester, Map<String, dynamic> esquenta) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _naCarta(esquenta: esquenta);
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);
    }

    testWidgets('mostra o nível de agora e quando esquenta', (tester) async {
      await abrirCom(tester, {'agora': 'Leve', 'ate': 'Picante', 'sobeEm': 3, 'subiuAgora': false});
      expect(find.text('🌡️ Leve · esquenta em 3 cartas'), findsOneWidget);
      await fecharApp(tester);

      await abrirCom(tester, {'agora': 'Leve', 'ate': 'Picante', 'sobeEm': 1, 'subiuAgora': false});
      expect(find.text('🌡️ Leve · esquenta na próxima'), findsOneWidget);
      await fecharApp(tester);

      await abrirCom(tester, {'agora': 'Picante', 'ate': 'Picante', 'sobeEm': null, 'subiuAgora': false});
      expect(find.text('🌡️ No máximo: 🌶️ Picante'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('avisa na primeira carta do nível novo', (tester) async {
      await abrirCom(tester, {'agora': 'Resenha', 'ate': 'Picante', 'sobeEm': 8, 'subiuAgora': true});

      expect(find.text('🌡️ Esquentou! Agora é 🍺 Resenha'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('sem esquenta, a barra só tem o "Tira essa"', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _naCarta();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.textContaining('🌡️'), findsNothing);
      expect(find.byKey(const Key('tira-essa')), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('anfitrião liga o esquenta na sala de espera', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = visaoJson(nivel: 'Picante')
        ..respostas['PUT /api/salas/ABCD/configuracao'] = visaoJson(nivel: 'Picante');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.byKey(const Key('esquentar')));
      expect(find.text('Começa no Leve e sobe um nível a cada 8 cartas, até 🌶️ Picante.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('esquentar')));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo!['esquentar'], true);
      expect(servidor.recebidas.last.corpo!['nivel'], 'Picante');
      await fecharApp(tester);
    });
  });
}
