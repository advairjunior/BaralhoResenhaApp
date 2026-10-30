import 'package:baralho_resenha_app/dominio/modelos.dart';
import 'package:baralho_resenha_app/infraestrutura/voz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
  jogadorJson('duda', 'Duda'),
];

const _umTime = [
  {
    'mimico': 'bia',
    'jogadores': ['bia', 'ana', 'caio', 'duda'],
  },
];

const _proibidas = ['Areia', 'Mar', 'Sol', 'Verão'];

Map<String, dynamic> _carta({String euId = 'ana', Map<String, dynamic>? revelacao}) {
  final explica = euId == 'bia';
  return visaoJson(
    euId: euId,
    souAnfitriao: euId == 'ana',
    fase: revelacao == null ? 'Carta' : 'Revelada',
    jogadores: _mesa,
    modos: ['PalavraProibida'],
    rodada: {
      ...rodadaJson(
        modo: 'PalavraProibida',
        texto: explica || revelacao != null ? 'Praia' : '🚫 Adivinhe a palavra!',
        revelacao: revelacao,
      ),
      'pedeResposta': false,
      'times': _umTime,
      'proibidas': explica || revelacao != null ? _proibidas : [],
      'cronometroSegundos': 60,
    },
  );
}

void main() {
  group('🚫 Palavra proibida', () {
    testWidgets('quem explica vê a palavra e o que não pode dizer', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta(euId: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('🚫 Não pode dizer:'));
      for (final proibida in _proibidas) {
        expect(find.text(proibida), findsOneWidget);
      }
      expect(find.text('🗣️ Bia explica para todo mundo'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem adivinha não vê a palavra nem as proibidas', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _carta(euId: 'caio');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('🚫 Adivinhe a palavra!'), findsWidgets);
      expect(find.text('Areia'), findsNothing);
      expect(find.text('🚫 Não pode dizer:'), findsNothing);
      await fecharApp(tester);
    });

    testWidgets('quem criou a sala marca que acertaram, como na mímica', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _carta()
        ..respostas['POST /api/salas/ABCD/mimica'] = _carta(
          revelacao: {
            'jaFizeram': [],
            'nuncaFizeram': [],
            'votos': [],
            'perderam': [],
            'contaAHistoria': null,
            'timeVencedor': 0,
          },
        );
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('✅ Acertaram!'));
      await tester.tap(find.text('✅ Acertaram!'));
      await tester.pumpAndSettle();

      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'vencedor': 0});
      await rolarAte(tester, find.text('Proibidas: Areia · Mar · Sol · Verão'));
      expect(find.text('Era: Praia'), findsOneWidget);
      await fecharApp(tester);
    });

    test('a voz não lê a palavra, só quem explica', () {
      final fala = falaDaCarta(VisaoDaSala.deJson(_carta()));

      expect(fala, endsWith('Palavra proibida! Bia explica.'));
      expect(fala, isNot(contains('Praia')));
    });
  });
}
