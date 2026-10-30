import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

/// Dá para uma piada, não para um textão (igual ao servidor).
const tamanhoDaFrase = 40;

/// Cada um completa a frase da carta em segredo.
class EscreverFrase extends StatefulWidget {
  const EscreverFrase({super.key, required this.rodada, required this.acoes});

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<EscreverFrase> createState() => _EscreverFraseState();
}

class _EscreverFraseState extends State<EscreverFrase> {
  late final _frase = TextEditingController(text: widget.rodada.minhaResposta ?? '');

  @override
  void dispose() {
    _frase.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _frase.text.trim();
    if (texto.isEmpty) {
      avisar(context, 'Escreva o fim da frase.');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.acoes.responder(texto);
  }

  @override
  Widget build(BuildContext context) {
    final enviada = widget.rodada.minhaResposta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '🔒 Ninguém sabe quem escreveu o quê. Só o autor da mais votada aparece.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: CoresBaralho.textoSecundario, height: 1.4),
        ),
        const SizedBox(height: EspacoBaralho.base),
        TextField(
          key: const Key('frase'),
          controller: _frase,
          maxLength: tamanhoDaFrase,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _enviar(),
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: '…complete aqui'),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        FilledButton(
          onPressed: _enviar,
          child: Text(enviada == null ? 'Enviar frase' : 'Trocar frase'),
        ),
        if (enviada != null)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text('Sua frase: "$enviada" ✓',
                textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoApagado)),
          ),
      ],
    );
  }
}

/// As frases, sem autor. A sua aparece marcada e não dá para votar nela.
class VotarNaFrase extends StatelessWidget {
  const VotarNaFrase({super.key, required this.rodada, required this.acoes});

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (indice, frase) in rodada.frases.indexed) ...[
          _BotaoDaFrase(
            key: Key('frase-$indice'),
            texto: indice == rodada.minhaFrase ? '$frase · a sua' : frase,
            escolhida: rodada.minhaResposta == '$indice',
            aoTocar: indice == rodada.minhaFrase ? null : () => acoes.responder('$indice'),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
        ],
      ],
    );
  }
}

class _BotaoDaFrase extends StatelessWidget {
  const _BotaoDaFrase({super.key, required this.texto, required this.escolhida, required this.aoTocar});

  final String texto;
  final bool escolhida;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhida ? CoresBaralho.frase.withValues(alpha: 0.18) : CoresBaralho.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: escolhida ? CoresBaralho.frase : CoresBaralho.borda, width: escolhida ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.base, vertical: EspacoBaralho.medio),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: aoTocar == null ? CoresBaralho.textoApagado : CoresBaralho.texto,
              fontWeight: escolhida ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

String _votos(int votos) => votos == 1 ? '1 voto' : '$votos votos';

/// A vencedora em destaque, com quem escreveu; as outras, anônimas, com os votos.
class RevelacaoDasFrases extends StatelessWidget {
  const RevelacaoDasFrases({super.key, required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final vencedoras = revelacao.frases.where((f) => f.autor != null).toList();
    final outras = revelacao.frases.where((f) => f.autor == null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vencedoras.isEmpty)
          const Text('Ninguém votou. 🤷', textAlign: TextAlign.center),
        for (final frase in vencedoras) ...[
          _Vencedora(visao: visao, frase: frase),
          const SizedBox(height: EspacoBaralho.base),
        ],
        if (outras.isNotEmpty) ...[
          const Text('As outras, anônimas:',
              textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoSecundario)),
          const SizedBox(height: EspacoBaralho.pequeno),
          for (final frase in outras)
            Padding(
              padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
              child: Row(children: [
                Expanded(child: Text(frase.texto, style: const TextStyle(fontSize: 16))),
                Text(_votos(frase.votos), style: const TextStyle(color: CoresBaralho.textoApagado)),
              ]),
            ),
        ],
      ],
    );
  }
}

class _Vencedora extends StatelessWidget {
  const _Vencedora({required this.visao, required this.frase});

  final VisaoDaSala visao;
  final FraseRevelada frase;

  @override
  Widget build(BuildContext context) {
    final autor = visao.jogador(frase.autor!);
    return Container(
      key: const Key('frase-vencedora'),
      padding: const EdgeInsets.all(EspacoBaralho.base),
      decoration: BoxDecoration(
        color: CoresBaralho.frase.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoresBaralho.frase, width: 2),
      ),
      child: Column(children: [
        if (autor != null) AvatarDoJogador(jogador: autor, tamanho: 72, destaque: CoresBaralho.frase),
        const SizedBox(height: EspacoBaralho.medio),
        Text(frase.texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: EspacoBaralho.mini),
        Text(_votos(frase.votos), style: const TextStyle(color: CoresBaralho.textoSecundario)),
        const SizedBox(height: EspacoBaralho.medio),
        Text(
          paraASala(visao, '✍️ ${autor?.nome ?? 'Quem escreveu'} escreveu a melhor e distribui goles!'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.frase, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
