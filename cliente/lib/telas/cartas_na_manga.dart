import 'dart:math';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'sala.dart';
import 'visual.dart';

extension VisualDaCartaNaManga on CartaNaManga {
  String get emoji => switch (this) {
    CartaNaManga.escudo => '🛡️',
    CartaNaManga.passaABola => '🎯',
    CartaNaManga.devolve => '↩️',
    CartaNaManga.batataQuente => '🥔',
    CartaNaManga.dobra => '✖️2',
  };

  String get titulo => switch (this) {
    CartaNaManga.escudo => 'Escudo',
    CartaNaManga.passaABola => 'Passa a bola',
    CartaNaManga.devolve => 'Devolve',
    CartaNaManga.batataQuente => 'Batata quente',
    CartaNaManga.dobra => 'Dobra',
  };

  String get explicacao => switch (this) {
    CartaNaManga.escudo => 'Cancela o que esta carta fez com você.',
    CartaNaManga.passaABola => 'O que esta carta fez com você vai para quem você escolher.',
    CartaNaManga.devolve => 'No duelo, o ponto volta para quem te venceu.',
    CartaNaManga.batataQuente => 'Vira dose com +1 gole em quem você escolher. A pessoa pode passar adiante!',
    CartaNaManga.dobra => 'Dobra o que esta carta fez com outra pessoa.',
  };

  String get quando => switch (this) {
    CartaNaManga.devolve => 'Quando você perde um duelo ou um pedra, papel e tesoura, depois do resultado.',
    CartaNaManga.dobra => 'Quando a carta da mesa pegou outra pessoa (não você).',
    _ =>
      'Quando a carta da mesa te pegar: no Beba se, depois do "Me pegou!"; '
          'nas votações, duelos, Tribunal e mímica, depois do resultado.',
  };

  String get exemplo => switch (this) {
    CartaNaManga.escudo => 'A carta mandou você beber 2? Escudo, e você não leva nada.',
    CartaNaManga.passaABola => 'O Tribunal te condenou? Passa a bola para a Bia, e ela leva no seu lugar.',
    CartaNaManga.devolve => 'Perdeu no pedra, papel e tesoura para o Caio? Devolve, e quem leva é ele.',
    CartaNaManga.batataQuente =>
      'Você levou 2 goles: joga no Caio, ele recebe 3. '
          'Se o Caio tiver uma batata, joga na Bia com 4…',
    CartaNaManga.dobra => 'O Caio levou 1 ponto? Dobra, e ele leva 2.',
  };

  /// A cor da moldura, como o naipe da carta.
  Color get cor => switch (this) {
    CartaNaManga.escudo => const Color(0xFF2F74E0),
    CartaNaManga.passaABola => const Color(0xFF1B8A5A),
    CartaNaManga.devolve => const Color(0xFF7446E8),
    CartaNaManga.batataQuente => const Color(0xFFE07A00),
    CartaNaManga.dobra => const Color(0xFFD9452A),
  };

  /// Precisa escolher em quem jogar?
  bool get temAlvo =>
      this == CartaNaManga.passaABola || this == CartaNaManga.batataQuente || this == CartaNaManga.dobra;
}

/// Por que a carta não pode ser usada agora (nulo: pode).
String? _impedimento(VisaoDaSala visao, Rodada rodada, CartaNaManga carta) {
  if (rodada.usos.any((uso) => uso.quem == visao.euId)) return 'Uma carta na manga por carta da mesa.';
  final fuiPego = rodada.pegos.contains(visao.euId);
  return switch (carta) {
    CartaNaManga.dobra when !rodada.pegos.any((id) => id != visao.euId) =>
      'A carta não pegou ninguém: não tem o que dobrar.',
    CartaNaManga.dobra => null,
    CartaNaManga.devolve when !(fuiPego && rodada.duelistas.contains(visao.euId) && rodada.revelacao != null) =>
      'Devolve só vale no duelo: o ponto volta para quem te venceu.',
    _ when !fuiPego => 'A carta não te pegou: guarde a sua para depois.',
    _ => null,
  };
}

/// A mão de quem está jogando, embaixo da carta.
class MinhaMao extends StatelessWidget {
  const MinhaMao({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  Future<void> _abrirFicha(BuildContext context, CartaNaManga carta) async {
    final impedimento = _impedimento(visao, rodada, carta);
    // Dobra só vale em quem a carta pegou; as outras, em qualquer um.
    final alvos = [
      for (final jogador in visao.jogadores)
        if (jogador.id != visao.euId && (carta != CartaNaManga.dobra || rodada.pegos.contains(jogador.id))) jogador,
    ];
    final escolha = await showModalBottomSheet<({bool usar, String? alvo})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Cartinha(carta: carta, largura: 132)),
              const SizedBox(height: EspacoBaralho.medio),
              const Text('O que faz', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(paraASala(visao, carta.explicacao), style: const TextStyle(height: 1.4)),
              const SizedBox(height: EspacoBaralho.medio),
              const Text('Quando dá para usar', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(paraASala(visao, carta.quando), style: const TextStyle(height: 1.4)),
              const SizedBox(height: EspacoBaralho.medio),
              const Text('Exemplo', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                paraASala(visao, carta.exemplo),
                style: const TextStyle(height: 1.4, color: CoresBaralho.textoSecundario),
              ),
              const SizedBox(height: EspacoBaralho.base),
              if (impedimento != null) ...[
                Text(
                  '⏳ $impedimento',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CoresBaralho.textoSecundario, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: EspacoBaralho.medio),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
              ] else if (carta.temAlvo) ...[
                const Text(
                  '✅ Dá para usar agora. Em quem jogar?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: EspacoBaralho.medio),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: EspacoBaralho.medio,
                  runSpacing: EspacoBaralho.medio,
                  children: [
                    for (final jogador in alvos)
                      GestureDetector(
                        key: Key('alvo-${jogador.id}'),
                        onTap: () => Navigator.pop(context, (usar: true, alvo: jogador.id)),
                        child: SizedBox(
                          width: 76,
                          child: Column(
                            children: [
                              AvatarDoJogador(jogador: jogador, tamanho: 56),
                              Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
              ] else ...[
                const Text(
                  '✅ Dá para usar agora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: EspacoBaralho.medio),
                FilledButton(
                  onPressed: () => Navigator.pop(context, (usar: true, alvo: null)),
                  child: Text('Usar ${carta.emoji}'),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
              ],
            ],
          ),
        ),
      ),
    );
    if (escolha?.usar == true) await acoes.usarCarta(carta, escolha!.alvo);
  }

  @override
  Widget build(BuildContext context) {
    if (!visao.configuracao.cartasNaManga || visao.minhaMao.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: EspacoBaralho.grande),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresBaralho.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('🃏 Sua mão', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                key: const Key('guia-das-cartas'),
                onPressed: () => abrirGuiaDasCartas(context, semAlcool: visao.configuracao.semAlcool),
                child: const Text('ⓘ Como funcionam'),
              ),
            ],
          ),
          const Text(
            'Toque numa carta para ver o que ela faz.',
            style: TextStyle(fontSize: 12, color: CoresBaralho.textoApagado),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
          const SizedBox(height: EspacoBaralho.pequeno),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (indice, carta) in visao.minhaMao.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Transform.rotate(
                    // Em leque, como na mão de verdade.
                    angle: (indice - (visao.minhaMao.length - 1) / 2) * 0.08,
                    child: Cartinha(
                      key: Key(
                        indice == visao.minhaMao.indexOf(carta) ? 'manga-${carta.name}' : 'manga-${carta.name}-$indice',
                      ),
                      carta: carta,
                      largura: 92,
                      podeUsar: _impedimento(visao, rodada, carta) == null,
                      aoTocar: () => _abrirFicha(context, carta),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// O que aconteceu de carta na manga nesta carta da mesa, para todo mundo ver.
class UsosDasCartas extends StatelessWidget {
  const UsosDasCartas({super.key, required this.visao, required this.rodada});

  final VisaoDaSala visao;
  final Rodada rodada;

  String _nome(String? id) => visao.jogador(id ?? '')?.nome ?? 'alguém';

  String _frase(UsoDeCarta uso) {
    final quem = _nome(uso.quem);
    final alvo = _nome(uso.alvo);
    return switch (uso.carta) {
      CartaNaManga.escudo => '🛡️ $quem usou Escudo!',
      CartaNaManga.passaABola => '🎯 $quem passou a bola para $alvo!',
      CartaNaManga.devolve => '↩️ $quem devolveu para $alvo!',
      CartaNaManga.batataQuente => paraASala(visao, '🥔 $quem jogou a batata quente em $alvo: ${uso.goles} goles!'),
      CartaNaManga.dobra => '✖️2 $quem dobrou a conta de $alvo!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final frases = [
      for (final uso in rodada.usos) _frase(uso),
      for (final id in rodada.ganharam) '🃏 ${_nome(id)} ganhou uma carta na manga',
    ];
    if (frases.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacoBaralho.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final frase in frases)
            Padding(
              padding: const EdgeInsets.only(bottom: EspacoBaralho.mini),
              child: Text(
                frase,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

/// Todas as cartas na manga e como ganhar mais.
Future<void> abrirGuiaDasCartas(BuildContext context, {bool semAlcool = false}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.8,
    maxChildSize: 0.95,
    // Coluna, não lista: todas as cartas ficam montadas (e o guia é curto).
    builder: (context, rolagem) => SingleChildScrollView(
      controller: rolagem,
      padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🃏 Cartas na manga', style: Theme.of(context).textTheme.titleLarge),
          const Text(
            'Estilo Uno: cada um guarda até 3 e usa na hora certa. Uma por pessoa a cada carta da mesa, '
            'e todo mundo vê quem usou o quê. Só você vê as suas.',
            style: TextStyle(color: CoresBaralho.textoSecundario, height: 1.4),
          ),
          const SizedBox(height: EspacoBaralho.base),
          for (final carta in CartaNaManga.values)
            Padding(
              padding: const EdgeInsets.only(bottom: EspacoBaralho.base),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Cartinha(carta: carta, largura: 64),
                  const SizedBox(width: EspacoBaralho.medio),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(carta.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text(
                          semAlcool ? semAlcoolNoTexto(carta.explicacao) : carta.explicacao,
                          style: const TextStyle(height: 1.4),
                        ),
                        Text(
                          semAlcool ? semAlcoolNoTexto(carta.quando) : carta.quando,
                          style: const TextStyle(fontSize: 12, height: 1.4, color: CoresBaralho.textoApagado),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Text('Como ganhar mais', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const Text(
            'Todo mundo começa com uma. Ganha mais quem vence duelo ou pedra, papel e tesoura, o time que '
            'acerta a mímica e quem a turma escolhe no elogio. A cada 10 cartas, quem está há mais tempo '
            'sem ganhar recebe uma.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: EspacoBaralho.base),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi 👍')),
        ],
      ),
    ),
  ),
);

/// Alguns navegadores desenham o 🛡️ e o ✖️ com uma cor só, a do texto (branca no tema
/// escuro). Com a cor da moldura, esses saem na cor da carta; emoji colorido ignora a cor.
Color _corDoEmoji(CartaNaManga carta) => carta.cor;

/// A carta na manga com cara de carta de baralho: papel claro, moldura na cor
/// da carta, o emoji grande e o nome. A que vale agora brilha.
class Cartinha extends StatelessWidget {
  const Cartinha({super.key, required this.carta, required this.largura, this.podeUsar, this.aoTocar});

  final CartaNaManga carta;
  final double largura;

  /// Nulo: só mostra (ficha e guia). Falso: apagada. Verdadeiro: brilha e diz "pode usar".
  final bool? podeUsar;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final altura = largura * 88 / 63;
    final apagada = podeUsar == false;
    final carta = this.carta;
    final corpo = Container(
      width: largura,
      height: altura,
      padding: EdgeInsets.all(largura * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(largura * 0.12),
        boxShadow: [
          BoxShadow(
            color: (podeUsar == true ? CoresBaralho.ambar : carta.cor).withValues(alpha: podeUsar == true ? 0.7 : 0.3),
            blurRadius: podeUsar == true ? 18 : 8,
            spreadRadius: podeUsar == true ? 1 : 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(largura * 0.08),
          border: Border.all(color: carta.cor, width: max(2, largura * 0.03)),
          color: carta.cor.withValues(alpha: 0.08),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 3,
              left: 4,
              child: Text(carta.emoji, style: TextStyle(fontSize: largura * 0.13, color: _corDoEmoji(carta))),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(2, largura * 0.1, 2, largura * (podeUsar == true ? 0.2 : 0.1)),
                // Encolhe para caber: nome de duas linhas numa cartinha pequena.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: largura * 0.8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(carta.emoji, style: TextStyle(fontSize: largura * 0.42, color: _corDoEmoji(carta))),
                        SizedBox(height: largura * 0.04),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            carta.titulo.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: largura * 0.105,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 1.1,
                              color: carta.cor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (podeUsar == true)
              Positioned(
                bottom: 3,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: CoresBaralho.ambar, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      'PODE USAR',
                      style: TextStyle(
                        fontSize: largura * 0.085,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF241812),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      button: aoTocar != null,
      label: carta.titulo,
      child: GestureDetector(
        onTap: aoTocar,
        child: Opacity(opacity: apagada ? 0.6 : 1, child: corpo),
      ),
    );
  }
}
