import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

/// Uma frase de verdade (ou de mentira), não uma história (igual ao servidor).
const tamanhoDaAfirmacao = 60;

/// A pessoa da vez escreve as três frases e marca qual é a mentira.
class EscreverDuasVerdades extends StatefulWidget {
  const EscreverDuasVerdades({super.key, required this.acoes});

  final AcoesDaSala acoes;

  @override
  State<EscreverDuasVerdades> createState() => _EscreverDuasVerdadesState();
}

class _EscreverDuasVerdadesState extends State<EscreverDuasVerdades> {
  final _frases = List.generate(3, (_) => TextEditingController());
  int? _mentira;

  @override
  void dispose() {
    for (final frase in _frases) {
      frase.dispose();
    }
    super.dispose();
  }

  void _enviar() {
    final textos = [for (final frase in _frases) frase.text.trim()];
    if (textos.any((texto) => texto.isEmpty)) {
      avisar(context, 'Escreva as três frases.');
      return;
    }
    final mentira = _mentira;
    if (mentira == null) {
      avisar(context, 'Marque qual das três é a mentira.');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.acoes.escreverDuasVerdades(textos, mentira);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('É a sua vez! 🤥', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: EspacoBaralho.pequeno),
        const Text(
          'Escreva três frases sobre você: duas verdades e uma mentira. '
          'Marque a mentira; só você sabe qual é.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CoresBaralho.textoSecundario, height: 1.4),
        ),
        const SizedBox(height: EspacoBaralho.base),
        for (final (indice, frase) in _frases.indexed) ...[
          TextField(
            key: Key('afirmacao-escrever-$indice'),
            controller: frase,
            maxLength: tamanhoDaAfirmacao,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: 'Frase ${indice + 1}'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ChoiceChip(
              key: Key('marcar-mentira-$indice'),
              label: const Text('🤥 É a mentira'),
              selected: _mentira == indice,
              selectedColor: CoresBaralho.mentira.withValues(alpha: 0.25),
              onSelected: (_) => setState(() => _mentira = indice),
            ),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
        ],
        FilledButton(onPressed: _enviar, child: const Text('Mostrar para a turma')),
      ],
    );
  }
}

/// A turma espera a pessoa da vez escrever.
class EsperandoAsAfirmacoes extends StatelessWidget {
  const EsperandoAsAfirmacoes({super.key, required this.visao, required this.rodada});

  final VisaoDaSala visao;
  final Rodada rodada;

  @override
  Widget build(BuildContext context) {
    final daVez = visao.jogador(rodada.alvo ?? '');
    return Column(children: [
      if (daVez != null) AvatarDoJogador(jogador: daVez, tamanho: 96, destaque: CoresBaralho.mentira),
      const SizedBox(height: EspacoBaralho.medio),
      Text('${daVez?.nome ?? 'A pessoa da vez'} está escrevendo três frases…',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: EspacoBaralho.mini),
      const Text('Enquanto isso, preparem as perguntas para pegar a mentira. 🕵️',
          textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoSecundario)),
    ]);
  }
}

/// Para a pessoa da vez: as frases que ela mandou, com a mentira marcada.
class MinhasAfirmacoes extends StatelessWidget {
  const MinhasAfirmacoes({super.key, required this.rodada});

  final Rodada rodada;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (indice, frase) in rodada.afirmacoes.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
            child: Text(
              indice == rodada.minhaMentira ? '🤥 $frase' : frase,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: indice == rodada.minhaMentira ? CoresBaralho.mentira : CoresBaralho.texto,
              ),
            ),
          ),
      ],
    );
  }
}

/// Para a turma: as três frases, para votar em qual é a mentira.
class VotarNaMentira extends StatelessWidget {
  const VotarNaMentira({super.key, required this.rodada, required this.acoes});

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (indice, frase) in rodada.afirmacoes.indexed) ...[
          OutlinedButton(
            key: Key('afirmacao-$indice'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.base, vertical: EspacoBaralho.medio),
              backgroundColor: rodada.minhaResposta == '$indice' ? CoresBaralho.mentira.withValues(alpha: 0.18) : null,
              side: BorderSide(
                color: rodada.minhaResposta == '$indice' ? CoresBaralho.mentira : CoresBaralho.borda,
                width: rodada.minhaResposta == '$indice' ? 2 : 1,
              ),
            ),
            onPressed: () => acoes.responder('$indice'),
            child: Text(frase, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
        ],
      ],
    );
  }
}

/// A mentira aparece marcada, com os votos de cada frase e quem achou.
class RevelacaoDaMentira extends StatelessWidget {
  const RevelacaoDaMentira({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  String _nomes(List<String> ids) => ids.map((id) => visao.jogador(id)?.nome ?? '?').join(', ');

  @override
  Widget build(BuildContext context) {
    final daVez = visao.jogador(rodada.alvo ?? '');
    final acertaram = revelacao.acertaram;
    final erraram = revelacao.perderam;
    return Column(
      key: const Key('revelacao-mentira'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (indice, frase) in rodada.afirmacoes.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
            padding: const EdgeInsets.all(EspacoBaralho.medio),
            decoration: BoxDecoration(
              color: indice == revelacao.mentira ? CoresBaralho.mentira.withValues(alpha: 0.15) : CoresBaralho.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: indice == revelacao.mentira ? CoresBaralho.mentira : CoresBaralho.borda,
                width: indice == revelacao.mentira ? 2 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  indice == revelacao.mentira ? '🤥 $frase' : frase,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: indice == revelacao.mentira ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
              if (indice < revelacao.votosNasAfirmacoes.length)
                Text(
                  revelacao.votosNasAfirmacoes[indice] == 1 ? '1 voto' : '${revelacao.votosNasAfirmacoes[indice]} votos',
                  style: const TextStyle(color: CoresBaralho.textoApagado),
                ),
            ]),
          ),
        const SizedBox(height: EspacoBaralho.base),
        Text(
          revelacao.elogio
              ? paraASala(visao,
                  '🎭 Ninguém acertou! ${daVez?.nome ?? 'A pessoa da vez'} enganou a turma inteira e distribui goles.')
              : [
                  if (acertaram.isNotEmpty) '${acertaram.length == 1 ? 'Acertou' : 'Acertaram'}: ${_nomes(acertaram)}',
                  if (erraram.isNotEmpty)
                    '${erraram.length == 1 ? 'Errou e leva' : 'Erraram e levam'} 1 ponto: ${_nomes(erraram)}',
                ].join(' · '),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
