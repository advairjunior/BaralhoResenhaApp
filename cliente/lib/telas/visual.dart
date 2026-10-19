import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

extension VisualDoModo on ModoDeJogo {
  String get titulo => switch (this) {
        ModoDeJogo.euNunca => 'Eu Nunca',
        ModoDeJogo.maisProvavel => 'Quem é mais provável',
        ModoDeJogo.bebaSe => 'Beba se',
        ModoDeJogo.regraRelampago => 'Regra-relâmpago',
        ModoDeJogo.casaisEmJogo => 'Casais em Jogo',
        ModoDeJogo.tribunal => 'Tribunal da Turma',
        ModoDeJogo.elogios => 'Rodada de Elogios',
        ModoDeJogo.correio => 'Correio da Resenha',
        ModoDeJogo.imagemEAcao => 'Imagem e Ação',
        ModoDeJogo.jurados => 'Jurados',
        ModoDeJogo.musica => 'Roda de Música',
        ModoDeJogo.impostor => 'Impostor',
      };

  String get emoji => switch (this) {
        ModoDeJogo.euNunca => '🙊',
        ModoDeJogo.maisProvavel => '👉',
        ModoDeJogo.bebaSe => '🍺',
        ModoDeJogo.regraRelampago => '⚡',
        ModoDeJogo.casaisEmJogo => '💞',
        ModoDeJogo.tribunal => '⚖️',
        ModoDeJogo.elogios => '💛',
        ModoDeJogo.correio => '📮',
        ModoDeJogo.imagemEAcao => '🎭',
        ModoDeJogo.jurados => '⭐',
        ModoDeJogo.musica => '🎵',
        ModoDeJogo.impostor => '🕵️',
      };

  String get explicacao => switch (this) {
        ModoDeJogo.euNunca => 'Cada um responde em segredo. Quem já fez leva ponto; se a maioria fez, vira.',
        ModoDeJogo.maisProvavel => 'Às vezes a turma vota no celular (com suspense e foto), '
            'às vezes aponta no 3. Inclui os ⚔️ duelos e o ✊✋✌️ pedra, papel e tesoura.',
        ModoDeJogo.bebaSe => 'Cartas rápidas para a mesa inteira.',
        ModoDeJogo.regraRelampago => 'Uma regra maluca que vale por algumas cartas.',
        ModoDeJogo.casaisEmJogo => 'Um do casal responde, o outro adivinha. Aparece de vez em quando, '
            'como tempero. Marquem os pares na sala de espera.',
        ModoDeJogo.tribunal => 'A turma julga alguém da mesa, sim ou não, em segredo. Na zoeira, o sim '
            'condena; no elogio, o não condena e o sim faz o réu distribuir goles.',
        ModoDeJogo.elogios => 'Dinâmicas de elogio para alguém da mesa. Ninguém bebe: todo mundo sai se achando.',
        ModoDeJogo.correio => 'Alguém fica de fora e a turma escreve um bilhete curto e anônimo sobre a pessoa. '
            'No fim, todo mundo lê. Precisa de 4 pessoas.',
        ModoDeJogo.imagemEAcao => 'Mímica! Até 5 pessoas, uma faz para todos; de 6 a 8, dois times; '
            'com 9 ou mais, três. Só o mímico vê a palavra. Time que perde leva ponto.',
        ModoDeJogo.jurados => 'O app elege alguém e o resto dá nota de 1 a 5 estrelas, em segredo ("o quanto '
            'fulano se veste bem?"). Média alta distribui goles; média baixa leva ponto.',
        ModoDeJogo.musica => 'A carta dá o tema ("abertura de novela") e cada um canta na sua vez, na ordem '
            'sorteada. Travou, leva ponto.',
        ModoDeJogo.impostor => 'Todo mundo recebe a mesma palavra, menos um, que só sabe o tema. Cada um fala '
            'uma pista e a turma vota no impostor. Precisa de 4 pessoas.',
      };

  Color get cor => switch (this) {
        ModoDeJogo.euNunca => CoresBaralho.euNunca,
        ModoDeJogo.maisProvavel => CoresBaralho.maisProvavel,
        ModoDeJogo.bebaSe => CoresBaralho.bebaSe,
        ModoDeJogo.regraRelampago => CoresBaralho.relampago,
        ModoDeJogo.casaisEmJogo => CoresBaralho.casais,
        ModoDeJogo.tribunal => CoresBaralho.tribunal,
        ModoDeJogo.elogios => CoresBaralho.elogios,
        ModoDeJogo.correio => CoresBaralho.correio,
        ModoDeJogo.imagemEAcao => CoresBaralho.mimica,
        ModoDeJogo.jurados => CoresBaralho.jurados,
        ModoDeJogo.musica => CoresBaralho.musica,
        ModoDeJogo.impostor => CoresBaralho.impostor,
      };
}

extension VisualDoNivel on NivelDaCarta {
  String get titulo => switch (this) {
        NivelDaCarta.leve => 'Leve',
        NivelDaCarta.resenha => 'Resenha',
        NivelDaCarta.picante => 'Picante',
        NivelDaCarta.original => 'Baralho Original',
      };

  String get emoji => switch (this) {
        NivelDaCarta.leve => '🧃',
        NivelDaCarta.resenha => '🍺',
        NivelDaCarta.picante => '🌶️',
        NivelDaCarta.original => '🔥',
      };

  String get explicacao => switch (this) {
        NivelDaCarta.leve => 'Dá para jogar até com a família.',
        NivelDaCarta.resenha => 'Engraçado e constrangedor na medida certa.',
        NivelDaCarta.picante => 'Malícia e insinuação, sem baixaria.',
        NivelDaCarta.original => 'Pesado como os baralhos de loja. Só se a turma topar!',
      };
}

/// Selfie do jogador numa bolinha; sem selfie (ou se ela não carregar),
/// fica a inicial do nome.
class AvatarDoJogador extends StatelessWidget {
  const AvatarDoJogador({super.key, required this.jogador, this.tamanho = 40, this.destaque});

  final Jogador jogador;
  final double tamanho;
  final Color? destaque;

  static const _cores = [
    Color(0xFFFF6B5B), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final cor = _cores[jogador.nome.codeUnits.fold(0, (soma, letra) => soma + letra) % _cores.length];
    final inicial = Center(
      child: Text(
        jogador.nome.characters.first.toUpperCase(),
        style: TextStyle(fontSize: tamanho * 0.42, fontWeight: FontWeight.w600, color: CoresBaralho.texto),
      ),
    );
    final foto = jogador.foto;
    // Quem caiu da sala aparece apagado em toda a sala.
    return Opacity(
      opacity: jogador.conectado ? 1 : 0.4,
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor.withValues(alpha: 0.22),
          border: Border.all(color: destaque ?? cor, width: destaque == null ? 1.5 : 3),
        ),
        child: foto == null
            ? inicial
            : ClipOval(
                child: Image.network(
                  foto,
                  key: ValueKey(foto),
                  fit: BoxFit.cover,
                  width: tamanho,
                  height: tamanho,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => inicial,
                ),
              ),
      ),
    );
  }
}

void avisar(BuildContext context, Object erro) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(erro.toString())));
}
