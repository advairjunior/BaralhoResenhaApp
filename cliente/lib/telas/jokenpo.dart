import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

const _maos = {'pedra': '✊', 'papel': '✋', 'tesoura': '✌️'};
const _nomes = {'pedra': 'Pedra', 'papel': 'Papel', 'tesoura': 'Tesoura'};

/// Pedra, papel e tesoura: os dois do duelo escolhem em segredo; a turma torce.
class PainelDoJokenpo extends StatelessWidget {
  const PainelDoJokenpo({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final duelistas = [for (final id in rodada.duelistas) ?visao.jogador(id)];
    final souDuelista = rodada.duelistas.contains(visao.euId);
    final outro = duelistas.where((j) => j.id != visao.euId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rodada.empates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacoBaralho.medio),
            child: Text(
              'Deu empate (${_maos[rodada.empates.last]} x ${_maos[rodada.empates.last]})! Joguem de novo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final (indice, jogador) in duelistas.indexed) ...[
            if (indice > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: EspacoBaralho.base),
                child: Text('VS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            Column(children: [
              AvatarDoJogador(jogador: jogador, tamanho: 72, destaque: CoresBaralho.maisProvavel),
              Text(jogador.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(jogador.respondeu ? '✅ jogou' : 'pensando…',
                  style: const TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
            ]),
          ],
        ]),
        const SizedBox(height: EspacoBaralho.base),
        if (souDuelista) ...[
          Row(children: [
            for (final mao in _maos.keys) ...[
              if (mao != _maos.keys.first) const SizedBox(width: EspacoBaralho.pequeno),
              Expanded(child: _Mao(mao: mao, escolhida: rodada.minhaResposta == mao, aoTocar: () => acoes.responder(mao))),
            ],
          ]),
          if (rodada.minhaResposta != null)
            Padding(
              padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
              child: Text(
                outro?.respondeu ?? false
                    ? 'Escolhido! ${outro!.nome} já jogou também.'
                    : 'Escolhido! Esperando ${outro?.nome ?? 'o outro'}…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: CoresBaralho.textoApagado),
              ),
            ),
        ] else
          const Text('Torce aí! 📣',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        if (visao.souAnfitriao)
          TextButton(onPressed: acoes.proxima, child: const Text('Pular carta')),
      ],
    );
  }
}

class _Mao extends StatelessWidget {
  const _Mao({required this.mao, required this.escolhida, required this.aoTocar});

  final String mao;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final conteudo = Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_maos[mao]!, style: const TextStyle(fontSize: 34)),
      Text(_nomes[mao]!),
    ]);
    final estilo = ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)));
    return SizedBox(
      height: 96,
      child: escolhida
          ? FilledButton(key: Key('jogar-$mao'), style: estilo, onPressed: aoTocar, child: conteudo)
          : OutlinedButton(key: Key('jogar-$mao'), style: estilo, onPressed: aoTocar, child: conteudo),
    );
  }
}

/// As duas mãos lado a lado e quem venceu.
class RevelacaoDoJokenpo extends StatelessWidget {
  const RevelacaoDoJokenpo({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final vencedor = revelacao.escolhidos.isEmpty ? null : visao.jogador(revelacao.escolhidos.first);
    return Column(
      key: const Key('resultado-do-jokenpo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(vencedor == null ? 'Fim do duelo!' : '👑 ${vencedor.nome} venceu!',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: EspacoBaralho.base),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final jogador in [for (final id in rodada.duelistas) ?visao.jogador(id)])
              SizedBox(
                width: 140,
                child: Column(children: [
                  Text(_maos[revelacao.jogadas[jogador.id]] ?? '❔', style: const TextStyle(fontSize: 56)),
                  AvatarDoJogador(
                    jogador: jogador,
                    tamanho: 64,
                    destaque: jogador.id == vencedor?.id ? CoresBaralho.ambar : null,
                  ),
                  Text(jogador.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (revelacao.perderam.contains(jogador.id))
                    Text(destinoDoPego(visao, jogador),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: CoresBaralho.ambar)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}
