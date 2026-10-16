import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'carta_de_baralho.dart';
import 'sala.dart';
import 'visual.dart';

/// Bilhete, não textão (igual ao servidor).
const tamanhoDoBilhete = 20;

/// No lugar da carta, para quem está na foto: a pergunta só aparece na revelação.
class DeForaDoCorreio extends StatelessWidget {
  const DeForaDoCorreio({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: AspectRatio(
          aspectRatio: proporcaoDaCarta,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CoresBaralho.correio.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: CoresBaralho.correio, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(EspacoBaralho.grande),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📮', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: EspacoBaralho.base),
                  Text('Você está de fora desta rodada 🤫',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: EspacoBaralho.medio),
                  const Text(
                    'A turma está escrevendo bilhetes anônimos sobre você. '
                    'Aguarde: no fim, todo mundo lê junto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CoresBaralho.textoSecundario, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A foto de quem recebe o correio, grande, para a turma escrever olhando.
class _FotoDoCorreio extends StatelessWidget {
  const _FotoDoCorreio({required this.jogador, required this.titulo});

  final Jogador jogador;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AvatarDoJogador(
        key: const Key('foto-do-correio'),
        jogador: jogador,
        tamanho: 128,
        destaque: CoresBaralho.correio,
      ),
      const SizedBox(height: EspacoBaralho.medio),
      Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
    ]);
  }
}

/// Quem não está na foto escreve o bilhete.
class EscreverBilhete extends StatefulWidget {
  const EscreverBilhete({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<EscreverBilhete> createState() => _EscreverBilheteState();
}

class _EscreverBilheteState extends State<EscreverBilhete> {
  late final _bilhete = TextEditingController(text: widget.rodada.minhaResposta ?? '');

  @override
  void dispose() {
    _bilhete.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _bilhete.text.trim();
    if (texto.isEmpty) {
      avisar(context, 'Escreva o bilhete.');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.acoes.responder(texto);
  }

  @override
  Widget build(BuildContext context) {
    final alvo = widget.visao.jogador(widget.rodada.alvo ?? '');
    final enviado = widget.rodada.minhaResposta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alvo != null) _FotoDoCorreio(jogador: alvo, titulo: 'Para ${alvo.nome}'),
        const SizedBox(height: EspacoBaralho.base),
        Container(
          padding: const EdgeInsets.all(EspacoBaralho.medio),
          decoration: BoxDecoration(
            color: CoresBaralho.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CoresBaralho.borda),
          ),
          child: const Text(
            '🔒 Anônimo de verdade: ninguém vê quem escreveu o quê, nem quem criou a sala. '
            'Vale zoeira de amigo ou elogio. Cantada não vale 😉',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CoresBaralho.textoSecundario, height: 1.4),
          ),
        ),
        const SizedBox(height: EspacoBaralho.base),
        TextField(
          key: const Key('bilhete'),
          controller: _bilhete,
          maxLength: tamanhoDoBilhete,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _enviar(),
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: 'Curto e certeiro…'),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        FilledButton(
          onPressed: _enviar,
          child: Text(enviado == null ? 'Enviar bilhete' : 'Trocar bilhete'),
        ),
        if (enviado != null)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text('Seu bilhete: "$enviado" ✓',
                textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoApagado)),
          ),
      ],
    );
  }
}

/// Todo mundo, inclusive quem está na foto, lê os bilhetes. Quem está na
/// foto toca no favorito e a mesa inteira vê a estrelinha.
class RevelacaoDoCorreio extends StatelessWidget {
  const RevelacaoDoCorreio({
    super.key,
    required this.visao,
    required this.rodada,
    required this.revelacao,
    required this.acoes,
  });

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final alvo = visao.jogador(rodada.alvo ?? '');
    if (alvo == null) return const Text('Quem estava na foto saiu da sala. 🏃', textAlign: TextAlign.center);
    final souAlvo = visao.euId == alvo.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FotoDoCorreio(jogador: alvo, titulo: '📮 Correio para ${alvo.nome}'),
        Text(
          souAlvo ? 'Toque no seu bilhete favorito ⭐' : 'Bilhetes anônimos da turma',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.base),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.medio,
          runSpacing: EspacoBaralho.medio,
          children: [
            for (final (indice, bilhete) in revelacao.bilhetes.indexed)
              _Bilhete(
                texto: bilhete,
                inclinacao: indice.isEven ? -0.025 : 0.02,
                favorito: rodada.favorito == indice,
                aoTocar: souAlvo ? () => acoes.escolherFavorito(indice) : null,
              ),
          ],
        ),
        if (rodada.favorito != null)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.medio),
            child: Text('⭐ Favorito de ${alvo.nome}',
                textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar)),
          ),
      ],
    );
  }
}

/// Um papelzinho: o bilhete parece bilhete.
class _Bilhete extends StatelessWidget {
  const _Bilhete({required this.texto, required this.inclinacao, required this.favorito, required this.aoTocar});

  final String texto;
  final double inclinacao;
  final bool favorito;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: inclinacao,
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.base, vertical: EspacoBaralho.medio),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3C4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: favorito ? CoresBaralho.ambar : const Color(0xFFE8D58A), width: favorito ? 3 : 1),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(
            favorito ? '⭐ $texto' : texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF3A2A12), fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
