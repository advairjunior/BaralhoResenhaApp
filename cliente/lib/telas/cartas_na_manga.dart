import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
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

  /// Precisa escolher em quem jogar?
  bool get temAlvo => this == CartaNaManga.passaABola || this == CartaNaManga.batataQuente || this == CartaNaManga.dobra;
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

  Future<void> _usar(BuildContext context, CartaNaManga carta) async {
    final impedimento = _impedimento(visao, rodada, carta);
    if (impedimento != null) {
      avisar(context, impedimento);
      return;
    }
    if (!carta.temAlvo) {
      final usar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${carta.emoji} ${carta.titulo}'),
          content: Text(carta.explicacao),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Guardar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Usar ${carta.emoji}'),
            ),
          ],
        ),
      );
      if (usar == true) await acoes.usarCarta(carta, null);
      return;
    }
    // Dobra só vale em quem a carta pegou; as outras, em qualquer um.
    final alvos = [
      for (final jogador in visao.jogadores)
        if (jogador.id != visao.euId && (carta != CartaNaManga.dobra || rodada.pegos.contains(jogador.id))) jogador,
    ];
    if (!context.mounted) return;
    final alvo = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${carta.emoji} ${carta.titulo}', style: Theme.of(context).textTheme.titleLarge),
            Text(carta.explicacao, style: const TextStyle(color: CoresBaralho.textoSecundario)),
            const SizedBox(height: EspacoBaralho.base),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: EspacoBaralho.medio,
              runSpacing: EspacoBaralho.medio,
              children: [
                for (final jogador in alvos)
                  GestureDetector(
                    key: Key('alvo-${jogador.id}'),
                    onTap: () => Navigator.pop(context, jogador.id),
                    child: SizedBox(
                      width: 76,
                      child: Column(children: [
                        AvatarDoJogador(jogador: jogador, tamanho: 56),
                        Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
    if (alvo != null) await acoes.usarCarta(carta, alvo);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('🃏 Suas cartas na manga', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: EspacoBaralho.pequeno),
        Wrap(spacing: EspacoBaralho.pequeno, runSpacing: EspacoBaralho.pequeno, children: [
          for (final (indice, carta) in visao.minhaMao.indexed)
            ActionChip(
              key: Key(indice == visao.minhaMao.indexOf(carta) ? 'manga-${carta.name}' : 'manga-${carta.name}-$indice'),
              avatar: Text(carta.emoji),
              label: Text(carta.titulo),
              backgroundColor:
                  _impedimento(visao, rodada, carta) == null ? CoresBaralho.ambarEscuro : CoresBaralho.superficieElevada,
              onPressed: () => _usar(context, carta),
            ),
        ]),
      ]),
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
      CartaNaManga.batataQuente => '🥔 $quem jogou a batata quente em $alvo: ${uso.goles} goles!',
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final frase in frases)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacoBaralho.mini),
            child: Text(frase,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
      ]),
    );
  }
}
