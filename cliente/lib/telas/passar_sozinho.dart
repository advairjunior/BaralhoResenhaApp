import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';

/// Cartas sem resposta no celular (regra, elogios, aponta no 3): todo mundo
/// toca em "Pronto", porque o app não tem como saber quando acabou.
bool pedeProntoDeTodos(VisaoDaSala visao, Rodada rodada) =>
    visao.fase != FaseDaSala.revelada &&
    switch (rodada.modo) {
      ModoDeJogo.regraRelampago || ModoDeJogo.elogios => true,
      ModoDeJogo.maisProvavel => !rodada.votacao,
      _ => false,
    };

/// O botão de quem tem pendência e o texto de quem a mesa está esperando.
const _botaoDoMotivo = {
  MotivoPendente.beber: '🍺 Bebi ✓',
  MotivoPendente.historia: '🎤 Contei ✓',
  MotivoPendente.elogio: '💛 Distribuí ✓',
  MotivoPendente.correio: '📮 Li tudo ✓',
};
const _esperandoPor = {
  MotivoPendente.beber: 'beber 🍺',
  MotivoPendente.historia: 'contar a história 🎤',
  MotivoPendente.elogio: 'distribuir os goles 💛',
  MotivoPendente.correio: 'ler os bilhetes 📮',
};

/// Passar a carta sozinho: "Pronto ✓", quem falta, a contagem de 3 segundos e
/// o "Segura aí". Quem criou a sala segue podendo passar na mão.
class PassarSozinho extends StatefulWidget {
  const PassarSozinho({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<PassarSozinho> createState() => _PassarSozinhoState();
}

class _PassarSozinhoState extends State<PassarSozinho> {
  DateTime? _fim;
  Timer? _relogio;
  bool _pediu = false;

  @override
  void initState() {
    super.initState();
    _sincronizar();
  }

  @override
  void didUpdateWidget(PassarSozinho antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.rodada.passaEmMs != widget.rodada.passaEmMs) _sincronizar();
  }

  /// O servidor diz quanto falta; aqui vira um horário de fim neste celular.
  void _sincronizar() {
    _relogio?.cancel();
    final restante = widget.rodada.passaEmMs;
    _fim = restante == null ? null : clock.now().add(Duration(milliseconds: restante));
    if (restante == null) return;
    _relogio = Timer.periodic(const Duration(milliseconds: 200), (relogio) {
      if (!mounted) return relogio.cancel();
      setState(() {});
      if (_segundosQueFaltam == 0) {
        relogio.cancel();
        // Todo celular pede; o servidor passa uma vez só.
        if (!_pediu) {
          _pediu = true;
          widget.acoes.passarSozinho();
        }
      }
    });
  }

  int? get _segundosQueFaltam {
    final fim = _fim;
    if (fim == null) return null;
    final ms = fim.difference(clock.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visao = widget.visao;
    final rodada = widget.rodada;
    final bebaSe = rodada.modo == ModoDeJogo.bebaSe;
    final prontoDeTodos = pedeProntoDeTodos(visao, rodada);
    final casaisSemJulgar = rodada.modo == ModoDeJogo.casaisEmJogo && rodada.acertou == null;
    final aparece = visao.fase == FaseDaSala.revelada ? !casaisSemJulgar : bebaSe || prontoDeTodos;
    if (!visao.configuracao.passarSozinho || !aparece) return const SizedBox.shrink();
    final anfitriao = visao.anfitriao?.nome ?? 'Quem criou a sala';
    final faltam = [for (final jogador in visao.jogadores) if (!rodada.prontos.contains(jogador.id)) jogador.nome];
    final faltando = faltam.isEmpty ? '' : ' · falta ${faltam.join(', ')}';
    // No "conta essa", o "Contei" fica na fila de histórias, junto da foto.
    final contaEssa = rodada.revelacao?.contadores.isNotEmpty ?? false;
    final minha = rodada.pendentes
        .where((p) => p.jogadorId == visao.euId && !(contaEssa && p.motivo == MotivoPendente.historia))
        .firstOrNull;
    final esperando = [
      for (final pendente in rodada.pendentes)
        if (pendente.jogadorId != visao.euId)
          '${visao.jogador(pendente.jogadorId)?.nome ?? 'alguém'} ${_esperandoPor[pendente.motivo]}',
    ];

    final Widget conteudo;
    if (rodada.seguradaPor case final quem?) {
      conteudo = Text('⏸️ $quem segurou a carta. $anfitriao passa quando quiser.',
          textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario));
    } else if (_segundosQueFaltam case final segundos?) {
      conteudo = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(segundos > 0 ? 'Próxima carta em $segundos…' : 'Passando…',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CoresBaralho.ambar)),
        TextButton(onPressed: widget.acoes.segurar, child: const Text('⏸️ Segura aí')),
      ]);
    } else if (prontoDeTodos) {
      conteudo = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!rodada.prontos.contains(visao.euId))
          OutlinedButton(onPressed: widget.acoes.marcarPronto, child: const Text('Pronto ✓')),
        const SizedBox(height: EspacoBaralho.mini),
        Text('Prontos: ${rodada.prontos.length} de ${visao.jogadores.length}$faltando',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CoresBaralho.textoApagado)),
        const Text('Com todo mundo pronto, a carta passa sozinha.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
      ]);
    } else {
      // Beba se e revelação: só quem tem pendência confirma.
      conteudo = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (minha != null)
          FilledButton(onPressed: widget.acoes.marcarPronto, child: Text(_botaoDoMotivo[minha.motivo]!)),
        if (bebaSe && faltam.isNotEmpty)
          Text('Responderam: ${rodada.prontos.length} de ${visao.jogadores.length}$faltando',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CoresBaralho.textoApagado)),
        if (esperando.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.mini),
            child: Text('Esperando: ${esperando.join(', ')}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CoresBaralho.textoSecundario)),
          ),
      ]);
    }
    return Padding(padding: const EdgeInsets.only(top: EspacoBaralho.base), child: conteudo);
  }
}
