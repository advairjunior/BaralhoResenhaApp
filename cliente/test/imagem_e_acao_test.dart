import 'package:flutter_test/flutter_test.dart';

import 'apoio.dart';

const _logado = {'sala_ABCD': 'tk'};

final _mesa = [
  jogadorJson('ana', 'Ana', anfitriao: true),
  jogadorJson('bia', 'Bia'),
  jogadorJson('caio', 'Caio'),
  jogadorJson('duda', 'Duda'),
  jogadorJson('edu', 'Edu'),
  jogadorJson('fabi', 'Fabi'),
];

const _doisTimes = [
  {'mimico': 'bia', 'jogadores': ['bia', 'ana', 'duda']},
  {'mimico': 'caio', 'jogadores': ['caio', 'edu', 'fabi']},
];

Map<String, dynamic> _mimica({
  String euId = 'ana',
  List<Map<String, Object>> times = _doisTimes,
  Map<String, dynamic>? revelacao,
}) {
  final mimico = times.any((t) => t['mimico'] == euId);
  return visaoJson(
    euId: euId,
    souAnfitriao: euId == 'ana',
    fase: revelacao == null ? 'Carta' : 'Revelada',
    jogadores: _mesa,
    rodada: {
      ...rodadaJson(
        modo: 'ImagemEAcao',
        texto: mimico || revelacao != null ? 'Escovar os dentes' : '🎭 Adivinhe a mímica!',
        revelacao: revelacao,
      ),
      'pedeResposta': false,
      'times': times,
      'dica': 'Ação · 3 palavras',
      'cronometroSegundos': 60,
    },
  );
}

void main() {
  group('Imagem e Ação', () {
    testWidgets('quem faz a mímica vê a palavra e a dica que pode dizer', (tester) async {
      final servidor = ServidorFalso()..respostas['GET /api/salas/ABCD'] = _mimica(euId: 'bia');
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Escovar os dentes'), findsWidgets);
      expect(find.text('🎭 AÇÃO · 3 PALAVRAS'), findsOneWidget);
      await rolarAte(tester, find.text('Pode dizer: Ação · 3 palavras'));
      expect(find.text('🤫 Só você e os outros mímicos veem a palavra'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('quem adivinha vê os times e quem criou a sala marca o time que acertou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _mimica()
        ..respostas['POST /api/salas/ABCD/mimica'] = _mimica(revelacao: {
          'jaFizeram': [],
          'nuncaFizeram': [],
          'votos': [],
          'perderam': ['bia', 'ana', 'duda'],
          'contaAHistoria': null,
          'escolhidos': ['caio', 'edu', 'fabi'],
          'timeVencedor': 1,
        });
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      expect(find.text('Escovar os dentes'), findsNothing);
      expect(find.text('🎭 Adivinhe a mímica!'), findsOneWidget);
      await rolarAte(tester, find.text('🔵 Time de Caio acertou!'));
      expect(find.text('🔴 Seu time · Bia faz a mímica'), findsOneWidget);
      expect(find.text('⏱️ Valendo! 60 segundos'), findsOneWidget);

      await tester.tap(find.text('🔵 Time de Caio acertou!'));
      await tester.pumpAndSettle();
      expect(servidor.recebidas.last.rota, 'POST /api/salas/ABCD/mimica');
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'vencedor': 1});

      await rolarAte(tester, find.text('Era: Escovar os dentes'));
      expect(find.text('🏆 Time 🔵 acertou!'), findsOneWidget);
      await fecharApp(tester);
    });

    testWidgets('com uma pessoa fazendo para todos, dá para marcar que ninguém acertou', (tester) async {
      final servidor = ServidorFalso()
        ..respostas['GET /api/salas/ABCD'] = _mimica(times: [
          {'mimico': 'bia', 'jogadores': ['bia', 'ana', 'caio', 'duda', 'edu', 'fabi']},
        ])
        ..respostas['POST /api/salas/ABCD/mimica'] = _mimica();
      await abrirApp(tester, servidor, rota: '/sala/ABCD', guardado: _logado);

      await rolarAte(tester, find.text('⏰ Ninguém acertou'));
      expect(find.text('✅ Acertaram!'), findsOneWidget);
      await tester.tap(find.text('⏰ Ninguém acertou'));
      await tester.pumpAndSettle();
      expect(servidor.recebidas.last.corpo, {'rodada': 1, 'vencedor': null});
      await fecharApp(tester);
    });
  });
}
