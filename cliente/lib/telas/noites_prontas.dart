import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

/// Uma noite já configurada: nível, jogos e ritmo num toque só.
class NoitePronta {
  const NoitePronta({
    required this.chave,
    required this.emoji,
    required this.titulo,
    required this.descricao,
    required this.configuracao,
  });

  final String chave;
  final String emoji;
  final String titulo;
  final String descricao;
  final ConfiguracaoDoJogo configuracao;

  /// A configuração da sala é exatamente esta noite?
  bool combina(ConfiguracaoDoJogo outra) =>
      outra.nivel == configuracao.nivel &&
      outra.zonaSegura == configuracao.zonaSegura &&
      outra.esquentar == configuracao.esquentar &&
      outra.ritmo == configuracao.ritmo &&
      outra.cartasNaManga == configuracao.cartasNaManga &&
      outra.passarSozinho == configuracao.passarSozinho &&
      outra.modos.length == configuracao.modos.length &&
      outra.modos.containsAll(configuracao.modos);
}

/// Casais em Jogo fica de fora de todas: quem quiser, liga na mão.
const noitesProntas = [
  NoitePronta(
    chave: 'classica',
    emoji: '🍻',
    titulo: 'Resenha clássica',
    descricao: 'Eu Nunca, votação, Beba se, Tribunal e regras-relâmpago.',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.resenha,
      modos: {
        ModoDeJogo.euNunca,
        ModoDeJogo.maisProvavel,
        ModoDeJogo.bebaSe,
        ModoDeJogo.regraRelampago,
        ModoDeJogo.tribunal,
      },
      zonaSegura: true,
    ),
  ),
  NoitePronta(
    chave: 'esquenta',
    emoji: '🌡️',
    titulo: 'Esquenta até o Picante',
    descricao: 'Começa leve e esquenta sozinho a cada 8 cartas.',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.picante,
      modos: {
        ModoDeJogo.euNunca,
        ModoDeJogo.maisProvavel,
        ModoDeJogo.bebaSe,
        ModoDeJogo.regraRelampago,
        ModoDeJogo.tribunal,
        ModoDeJogo.correio,
      },
      zonaSegura: true,
      esquentar: true,
    ),
  ),
  NoitePronta(
    chave: 'brincadeiras',
    emoji: '🎭',
    titulo: 'Noite das brincadeiras',
    descricao: 'Mímica, duelos, Correio e regras com isca. Mais rir que beber.',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.resenha,
      modos: {
        ModoDeJogo.maisProvavel,
        ModoDeJogo.regraRelampago,
        ModoDeJogo.elogios,
        ModoDeJogo.correio,
        ModoDeJogo.imagemEAcao,
      },
      zonaSegura: true,
    ),
  ),
  NoitePronta(
    chave: 'zoeira',
    emoji: '😂',
    titulo: 'Só zoeira',
    descricao: 'Tribunal, votação, Correio e Beba se, no ritmo normal.',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.resenha,
      modos: {
        ModoDeJogo.maisProvavel,
        ModoDeJogo.bebaSe,
        ModoDeJogo.regraRelampago,
        ModoDeJogo.tribunal,
        ModoDeJogo.correio,
      },
      zonaSegura: true,
      ritmo: RitmoDaBebida.normal,
    ),
  ),
  NoitePronta(
    chave: 'tranquila',
    emoji: '💛',
    titulo: 'Noite tranquila',
    descricao: 'Leve, com elogios, mímica e Correio. Dá até para jogar sem beber.',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.leve,
      modos: {
        ModoDeJogo.euNunca,
        ModoDeJogo.maisProvavel,
        ModoDeJogo.elogios,
        ModoDeJogo.correio,
        ModoDeJogo.imagemEAcao,
      },
      zonaSegura: true,
    ),
  ),
  NoitePronta(
    chave: 'raiz',
    emoji: '🔥',
    titulo: 'Raiz',
    descricao: 'Baralho Original e todo ponto é gole. Só se a turma topar!',
    configuracao: ConfiguracaoDoJogo(
      nivel: NivelDaCarta.original,
      modos: {
        ModoDeJogo.euNunca,
        ModoDeJogo.maisProvavel,
        ModoDeJogo.bebaSe,
        ModoDeJogo.regraRelampago,
        ModoDeJogo.tribunal,
      },
      zonaSegura: true,
      ritmo: RitmoDaBebida.raiz,
    ),
  ),
];

/// As noites prontas, em cartões. A que combina com a sala aparece marcada.
class NoitesProntas extends StatelessWidget {
  const NoitesProntas({super.key, required this.configuracao, required this.aoEscolher});

  final ConfiguracaoDoJogo configuracao;

  /// Nulo para quem só vê (não criou a sala).
  final ValueChanged<NoitePronta>? aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final noite in noitesProntas)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
            child: _CartaoDaNoite(
              noite: noite,
              escolhida: noite.combina(configuracao),
              aoTocar: aoEscolher == null ? null : () => aoEscolher!(noite),
            ),
          ),
      ],
    );
  }
}

class _CartaoDaNoite extends StatelessWidget {
  const _CartaoDaNoite({required this.noite, required this.escolhida, required this.aoTocar});

  final NoitePronta noite;
  final bool escolhida;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhida ? CoresBaralho.ambarEscuro : CoresBaralho.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: escolhida ? CoresBaralho.ambar : CoresBaralho.borda, width: escolhida ? 2 : 1),
      ),
      child: InkWell(
        key: Key('noite-${noite.chave}'),
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio, vertical: EspacoBaralho.pequeno + 2),
          child: Row(
            children: [
              Text(noite.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: EspacoBaralho.medio),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      escolhida ? '✓ ${noite.titulo}' : noite.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      noite.descricao,
                      style: const TextStyle(fontSize: 12, height: 1.3, color: CoresBaralho.textoSecundario),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
