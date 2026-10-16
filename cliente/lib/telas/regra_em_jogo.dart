import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';
import 'visual.dart';

/// A regra-relâmpago valendo: o texto, a isca desta carta (entrevista,
/// pergunta, missão ou piada) e o vacilo. Regra de fala sem ninguém falando
/// é regra desperdiçada.
class RegraEmJogo extends StatefulWidget {
  const RegraEmJogo({super.key, required this.visao, required this.acoes, this.mostrarTexto = true});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  /// Na própria carta da regra o texto já aparece na carta.
  final bool mostrarTexto;

  @override
  State<RegraEmJogo> createState() => _RegraEmJogoState();
}

class _RegraEmJogoState extends State<RegraEmJogo> {
  bool _marcando = false;

  @override
  Widget build(BuildContext context) {
    final visao = widget.visao;
    final regra = visao.regra;
    final rodada = visao.rodada;
    if (regra == null || rodada == null) return const SizedBox.shrink();
    final vacilaram = [for (final id in rodada.vacilaram) ?visao.jogador(id)];
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.medio),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.relampago.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresBaralho.relampago.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mostrarTexto)
            Row(children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: EspacoBaralho.medio),
              Expanded(child: Text(regra.texto, style: const TextStyle(fontSize: 13, height: 1.35))),
              const SizedBox(width: EspacoBaralho.pequeno),
              Text(
                regra.rodadasRestantes == 1 ? 'última\ncarta' : 'mais ${regra.rodadasRestantes}\ncartas',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: CoresBaralho.textoSecundario),
              ),
            ]),
          if (regra.desafio case final desafio?) _Desafio(visao: visao, desafio: desafio, espaco: widget.mostrarTexto),
          if (vacilaram.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
              child: Text('🚨 Vacilou: ${vacilaram.map((j) => j.nome).join(', ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CoresBaralho.coral, fontWeight: FontWeight.w600)),
            ),
          if (visao.souAnfitriao) ...[
            TextButton(
              onPressed: () => setState(() => _marcando = !_marcando),
              child: Text(_marcando ? 'Pronto' : '🚨 Alguém vacilou?'),
            ),
            if (_marcando)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: EspacoBaralho.medio,
                runSpacing: EspacoBaralho.pequeno,
                children: [
                  for (final jogador in visao.jogadores)
                    GestureDetector(
                      key: Key('vacilou-${jogador.id}'),
                      onTap: () => widget.acoes.marcarVacilo(jogador.id),
                      child: SizedBox(
                        width: 64,
                        child: Column(children: [
                          AvatarDoJogador(
                            jogador: jogador,
                            tamanho: 44,
                            destaque: rodada.vacilaram.contains(jogador.id) ? CoresBaralho.coral : null,
                          ),
                          Text(jogador.nome,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _Desafio extends StatelessWidget {
  const _Desafio({required this.visao, required this.desafio, required this.espaco});

  final VisaoDaSala visao;
  final DesafioDaRegra desafio;
  final bool espaco;

  @override
  Widget build(BuildContext context) {
    final quem = visao.jogador(desafio.quem ?? '')?.nome ?? 'Alguém';
    final para = visao.jogador(desafio.para ?? '')?.nome ?? 'alguém';
    final (titulo, rodape) = switch (desafio.tipo) {
      IscaDaRegra.entrevista => ('🎤 $quem entrevista $para', '$para responde seguindo a regra!'),
      IscaDaRegra.conversa => ('🎤 Pergunta para $para', 'Responda seguindo a regra!'),
      IscaDaRegra.risada => ('😂 Missão de $quem: fazer $para rir', null),
      IscaDaRegra.mestre => ('❓ $quem pergunta para $para', null),
      IscaDaRegra.piada => ('🥁 $quem conta a piada', 'Quem rir ou não rir… a regra decide.'),
      IscaDaRegra.nenhuma => ('', null),
    };
    final varias = desafio.textos.length > 1;
    return Container(
      margin: EdgeInsets.only(top: espaco ? EspacoBaralho.medio : 0),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: EspacoBaralho.pequeno),
          for (final (indice, texto) in desafio.textos.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: EspacoBaralho.mini),
              child: Text(
                texto,
                key: varias ? ValueKey('pergunta-$indice') : null,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.35),
              ),
            ),
          if (rodape != null)
            Text(rodape,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CoresBaralho.textoSecundario)),
        ],
      ),
    );
  }
}
