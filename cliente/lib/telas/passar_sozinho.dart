import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';

/// Pronto vale quando não há mais o que responder (igual ao servidor): depois
/// da revelação ou nas cartas que não pedem resposta no celular.
bool podeFicarPronto(VisaoDaSala visao, Rodada rodada) => visao.fase == FaseDaSala.revelada
    ? rodada.modo != ModoDeJogo.casaisEmJogo || rodada.acertou != null
    : switch (rodada.modo) {
        ModoDeJogo.bebaSe || ModoDeJogo.regraRelampago || ModoDeJogo.elogios => true,
        ModoDeJogo.maisProvavel => !rodada.votacao,
        _ => false,
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
    if (!visao.configuracao.passarSozinho || !podeFicarPronto(visao, rodada)) return const SizedBox.shrink();
    final anfitriao = visao.anfitriao?.nome ?? 'Quem criou a sala';
    final faltam = [for (final jogador in visao.jogadores) if (!rodada.prontos.contains(jogador.id)) jogador.nome];
    final bebaSe = rodada.modo == ModoDeJogo.bebaSe;
    final faltando = faltam.isEmpty ? '' : ' · falta ${faltam.join(', ')}';

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
    } else {
      conteudo = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // No Beba se, "Me pegou" e "Não me pegou" já respondem.
        if (!bebaSe && !rodada.prontos.contains(visao.euId))
          OutlinedButton(onPressed: widget.acoes.marcarPronto, child: const Text('Pronto ✓')),
        const SizedBox(height: EspacoBaralho.mini),
        Text(
          '${bebaSe ? 'Responderam' : 'Prontos'}: ${rodada.prontos.length} de ${visao.jogadores.length}$faltando',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: CoresBaralho.textoApagado),
        ),
        const Text('Com todo mundo pronto, a carta passa sozinha.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
      ]);
    }
    return Padding(padding: const EdgeInsets.only(top: EspacoBaralho.base), child: conteudo);
  }
}
