import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

Map<String, dynamic> _comCronometro({String euId = 'ana', int? restanteMs}) => visaoJson(
      euId: euId,
      souAnfitriao: euId == 'ana',
      fase: 'Carta',
      rodada: {
        ...rodadaJson(
          modo: 'Elogios',
          texto: 'Rodada de elogios para Bia: cada um diz uma qualidade dela em 5 segundos, sem repetir.',
        ),
        'cronometroSegundos': 5,
        'cronometroRestanteMs': restanteMs,
      },
    );

void main() {
  testWidgets('quem criou a sala dá o valendo e o tempo corre', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = _comCronometro()
      ..respostas['POST /api/salas/ABCD/cronometro'] = _comCronometro(restanteMs: 5000);
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('⏱️ Valendo! 5 segundos'));
    await tester.tap(find.text('⏱️ Valendo! 5 segundos'));
    // Depois do valendo, o servidor de verdade conta o tempo; aqui ele já responde que acabou.
    servidor.respostas['GET /api/salas/ABCD'] = _comCronometro(restanteMs: 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/cronometro');
    expect(servidor.recebidas.last.corpo, {'rodada': 1});

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Tempo! ⏰'), findsOneWidget);
    await fecharApp(tester);
  });

  testWidgets('quem não criou a sala espera o valendo e vê o mesmo tempo', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _comCronometro(euId: 'bia');
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('⏱️ Ana dá o valendo (5 segundos)'));
    expect(find.text('⏱️ Valendo! 5 segundos'), findsNothing);
    await fecharApp(tester);
  });

  testWidgets('carta sem tempo não tem cronômetro', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(fase: 'Carta', rodada: rodadaJson(modo: 'BebaSe', texto: 'Beba se usa óculos.'));
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    expect(find.textContaining('⏱️'), findsNothing);
    await fecharApp(tester);
  });
}
