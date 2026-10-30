import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

/// ✍️ Quem escreveu?: a resposta do centro em destaque, as outras embaixo (sem autor)
/// e as fotos de todo mundo menos você para votar. Quem escreveu vota também, para
/// não se entregar.
class VotarNoAutor extends StatelessWidget {
  const VotarNoAutor({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final emJogo = rodada.fraseEmJogo;
    final frase = emJogo != null && emJogo < rodada.frases.length ? rodada.frases[emJogo] : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('frase-em-jogo'),
          padding: const EdgeInsets.all(EspacoBaralho.base),
          decoration: BoxDecoration(
            color: CoresBaralho.quemEscreveu.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CoresBaralho.quemEscreveu, width: 2),
          ),
          child: Column(children: [
            const Text('De quem é esta?', style: TextStyle(color: CoresBaralho.textoSecundario)),
            const SizedBox(height: EspacoBaralho.mini),
            Text('"$frase"',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ]),
        ),
        if (emJogo != null && emJogo == rodada.minhaFrase)
          const Padding(
            padding: EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text('🤫 É a sua! Vote em alguém mesmo assim, para ninguém desconfiar.',
                textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoSecundario)),
          ),
        const SizedBox(height: EspacoBaralho.base),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.pequeno,
          runSpacing: EspacoBaralho.pequeno,
          children: [
            for (final jogador in visao.jogadores)
              if (jogador.id != visao.euId)
                _Voto(
                  key: Key('votar-${jogador.id}'),
                  jogador: jogador,
                  escolhido: rodada.minhaResposta == jogador.id,
                  aoTocar: () => acoes.responder(jogador.id),
                ),
          ],
        ),
        if (rodada.frases.length > 1) ...[
          const SizedBox(height: EspacoBaralho.base),
          const Text('As outras respostas', textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoApagado)),
          for (final (indice, outra) in rodada.frases.indexed)
            if (indice != emJogo)
              Text('"$outra"', textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
        ],
      ],
    );
  }
}

class _Voto extends StatelessWidget {
  const _Voto({super.key, required this.jogador, required this.escolhido, required this.aoTocar});

  final Jogador jogador;
  final bool escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhido ? CoresBaralho.ambarEscuro : CoresBaralho.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: escolhido ? CoresBaralho.ambar : CoresBaralho.borda, width: escolhido ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EspacoBaralho.medio, horizontal: EspacoBaralho.pequeno),
            child: Column(children: [
              AvatarDoJogador(jogador: jogador, tamanho: 56),
              const SizedBox(height: EspacoBaralho.mini),
              Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Quem escreveu a do centro, quem acertou, quem errou, e as outras respostas (sem autor).
class RevelacaoDoQuemEscreveu extends StatelessWidget {
  const RevelacaoDoQuemEscreveu({super.key, required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  String _nomes(List<String> ids) => ids.map((id) => visao.jogador(id)?.nome ?? '?').join(', ');

  @override
  Widget build(BuildContext context) {
    final centro = revelacao.frases.where((f) => f.autor != null).firstOrNull;
    final autor = visao.jogador(centro?.autor ?? '');
    final nome = autor?.nome ?? 'Quem escreveu';
    final acertaram = revelacao.acertaram;
    final erraram = revelacao.perderam;
    return Column(
      key: const Key('quem-escreveu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (centro != null)
          Text('"${centro.texto}"',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: EspacoBaralho.medio),
        if (autor != null) Center(child: AvatarDoJogador(jogador: autor, tamanho: 88, destaque: CoresBaralho.quemEscreveu)),
        const SizedBox(height: EspacoBaralho.pequeno),
        Text('Quem escreveu: $nome', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: EspacoBaralho.medio),
        if (revelacao.escolhidos.isNotEmpty)
          Text(
            paraASala(visao, '🕵️ Ninguém descobriu! $nome escapou: ganha uma carta na manga e distribui goles.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (acertaram.isNotEmpty)
          Text('${acertaram.length == 1 ? 'Acertou' : 'Acertaram'}: ${_nomes(acertaram)}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.sucesso)),
        if (erraram.isNotEmpty)
          Text('${erraram.length == 1 ? 'Errou e leva' : 'Erraram e levam'} 1 ponto: ${_nomes(erraram)}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.coral)),
        if (revelacao.frases.length > 1) ...[
          const SizedBox(height: EspacoBaralho.base),
          const Text('As outras respostas (ninguém vai saber de quem são)',
              textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoApagado)),
          for (final frase in revelacao.frases)
            if (frase.autor == null)
              Text('"${frase.texto}"',
                  textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
        ],
      ],
    );
  }
}
