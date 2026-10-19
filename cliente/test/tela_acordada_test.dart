import 'package:baralho_resenha_app/infraestrutura/tela_acordada.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

void main() {
  testWidgets('dentro da sala a tela não apaga; fora dela, volta ao normal', (tester) async {
    final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = visaoJson();
    await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: const {'sala_ABCD': 'tk'});

    expect(telaAcordada, isTrue);

    await fecharApp(tester);
    expect(telaAcordada, isFalse);
  });
}
