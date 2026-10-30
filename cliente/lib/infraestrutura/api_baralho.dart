import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../dominio/modelos.dart';

class FalhaNaApi implements Exception {
  const FalhaNaApi(this.mensagem, {this.status});

  final String mensagem;
  final int? status;

  /// A sala acabou ou este celular saiu dela: hora de entrar de novo.
  bool get perdeuASala => status == 401 || status == 404;

  @override
  String toString() => mensagem;
}

class ApiBaralho {
  ApiBaralho({http.Client? cliente, String? enderecoBase})
      : _cliente = cliente ?? http.Client(),
        _enderecoBase = enderecoBase ?? _enderecoConfigurado();

  final http.Client _cliente;
  final String _enderecoBase;

  static String _enderecoConfigurado() {
    const configurado = String.fromEnvironment('API_URL');
    if (configurado.isNotEmpty) return configurado;
    if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') return Uri.base.origin;
    return 'http://localhost:5090';
  }

  /// O guia para mandar à turma: mora no mesmo servidor da API.
  String get enderecoDoComoJogar => '$_enderecoBase/como-jogar';

  String enderecoTempoReal(String codigo) => '$_enderecoBase/api/tempo-real/${_codigo(codigo)}';

  /// No plano gratuito o servidor dorme sem uso: cutucar logo ao abrir o app
  /// adianta o despertar enquanto a pessoa digita o nome e tira a selfie.
  Future<void> acordar() async {
    try {
      await _enviar('GET', '/api/saude');
    } on FalhaNaApi {
      // Só um cutucão: quem precisa da resposta é criar ou entrar na sala.
    }
  }

  Future<Entrada> criarSala(String nome, {required bool semAlcool}) async {
    final resposta = await _enviar('POST', '/api/salas', corpo: {'nome': nome, 'semAlcool': semAlcool});
    return Entrada.deJson(resposta as Map<String, dynamic>);
  }

  Future<Entrada> entrar(String codigo, String nome, {required bool semAlcool}) async {
    final resposta = await _enviar('POST', '/api/salas/${_codigo(codigo)}/jogadores',
        corpo: {'nome': nome, 'semAlcool': semAlcool});
    return Entrada.deJson(resposta as Map<String, dynamic>);
  }

  Future<VisaoDaSala> visao(String codigo, String token) =>
      _visao('GET', '/api/salas/${_codigo(codigo)}', token);

  Future<VisaoDaSala> configurar(String codigo, String token, ConfiguracaoDoJogo configuracao) =>
      _visao('PUT', '/api/salas/${_codigo(codigo)}/configuracao', token, corpo: configuracao.paraJson());

  /// Na sala de espera, cada celular manda as cartas que já viu em outras noites.
  Future<VisaoDaSala> lembrarVistas(String codigo, String token, List<String> vistas) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/vistas', token, corpo: {'vistas': vistas});

  /// [vistas]: cartas das noites anteriores, que vão para o fim do monte.
  Future<VisaoDaSala> comecar(String codigo, String token, {List<String> vistas = const []}) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/comecar', token, corpo: {'vistas': vistas});

  Future<VisaoDaSala> responder(String codigo, String token, int rodada, String resposta) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/respostas', token,
          corpo: {'rodada': rodada, 'resposta': resposta});

  Future<VisaoDaSala> revelar(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/revelar', token, corpo: {'rodada': rodada});

  Future<VisaoDaSala> proxima(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/proxima', token, corpo: {'rodada': rodada});

  Future<VisaoDaSala> alternarBebi(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/bebi', token, corpo: {'rodada': rodada});

  /// Marca o par do casal; nulo desfaz.
  Future<VisaoDaSala> definirPar(String codigo, String token, String? parId) =>
      _visao('PUT', '/api/salas/${_codigo(codigo)}/jogadores/eu/par', token, corpo: {'parId': parId});

  Future<VisaoDaSala> julgar(String codigo, String token, int rodada, {required bool acertou}) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/julgar', token,
          corpo: {'rodada': rodada, 'acertou': acertou});

  /// Apontar no 3: quem criou a sala marca (ou desmarca) quem a turma apontou.
  Future<VisaoDaSala> marcarApontado(String codigo, String token, int rodada, String jogadorId) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/apontado', token,
          corpo: {'rodada': rodada, 'jogadorId': jogadorId});

  /// Correio: quem está na foto marca (ou desmarca) o bilhete favorito.
  Future<VisaoDaSala> escolherFavorito(String codigo, String token, int rodada, int indice) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/favorito', token,
          corpo: {'rodada': rodada, 'indice': indice});

  /// Duas verdades e uma mentira: a pessoa da vez manda as três frases e qual é a mentira.
  Future<VisaoDaSala> escreverDuasVerdades(String codigo, String token, int rodada, List<String> frases, int mentira) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/duas-verdades', token,
          corpo: {'rodada': rodada, 'frases': frases, 'mentira': mentira});

  /// Batata quente: quem está com a batata falou e passa para o próximo.
  Future<VisaoDaSala> passarABatata(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/batata', token, corpo: {'rodada': rodada});

  /// Regra-relâmpago: quem criou a sala marca (ou desmarca) quem vacilou.
  Future<VisaoDaSala> marcarVacilo(String codigo, String token, int rodada, String jogadorId) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/vacilo', token,
          corpo: {'rodada': rodada, 'jogadorId': jogadorId});

  /// Imagem e Ação: o time que acertou (nulo: ninguém acertou).
  Future<VisaoDaSala> resultadoDaMimica(String codigo, String token, int rodada, int? vencedor) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/mimica', token,
          corpo: {'rodada': rodada, 'vencedor': vencedor});

  /// Cronômetro da carta: quem criou a sala dá o valendo (de novo, recomeça).
  Future<VisaoDaSala> iniciarCronometro(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/cronometro', token, corpo: {'rodada': rodada});

  /// Carta na manga: usa uma da mão (alvo para Passa a bola, Batata quente e Dobra).
  Future<VisaoDaSala> usarCarta(String codigo, String token, int rodada, CartaNaManga carta, String? alvo) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/carta-na-manga', token,
          corpo: {'rodada': rodada, 'carta': paraServidor(carta), 'alvo': alvo});

  /// Passar sozinho: respondi / estou pronto, segura aí e "acabou a contagem".
  /// "Conta essa": quem criou a sala confirma que a pessoa da vez contou.
  Future<VisaoDaSala> confirmarHistoria(String codigo, String token, int rodada, String jogadorId) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/contou', token, corpo: {'rodada': rodada, 'jogadorId': jogadorId});

  /// Roda de Música: quem criou a sala marca que a pessoa da vez travou.
  Future<VisaoDaSala> marcarTravou(String codigo, String token, int rodada, String jogadorId) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/travou', token, corpo: {'rodada': rodada, 'jogadorId': jogadorId});

  Future<VisaoDaSala> marcarPronto(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/pronto', token, corpo: {'rodada': rodada});

  Future<VisaoDaSala> segurar(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/segurar', token, corpo: {'rodada': rodada});

  Future<VisaoDaSala> passarSozinho(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/passar-sozinho', token, corpo: {'rodada': rodada});

  /// "Tira essa": a carta sai do baralho da noite e vem outra.
  Future<VisaoDaSala> tirar(String codigo, String token, int rodada) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/tirar', token, corpo: {'rodada': rodada});

  /// Reação rápida na carta; a mesma de novo desfaz.
  Future<VisaoDaSala> reagir(String codigo, String token, int rodada, String emoji) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/reacao', token, corpo: {'rodada': rodada, 'emoji': emoji});

  /// Quem está no comando (puxa, pula, revela) passa para outra pessoa.
  Future<VisaoDaSala> passarComando(String codigo, String token, String jogadorId) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/comando', token, corpo: {'jogadorId': jogadorId});

  Future<VisaoDaSala> encerrar(String codigo, String token) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/encerrar', token);

  Future<VisaoDaSala> retomar(String codigo, String token) =>
      _visao('POST', '/api/salas/${_codigo(codigo)}/retomar', token);

  /// Selfie de reação de quem foi pego na carta: vai para o mural da noite.
  Future<VisaoDaSala> registrarMomento(String codigo, String token, int rodada, Uint8List foto) async {
    final resposta = await _enviar('PUT', '/api/salas/${_codigo(codigo)}/momentos?rodada=$rodada',
        token: token, bytes: foto);
    return VisaoDaSala.deJson(resposta as Map<String, dynamic>, enderecoBase: _enderecoBase);
  }

  /// Bytes de uma foto do mural, para salvar no celular.
  Future<Uint8List> baixarFoto(String endereco) async {
    final http.Response resposta;
    try {
      resposta = await _cliente.get(Uri.parse(endereco));
    } catch (_) {
      throw const FalhaNaApi('Sem conexão. Confira a internet e tente de novo.');
    }
    if (resposta.statusCode != 200) {
      throw FalhaNaApi('Essa foto não está mais disponível.', status: resposta.statusCode);
    }
    return resposta.bodyBytes;
  }

  Future<void> sair(String codigo, String token) =>
      _enviar('DELETE', '/api/salas/${_codigo(codigo)}/jogadores/eu', token: token);

  /// Quem criou a sala tira quem caiu e foi embora de vez.
  Future<VisaoDaSala> tirarDaSala(String codigo, String token, String jogadorId) =>
      _visao('DELETE', '/api/salas/${_codigo(codigo)}/jogadores/$jogadorId', token);

  Future<VisaoDaSala> _visao(String metodo, String rota, String token, {Object? corpo}) async {
    final resposta = await _enviar(metodo, rota, token: token, corpo: corpo);
    return VisaoDaSala.deJson(resposta as Map<String, dynamic>, enderecoBase: _enderecoBase);
  }

  /// A selfie vai crua no corpo, como JPEG.
  Future<VisaoDaSala> enviarFoto(String codigo, String token, Uint8List foto) async {
    final resposta = await _enviar('PUT', '/api/salas/${_codigo(codigo)}/jogadores/eu/foto',
        token: token, bytes: foto);
    return VisaoDaSala.deJson(resposta as Map<String, dynamic>, enderecoBase: _enderecoBase);
  }

  Future<Object?> _enviar(String metodo, String rota,
      {String? token, Object? corpo, Uint8List? bytes}) async {
    final requisicao = http.Request(metodo, Uri.parse('$_enderecoBase$rota'));
    if (token != null) requisicao.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json';
      requisicao.body = jsonEncode(corpo);
    }
    if (bytes != null) {
      requisicao.headers['Content-Type'] = 'image/jpeg';
      requisicao.bodyBytes = bytes;
    }

    final http.Response resposta;
    try {
      resposta = await http.Response.fromStream(await _cliente.send(requisicao));
    } catch (_) {
      throw const FalhaNaApi('Sem conexão. Confira a internet e tente de novo.');
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return resposta.body.isEmpty ? null : jsonDecode(utf8.decode(resposta.bodyBytes));
    }
    var mensagem = 'Não deu certo. Tente de novo.';
    try {
      final erro = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (erro is Map && erro['mensagem'] is String) mensagem = erro['mensagem'] as String;
    } on FormatException {
      // Resposta sem corpo JSON: fica a mensagem genérica.
    }
    throw FalhaNaApi(mensagem, status: resposta.statusCode);
  }

  static String _codigo(String codigo) => codigo.trim().toUpperCase();
}
