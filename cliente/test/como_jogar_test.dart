import 'package:baralho_resenha_app/infraestrutura/abrir_link.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('a tela inicial abre o guia Como jogar', (tester) async {
    final servidor = ServidorFalso();
    await abrirApp(tester, servidor);

    await rolarAte(tester, find.text('📖 Como jogar?'));
    await tester.tap(find.text('📖 Como jogar?'));
    await tester.pumpAndSettle();

    expect(linksAbertos.last, 'http://teste/como-jogar');
  });
}
