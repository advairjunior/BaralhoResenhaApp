import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:baralho_resenha_app/infraestrutura/api_baralho.dart';
import 'package:baralho_resenha_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servidor de mentira: responde por "MÉTODO /rota" e anota o que recebeu.
class ServidorFalso {
  final respostas = <String, Object>{};
  final recebidas = <({String rota, Map<String, dynamic>? corpo})>[];

  /// Fotos recebidas, na ordem.
  final fotos = <List<int>>[];

  /// Vezes que o app cutucou o servidor para acordar (fica fora de [recebidas]).
  int acordou = 0;

  /// Servidor dormindo: cada resposta demora isso.
  Duration atraso = Duration.zero;

  late final api = ApiBaralho(
    enderecoBase: 'http://teste',
    cliente: MockClient((requisicao) async {
      final chave = '${requisicao.method} ${requisicao.url.path}';
      if (chave == 'GET /api/saude') {
        acordou++;
        return http.Response('{"status":"ok"}', 200);
      }
      if (atraso > Duration.zero) await Future<void>.delayed(atraso);
      final ehFoto = requisicao.headers['Content-Type'] == 'image/jpeg';
      if (ehFoto) fotos.add(requisicao.bodyBytes);
      recebidas.add((
        rota: chave,
        corpo: ehFoto || requisicao.body.isEmpty
            ? null
            : jsonDecode(requisicao.body) as Map<String, dynamic>,
      ));
      final resposta = respostas[chave];
      if (resposta == null) return http.Response('{"mensagem":"Sala não encontrada."}', 404);
      // Sem internet: a requisição nem chega.
      if (resposta is Exception) throw resposta;
      if (resposta is List<int>) {
        return http.Response.bytes(resposta, 200, headers: {'content-type': 'image/jpeg'});
      }
      return http.Response.bytes(utf8.encode(jsonEncode(resposta)), 200,
          headers: {'content-type': 'application/json'});
    }),
  );

  List<String> get rotas => [for (final r in recebidas) r.rota];
}

Map<String, dynamic> jogadorJson(String id, String nome,
        {bool anfitriao = false,
        bool semAlcool = false,
        int goles = 0,
        int? pontos,
        int cofrinho = 0,
        bool respondeu = false,
        String? foto,
        bool conectado = true}) =>
    {
      'id': id,
      'nome': nome,
      'anfitriao': anfitriao,
      'semAlcool': semAlcool,
      'goles': goles,
      'pontos': pontos ?? goles,
      'cofrinho': cofrinho,
      'respondeu': respondeu,
      'foto': foto,
      'conectado': conectado,
    };

Map<String, dynamic> visaoJson({
  String fase = 'Lobby',
  String euId = 'ana',
  bool souAnfitriao = true,
  List<Map<String, dynamic>>? jogadores,
  Map<String, dynamic>? rodada,
  Map<String, dynamic>? regra,
  String nivel = 'Resenha',
  List<String> modos = const ['EuNunca', 'MaisProvavel', 'BebaSe', 'RegraRelampago'],
  // Os testes mais antigos são do tempo em que todo ponto era gole.
  String ritmo = 'Raiz',
  int? cofrinho,
  bool semAlcool = false,
}) =>
    {
      'codigo': 'ABCD',
      'fase': fase,
      'euId': euId,
      'souAnfitriao': souAnfitriao,
      'configuracao': {
        'nivel': nivel,
        'modos': modos,
        'zonaSegura': true,
        'ritmo': ritmo,
        'cofrinho': cofrinho,
        'semAlcool': semAlcool,
      },
      'jogadores': jogadores ??
          [jogadorJson('ana', 'Ana', anfitriao: true), jogadorJson('bia', 'Bia', semAlcool: true)],
      'rodada': rodada,
      'regra': regra,
    };

Map<String, dynamic> rodadaJson({
  String modo = 'EuNunca',
  String texto = 'Eu nunca dormi no sofá depois de uma briga.',
  String? minhaResposta,
  int respostas = 0,
  Map<String, dynamic>? revelacao,
  bool euBebi = false,
  List<String> beberam = const [],
  List<String> bebemAgora = const [],
}) =>
    {
      'numero': 1,
      'modo': modo,
      'nivel': 'Resenha',
      'texto': texto,
      'pedeResposta': modo == 'EuNunca' || modo == 'MaisProvavel',
      'minhaResposta': minhaResposta,
      'respostas': respostas,
      'euBebi': euBebi,
      'beberam': beberam,
      'bebemAgora': bebemAgora,
      'revelacao': revelacao,
    };

Future<void> abrirApp(WidgetTester tester, ServidorFalso servidor,
    {String rota = '/', Map<String, Object> guardado = const {}, bool esperarAcalmar = true}) async {
  SharedPreferences.setMockInitialValues(guardado);
  tester.view.physicalSize = const Size(430, 932) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BaralhoResenhaApp(api: servidor.api));
  if (rota != '/') {
    final navegador = tester.state<NavigatorState>(find.byType(Navigator));
    navegador.pushReplacementNamed(rota);
  }
  if (esperarAcalmar) {
    await tester.pumpAndSettle();
  } else {
    // Animação em laço (o tambor do suspense) nunca acalma: avança aos poucos.
    for (var passo = 0; passo < 5; passo++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }
}

/// Desmonta o app para encerrar a consulta periódica da sala.
Future<void> fecharApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// A sala de espera é uma lista longa: rola até o texto aparecer.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 300, scrollable: find.byType(Scrollable).first);
  // Aparecer só a pontinha não basta para tocar: traz inteiro para a tela.
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
}
