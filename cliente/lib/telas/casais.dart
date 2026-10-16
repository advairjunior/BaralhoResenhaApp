import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

/// Casais em Jogo, antes da revelação: o alvo escreve a verdade, o par
/// escreve o chute e o resto da mesa assiste.
class RespostaDoCasal extends StatefulWidget {
  const RespostaDoCasal({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<RespostaDoCasal> createState() => _RespostaDoCasalState();
}

class _RespostaDoCasalState extends State<RespostaDoCasal> {
  late final _resposta = TextEditingController(text: widget.rodada.minhaResposta ?? '');

  @override
  void dispose() {
    _resposta.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _resposta.text.trim();
    if (texto.isEmpty) {
      avisar(context, 'Escreva sua resposta.');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.acoes.responder(texto);
  }

  @override
  Widget build(BuildContext context) {
    final visao = widget.visao;
    final rodada = widget.rodada;
    final palpiteiro = visao.jogador(rodada.palpiteiro ?? '');
    final alvo = visao.jogador(rodada.alvo ?? '');
    final Widget pular = visao.souAnfitriao
        ? TextButton(onPressed: widget.acoes.proxima, child: const Text('Pular carta'))
        : const SizedBox.shrink();
    if (palpiteiro == null || alvo == null) {
      return Column(children: [const Text('O casal da vez saiu da sala.'), pular]);
    }

    final souAlvo = visao.euId == alvo.id;
    final souPalpiteiro = visao.euId == palpiteiro.id;
    final jaRespondi = rodada.minhaResposta != null;
    final outro = souAlvo ? palpiteiro : alvo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DuelaDoCasal(palpiteiro: palpiteiro, alvo: alvo),
        const SizedBox(height: EspacoBaralho.grande),
        if (souAlvo || souPalpiteiro) ...[
          Text(
            souAlvo
                ? 'A pergunta é sobre você. Responda a verdade, em segredo:'
                : 'Tente adivinhar o que ${alvo.nome} vai responder:',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoSecundario),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          TextField(
            key: const Key('resposta-do-casal'),
            controller: _resposta,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _enviar(),
            decoration: InputDecoration(
              hintText: souAlvo ? 'A verdade, só a verdade…' : 'Seu chute…',
              counterText: '',
            ),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          FilledButton(onPressed: _enviar, child: Text(jaRespondi ? 'Trocar resposta' : 'Enviar')),
          if (jaRespondi)
            Padding(
              padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
              child: Text(
                outro.respondeu ? 'Revelando…' : 'Guardado! Esperando ${outro.nome}…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: CoresBaralho.textoApagado),
              ),
            ),
        ] else ...[
          const Text(
            'Vez do casal! Pega a pipoca 🍿',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
          Text(
            [
              '${palpiteiro.nome} ${palpiteiro.respondeu ? '✓ chutou' : 'pensando…'}',
              '${alvo.nome} ${alvo.respondeu ? '✓ respondeu' : 'pensando…'}',
            ].join('   ·   '),
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoSecundario),
          ),
        ],
        const SizedBox(height: EspacoBaralho.medio),
        pular,
      ],
    );
  }
}

/// Os dois do casal frente a frente.
class _DuelaDoCasal extends StatelessWidget {
  const _DuelaDoCasal({required this.palpiteiro, required this.alvo});

  final Jogador palpiteiro;
  final Jogador alvo;

  @override
  Widget build(BuildContext context) {
    Widget pessoa(Jogador jogador, String papel) => SizedBox(
          width: 110,
          child: Column(children: [
            AvatarDoJogador(jogador: jogador, tamanho: 72, destaque: CoresBaralho.casais),
            const SizedBox(height: EspacoBaralho.mini),
            Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(papel, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pessoa(palpiteiro, 'tenta adivinhar'),
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text('💞', style: TextStyle(fontSize: 28)),
        ),
        pessoa(alvo, 'diz a verdade'),
      ],
    );
  }
}

/// Casais em Jogo revelado: a verdade, o chute e o julgamento do alvo.
class RevelacaoDoCasal extends StatelessWidget {
  const RevelacaoDoCasal({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final revelacao = rodada.revelacao!;
    final palpiteiro = visao.jogador(rodada.palpiteiro ?? '');
    final alvo = visao.jogador(rodada.alvo ?? '');
    final nomeDoAlvo = alvo?.nome ?? 'Quem respondeu';
    final nomeDoPalpiteiro = palpiteiro?.nome ?? 'O par';

    final julgamento = switch (rodada.acertou) {
      null when visao.euId == rodada.alvo => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('E aí, acertou?', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: EspacoBaralho.medio),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: CoresBaralho.casais),
                    onPressed: () => acoes.julgar(acertou: true),
                    child: const Text('💞 Acertou!'),
                  ),
                ),
              ),
              const SizedBox(width: EspacoBaralho.medio),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () => acoes.julgar(acertou: false),
                    child: const Text('😬 Errou'),
                  ),
                ),
              ),
            ]),
          ],
        ),
      null => Text('$nomeDoAlvo está julgando… 🧑‍⚖️', textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario, fontSize: 16)),
      true => const _Veredito(emoji: '💞', titulo: 'Acertou!', detalhe: 'Isso é que é sintonia de casal.'),
      false => _Veredito(
          emoji: '😬',
          titulo: 'Errou!',
          detalhe: palpiteiro == null
              ? 'Precisam conversar mais…'
              : '$nomeDoPalpiteiro ${destinoDoPego(visao, palpiteiro)}',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Resposta(rotulo: '$nomeDoAlvo respondeu', texto: revelacao.respostaDoAlvo ?? '', cor: CoresBaralho.casais),
        const SizedBox(height: EspacoBaralho.medio),
        _Resposta(rotulo: '$nomeDoPalpiteiro chutou', texto: revelacao.palpiteDoPar ?? '', cor: CoresBaralho.ambar),
        const SizedBox(height: EspacoBaralho.grande),
        julgamento,
      ],
    );
  }
}

class _Resposta extends StatelessWidget {
  const _Resposta({required this.rotulo, required this.texto, required this.cor});

  final String rotulo;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EspacoBaralho.base),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: EspacoBaralho.mini),
          Text('“$texto”', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3)),
        ],
      ),
    );
  }
}

class _Veredito extends StatelessWidget {
  const _Veredito({required this.emoji, required this.titulo, required this.detalhe});

  final String emoji;
  final String titulo;
  final String detalhe;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 48)),
      Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
      Text(detalhe, textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
    ]);
  }
}
