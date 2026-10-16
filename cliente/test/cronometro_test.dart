import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

void main() {
  testWidgets('carta que fala em segundos ganha cronômetro', (tester) async {
    final servidor = ServidorFalso()
      ..respostas['GET /api/salas/ABCD'] = visaoJson(
        fase: 'Carta',
        rodada: rodadaJson(
          modo: 'Elogios',
          texto: 'Rodada de elogios para Bia: cada um diz uma qualidade dela em 5 segundos, sem repetir.',
        ),
      );
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

    await rolarAte(tester, find.text('⏱️ Valendo! 5 segundos'));
    await tester.tap(find.text('⏱️ Valendo! 5 segundos'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Tempo! ⏰ Toque para o próximo'), findsOneWidget);
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
