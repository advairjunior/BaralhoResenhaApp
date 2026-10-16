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

  String get quando => switch (this) {
        CartaNaManga.devolve => 'Quando você perde um duelo ou um pedra, papel e tesoura, depois do resultado.',
        CartaNaManga.dobra => 'Quando a carta da mesa pegou outra pessoa (não você).',
        _ => 'Quando a carta da mesa te pegar: no Beba se, depois do "Me pegou!"; '
            'nas votações, duelos, Tribunal e mímica, depois do resultado.',
      };

  String get exemplo => switch (this) {
        CartaNaManga.escudo => 'A carta mandou você beber 2? Escudo, e você não leva nada.',
        CartaNaManga.passaABola => 'O Tribunal te condenou? Passa a bola para a Bia, e ela leva no seu lugar.',
        CartaNaManga.devolve => 'Perdeu no pedra, papel e tesoura para o Caio? Devolve, e quem leva é ele.',
        CartaNaManga.batataQuente => 'Você levou 2 goles: joga no Caio, ele recebe 3. '
            'Se o Caio tiver uma batata, joga na Bia com 4…',
        CartaNaManga.dobra => 'O Caio levou 1 ponto? Dobra, e ele leva 2.',
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
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${carta.emoji} ${carta.titulo}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: EspacoBaralho.medio),
            const Text('O que faz', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(carta.explicacao, style: const TextStyle(height: 1.4)),
            const SizedBox(height: EspacoBaralho.medio),
            const Text('Quando dá para usar', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(carta.quando, style: const TextStyle(height: 1.4)),
            const SizedBox(height: EspacoBaralho.medio),
            const Text('Exemplo', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(carta.exemplo, style: const TextStyle(height: 1.4, color: CoresBaralho.textoSecundario)),
            const SizedBox(height: EspacoBaralho.base),
            if (impedimento != null) ...[
              Text('⏳ $impedimento',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CoresBaralho.textoSecundario, fontWeight: FontWeight.w600)),
              const SizedBox(height: EspacoBaralho.medio),
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
            ] else if (carta.temAlvo) ...[
              const Text('✅ Dá para usar agora. Em quem jogar?',
                  textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600)),
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
                        child: Column(children: [
                          AvatarDoJogador(jogador: jogador, tamanho: 56),
                          Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ),
                ],
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
            ] else ...[
              const Text('✅ Dá para usar agora.',
                  textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600)),
              const SizedBox(height: EspacoBaralho.medio),
              FilledButton(
                onPressed: () => Navigator.pop(context, (usar: true, alvo: null)),
                child: Text('Usar ${carta.emoji}'),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar para depois')),
            ],
          ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('🃏 Suas cartas na manga', style: TextStyle(fontWeight: FontWeight.w600))),
          TextButton(
            key: const Key('guia-das-cartas'),
            onPressed: () => abrirGuiaDasCartas(context),
            child: const Text('ⓘ Como funcionam'),
          ),
        ]),
        const Text('Toque numa carta para ver o que ela faz.',
            style: TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
        const SizedBox(height: EspacoBaralho.pequeno),
        Wrap(spacing: EspacoBaralho.pequeno, runSpacing: EspacoBaralho.pequeno, children: [
          for (final (indice, carta) in visao.minhaMao.indexed)
            ActionChip(
              key: Key(indice == visao.minhaMao.indexOf(carta) ? 'manga-${carta.name}' : 'manga-${carta.name}-$indice'),
              avatar: Text(carta.emoji),
              label: Text(carta.titulo),
              backgroundColor:
                  _impedimento(visao, rodada, carta) == null ? CoresBaralho.ambarEscuro : CoresBaralho.superficieElevada,
              onPressed: () => _abrirFicha(context, carta),
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

/// Todas as cartas na manga e como ganhar mais.
Future<void> abrirGuiaDasCartas(BuildContext context) => showModalBottomSheet<void>(
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${carta.emoji} ${carta.titulo}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(carta.explicacao, style: const TextStyle(height: 1.4)),
                  Text('Quando: ${carta.quando}',
                      style: const TextStyle(fontSize: 12, height: 1.4, color: CoresBaralho.textoApagado)),
                ]),
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
          ]),
        ),
      ),
    );
