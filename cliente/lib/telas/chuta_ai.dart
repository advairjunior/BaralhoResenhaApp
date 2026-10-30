import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

/// "42,195" com vírgula, como a gente escreve; ano e número inteiro sem casas.
String numeroBr(num numero) =>
    numero == numero.roundToDouble() ? numero.round().toString() : numero.toString().replaceAll('.', ',');

/// Cada um chuta um número em segredo. Vírgula ou ponto, o que o teclado tiver.
class ChutarNumero extends StatefulWidget {
  const ChutarNumero({super.key, required this.rodada, required this.acoes});

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<ChutarNumero> createState() => _ChutarNumeroState();
}

class _ChutarNumeroState extends State<ChutarNumero> {
  final _chute = TextEditingController();

  @override
  void dispose() {
    _chute.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _chute.text.trim().replaceAll(',', '.');
    if (num.tryParse(texto) == null) {
      avisar(context, 'Chute um número.');
      return;
    }
    FocusScope.of(context).unfocus();
    _chute.clear();
    widget.acoes.responder(texto);
  }

  @override
  Widget build(BuildContext context) {
    final guardado = num.tryParse(widget.rodada.minhaResposta ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (guardado != null) ...[
          Text(
            'Seu chute: ${numeroBr(guardado)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CoresBaralho.chute),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
        ],
        TextField(
          key: const Key('chute'),
          controller: _chute,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]'))],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _enviar(),
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(hintText: guardado == null ? 'Seu chute' : 'Trocar o chute'),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        FilledButton(onPressed: _enviar, child: Text(guardado == null ? 'Chutar' : 'Trocar')),
      ],
    );
  }
}

/// A resposta certa em destaque e os chutes do mais perto para o mais longe.
class RevelacaoDosChutes extends StatelessWidget {
  const RevelacaoDosChutes({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  String _nomes(Iterable<String> ids) => ids.map((id) => visao.jogador(id)?.nome ?? '?').join(', ');

  String get _resumo => paraASala(visao, _resumoComBebida);

  String get _resumoComBebida {
    final perto = revelacao.escolhidos;
    final longe = revelacao.perderam;
    if (perto.isEmpty && longe.isEmpty) return 'Todo mundo chutou igual: ninguém bebe.';
    return [
      if (perto.isNotEmpty) 'Mais perto: ${_nomes(perto)} ${perto.length == 1 ? 'distribui' : 'distribuem'} goles',
      if (longe.isNotEmpty) 'Mais longe: ${_nomes(longe)} ${longe.length == 1 ? 'leva' : 'levam'} 1 ponto',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final certa = revelacao.respostaCerta;
    final naMosca = [for (final chute in revelacao.chutes) if (chute.valor == certa) chute.jogadorId];
    final ganharam = naMosca.where(rodada.ganharam.contains).toList();
    return Column(
      key: const Key('revelacao-chutes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Resposta certa', textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoSecundario)),
        if (certa != null)
          Text(
            numeroBr(certa),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: CoresBaralho.chute),
          ),
        if (naMosca.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text(
              ganharam.isNotEmpty
                  ? '🎯 Na mosca! ${_nomes(ganharam)} ${ganharam.length == 1 ? 'ganhou' : 'ganharam'} uma carta na manga.'
                  : '🎯 Na mosca, ${_nomes(naMosca)}!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: EspacoBaralho.base),
        for (final chute in revelacao.chutes)
          Container(
            margin: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
            padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio, vertical: EspacoBaralho.pequeno),
            decoration: BoxDecoration(
              color: CoresBaralho.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: revelacao.escolhidos.contains(chute.jogadorId)
                    ? CoresBaralho.sucesso
                    : revelacao.perderam.contains(chute.jogadorId)
                        ? CoresBaralho.coral
                        : CoresBaralho.borda,
                width: revelacao.escolhidos.contains(chute.jogadorId) || revelacao.perderam.contains(chute.jogadorId)
                    ? 2
                    : 1,
              ),
            ),
            child: Row(children: [
              if (visao.jogador(chute.jogadorId) case final jogador?)
                AvatarDoJogador(jogador: jogador, tamanho: 36),
              const SizedBox(width: EspacoBaralho.medio),
              Expanded(child: Text(visao.jogador(chute.jogadorId)?.nome ?? '?', style: const TextStyle(fontSize: 16))),
              Text(numeroBr(chute.valor), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
        const SizedBox(height: EspacoBaralho.base),
        Text(_resumo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
