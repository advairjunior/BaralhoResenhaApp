import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../infraestrutura/api_baralho.dart';
import '../infraestrutura/assinatura_tempo_real.dart';
import '../infraestrutura/sessoes_locais.dart';
import '../tema/tema_baralho.dart';
import 'fim_da_noite.dart';
import 'inicio.dart';
import 'jogo.dart';
import 'lobby.dart';
import 'visual.dart';

/// Ações que as telas da sala disparam; cada uma devolve a sala atualizada.
abstract interface class AcoesDaSala {
  Future<void> configurar(ConfiguracaoDoJogo configuracao);
  Future<void> comecar();
  Future<void> responder(String resposta);
  Future<void> revelar();
  Future<void> proxima();
  Future<void> tirar();
  Future<void> marcarApontado(String jogadorId);
  Future<void> escolherFavorito(int indice);
  Future<void> marcarVacilo(String jogadorId);
  Future<void> resultadoDaMimica(int? vencedor);
  Future<void> iniciarCronometro();
  Future<void> usarCarta(CartaNaManga carta, String? alvo);
  Future<void> marcarPronto();
  Future<void> confirmarHistoria(String jogadorId);
  Future<void> marcarTravou(String jogadorId);
  Future<void> segurar();
  Future<void> passarSozinho();
  Future<void> alternarBebi();
  Future<void> trocarFoto(Uint8List foto);
  Future<void> definirPar(String? parId);
  Future<void> julgar({required bool acertou});
  Future<void> registrarMomento(Uint8List foto);
  Future<void> encerrar();
  Future<void> retomar();
  Future<Uint8List> baixarFoto(String endereco);
  Future<void> sair();
}

class TelaDaSala extends StatefulWidget {
  const TelaDaSala({
    super.key,
    required this.codigo,
    required this.api,
    required this.sessoes,
    this.intervaloDeReserva = const Duration(seconds: 6),
  });

  final String codigo;
  final ApiBaralho api;
  final SessoesLocais sessoes;

  /// O tempo real avisa na hora; a consulta periódica cobre a conexão que caiu.
  final Duration intervaloDeReserva;

  @override
  State<TelaDaSala> createState() => _TelaDaSalaState();
}

class _TelaDaSalaState extends State<TelaDaSala> implements AcoesDaSala {
  String? _token;
  VisaoDaSala? _visao;
  bool _carregando = true;
  bool _ocupado = false;
  AssinaturaTempoReal? _tempoReal;
  Timer? _reserva;

  String get _codigo => widget.codigo.toUpperCase();

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  @override
  void dispose() {
    _pararDeOuvir();
    super.dispose();
  }

  Future<void> _abrir() async {
    _token = await widget.sessoes.token(_codigo);
    if (_token == null) {
      if (mounted) setState(() => _carregando = false);
      return;
    }
    await _atualizar();
    if (!mounted || _token == null) return;
    _tempoReal = AssinaturaTempoReal(widget.api.enderecoTempoReal(_codigo), _atualizar);
    _reserva = Timer.periodic(widget.intervaloDeReserva, (_) => _atualizar());
  }

  void _pararDeOuvir() {
    _tempoReal?.encerrar();
    _tempoReal = null;
    _reserva?.cancel();
    _reserva = null;
  }

  Future<void> _atualizar() async {
    final token = _token;
    if (token == null) return;
    try {
      _mostrar(await widget.api.visao(_codigo, token));
    } on FalhaNaApi catch (falha) {
      if (falha.perdeuASala) await _perderASala();
    } finally {
      if (mounted && _carregando) setState(() => _carregando = false);
    }
  }

  Future<void> _perderASala() async {
    _pararDeOuvir();
    await widget.sessoes.esquecer(_codigo);
    if (!mounted) return;
    setState(() {
      _token = null;
      _visao = null;
    });
  }

  Future<void> _agir(Future<VisaoDaSala> Function(String token) acao) async {
    final token = _token;
    if (token == null || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      _mostrar(await acao(token));
    } on FalhaNaApi catch (falha) {
      if (falha.perdeuASala) {
        await _perderASala();
      } else if (mounted) {
        avisar(context, falha);
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  /// Desenha a visão nova e lembra a carta, para a próxima noite não começar por ela.
  void _mostrar(VisaoDaSala visao) {
    final carta = visao.rodada?.cartaId;
    if (carta != null && carta != _visao?.rodada?.cartaId) widget.sessoes.marcarVista(carta);
    if (visao.fase == FaseDaSala.lobby && !_vistasEnviadas) _enviarVistas();
    if (mounted) setState(() => _visao = visao);
  }

  /// Uma vez por sala: se alguém da turma já viu a carta, ela vai para o fim do monte.
  bool _vistasEnviadas = false;

  Future<void> _enviarVistas() async {
    _vistasEnviadas = true;
    final token = _token;
    final vistas = await widget.sessoes.cartasVistas();
    if (token == null || vistas.isEmpty) return;
    try {
      await widget.api.lembrarVistas(_codigo, token, vistas);
    } on FalhaNaApi {
      // Sem a memória deste celular a noite funciona igual; não vale atrapalhar.
    }
  }

  int get _rodada => _visao?.rodada?.numero ?? 0;

  @override
  Future<void> configurar(ConfiguracaoDoJogo configuracao) =>
      _agir((token) => widget.api.configurar(_codigo, token, configuracao));

  @override
  Future<void> comecar() => _agir(
      (token) async => widget.api.comecar(_codigo, token, vistas: await widget.sessoes.cartasVistas()));

  @override
  Future<void> responder(String resposta) =>
      _agir((token) => widget.api.responder(_codigo, token, _rodada, resposta));

  @override
  Future<void> revelar() => _agir((token) => widget.api.revelar(_codigo, token, _rodada));

  @override
  Future<void> proxima() => _agir((token) => widget.api.proxima(_codigo, token, _rodada));

  @override
  Future<void> marcarApontado(String jogadorId) =>
      _agir((token) => widget.api.marcarApontado(_codigo, token, _rodada, jogadorId));

  @override
  Future<void> escolherFavorito(int indice) =>
      _agir((token) => widget.api.escolherFavorito(_codigo, token, _rodada, indice));

  @override
  Future<void> marcarVacilo(String jogadorId) =>
      _agir((token) => widget.api.marcarVacilo(_codigo, token, _rodada, jogadorId));

  @override
  Future<void> resultadoDaMimica(int? vencedor) =>
      _agir((token) => widget.api.resultadoDaMimica(_codigo, token, _rodada, vencedor));

  @override
  Future<void> iniciarCronometro() => _agir((token) => widget.api.iniciarCronometro(_codigo, token, _rodada));

  @override
  Future<void> usarCarta(CartaNaManga carta, String? alvo) =>
      _agir((token) => widget.api.usarCarta(_codigo, token, _rodada, carta, alvo));

  @override
  Future<void> marcarPronto() => _agir((token) => widget.api.marcarPronto(_codigo, token, _rodada));

  @override
  Future<void> confirmarHistoria(String jogadorId) =>
      _agir((token) => widget.api.confirmarHistoria(_codigo, token, _rodada, jogadorId));

  @override
  Future<void> marcarTravou(String jogadorId) =>
      _agir((token) => widget.api.marcarTravou(_codigo, token, _rodada, jogadorId));

  @override
  Future<void> segurar() => _agir((token) => widget.api.segurar(_codigo, token, _rodada));

  @override
  Future<void> passarSozinho() => _agir((token) => widget.api.passarSozinho(_codigo, token, _rodada));

  @override
  Future<void> tirar() => _agir((token) => widget.api.tirar(_codigo, token, _rodada));

  @override
  Future<void> alternarBebi() => _agir((token) => widget.api.alternarBebi(_codigo, token, _rodada));

  @override
  Future<void> trocarFoto(Uint8List foto) => _agir((token) => widget.api.enviarFoto(_codigo, token, foto));

  @override
  Future<void> definirPar(String? parId) => _agir((token) => widget.api.definirPar(_codigo, token, parId));

  @override
  Future<void> julgar({required bool acertou}) =>
      _agir((token) => widget.api.julgar(_codigo, token, _rodada, acertou: acertou));

  @override
  Future<void> registrarMomento(Uint8List foto) =>
      _agir((token) => widget.api.registrarMomento(_codigo, token, _rodada, foto));

  @override
  Future<void> encerrar() => _agir((token) => widget.api.encerrar(_codigo, token));

  @override
  Future<void> retomar() => _agir((token) => widget.api.retomar(_codigo, token));

  @override
  Future<Uint8List> baixarFoto(String endereco) => widget.api.baixarFoto(endereco);

  @override
  Future<void> sair() async {
    final token = _token;
    _pararDeOuvir();
    if (token != null) {
      try {
        await widget.api.sair(_codigo, token);
      } on FalhaNaApi {
        // Se a sala já acabou, sair é só esquecer o código.
      }
    }
    await widget.sessoes.esquecer(_codigo);
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final visao = _visao;
    if (_token == null || visao == null) {
      return Inicio(api: widget.api, sessoes: widget.sessoes, codigoInicial: _codigo);
    }
    return AbsorbPointer(
      absorbing: _ocupado,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (visao.fase) {
          FaseDaSala.lobby => Lobby(key: const ValueKey('lobby'), visao: visao, acoes: this),
          FaseDaSala.fim => FimDaNoite(key: const ValueKey('fim'), visao: visao, acoes: this),
          _ => Jogo(key: const ValueKey('jogo'), visao: visao, acoes: this),
        },
      ),
    );
  }
}

/// Ponto de partida para confirmar a saída em qualquer tela da sala.
Future<void> confirmarSaida(BuildContext context, AcoesDaSala acoes) async {
  final sair = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sair da sala?'),
      content: const Text('Você sai do placar. Para voltar, é só entrar de novo com o código.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ficar')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sair', style: TextStyle(color: CoresBaralho.coral)),
        ),
      ],
    ),
  );
  if (sair == true) await acoes.sair();
}
