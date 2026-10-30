import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'cronometro.dart';
import 'sala.dart';
import 'visual.dart';

/// Cor de cada time, na ordem em que o servidor manda.
const coresDosTimes = ['🔴', '🔵', '🟢'];

/// Imagem e Ação (e Palavra proibida) antes do resultado: a palavra (só para quem
/// faz a mímica ou explica), os times, o cronômetro e, para quem criou a sala, quem acertou.
class PainelDaMimica extends StatelessWidget {
  const PainelDaMimica({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final souMimico = rodada.times.any((t) => t.mimico == visao.euId);
    final umaPessoaSo = rodada.times.length == 1;
    final palavra = rodada.modo == ModoDeJogo.palavraProibida;
    final quem = umaPessoaSo ? visao.jogador(rodada.times.single.mimico)?.nome ?? 'Alguém' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (souMimico) ...[
          Text(palavra ? '🤫 Só quem explica vê a palavra' : '🤫 Só você e os outros mímicos veem a palavra',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
          if (palavra) ...[
            const SizedBox(height: EspacoBaralho.pequeno),
            const Text('🚫 Não pode dizer:',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: EspacoBaralho.mini),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: EspacoBaralho.pequeno,
              runSpacing: EspacoBaralho.pequeno,
              children: [
                for (final proibida in rodada.proibidas)
                  Chip(
                    label: Text(proibida, style: const TextStyle(fontWeight: FontWeight.w700)),
                    side: const BorderSide(color: CoresBaralho.coral),
                  ),
              ],
            ),
          ],
          if (rodada.dica case final dica?)
            Text('Pode dizer: $dica',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(
              palavra
                  ? 'Não vale dizer a palavra, as proibidas, pedaços delas nem fazer mímica.'
                  : 'Não vale falar a palavra, soletrar nem apontar para objetos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
          const SizedBox(height: EspacoBaralho.base),
        ],
        if (umaPessoaSo)
          Text(
            palavra ? '🗣️ $quem explica para todo mundo' : '🎭 $quem faz a mímica para todo mundo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          )
        else
          for (final (indice, time) in rodada.times.indexed) _Time(visao: visao, time: time, indice: indice, palavra: palavra),
        const SizedBox(height: EspacoBaralho.base),
        Cronometro(key: ValueKey('mimica-${rodada.numero}'), visao: visao, rodada: rodada, aoIniciar: acoes.iniciarCronometro),
        if (visao.souAnfitriao) ...[
          if (umaPessoaSo)
            FilledButton(onPressed: () => acoes.resultadoDaMimica(0), child: const Text('✅ Acertaram!'))
          else
            for (final (indice, time) in rodada.times.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
                child: FilledButton(
                  onPressed: () => acoes.resultadoDaMimica(indice),
                  child: Text('${coresDosTimes[indice]} Time de${_de(visao, time)} acertou!'),
                ),
              ),
          TextButton(onPressed: () => acoes.resultadoDaMimica(null), child: const Text('⏰ Ninguém acertou')),
          TextButton(onPressed: acoes.proxima, child: const Text('Pular carta')),
        ] else
          Text(
            '${visao.anfitriao?.nome ?? 'Quem criou a sala'} marca quem acertou primeiro',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoApagado),
          ),
      ],
    );
  }
}

/// " Caio" ou " Bia", com o espaço: "Time de Bia" (sem adivinhar gênero).
String _de(VisaoDaSala visao, TimeDaMimica time) => ' ${visao.jogador(time.mimico)?.nome ?? 'mímico'}';

class _Time extends StatelessWidget {
  const _Time({required this.visao, required this.time, required this.indice, required this.palavra});

  final VisaoDaSala visao;
  final TimeDaMimica time;
  final int indice;

  /// Palavra proibida: quem está no lugar do mímico explica.
  final bool palavra;

  @override
  Widget build(BuildContext context) {
    final meu = time.jogadores.contains(visao.euId);
    final mimico = visao.jogador(time.mimico)?.nome ?? 'Alguém';
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: meu ? CoresBaralho.ambarEscuro : CoresBaralho.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meu ? CoresBaralho.ambar : CoresBaralho.borda),
      ),
      child: Column(children: [
        Text('${coresDosTimes[indice]} ${meu ? 'Seu time' : 'Time'} · $mimico ${palavra ? 'explica' : 'faz a mímica'}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: EspacoBaralho.pequeno),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.pequeno,
          runSpacing: EspacoBaralho.pequeno,
          children: [
            for (final jogador in [for (final id in time.jogadores) ?visao.jogador(id)])
              SizedBox(
                width: 60,
                child: Column(children: [
                  AvatarDoJogador(
                    jogador: jogador,
                    tamanho: 40,
                    destaque: jogador.id == time.mimico ? CoresBaralho.mimica : null,
                  ),
                  Text(jogador.id == time.mimico ? '${palavra ? '🗣️' : '🎭'} ${jogador.nome}' : jogador.nome,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ],
        ),
      ]),
    );
  }
}

/// Depois do resultado: a palavra para todo mundo e quem leva o ponto.
class RevelacaoDaMimica extends StatelessWidget {
  const RevelacaoDaMimica({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final vencedor = revelacao.timeVencedor;
    final umaPessoaSo = rodada.times.length == 1;
    final titulo = switch (vencedor) {
      null => '⏰ Ninguém acertou!',
      _ when umaPessoaSo => '✅ A turma acertou!',
      final indice => '🏆 Time ${coresDosTimes[indice]} acertou!',
    };
    final perderam = [for (final id in revelacao.perderam) ?visao.jogador(id)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Era: ${rodada.texto}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        if (rodada.proibidas.isNotEmpty)
          Text('Proibidas: ${rodada.proibidas.join(' · ')}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
        const SizedBox(height: EspacoBaralho.pequeno),
        Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: EspacoBaralho.base),
        if (perderam.isEmpty)
          const Text('Ninguém leva ponto. 🎉', textAlign: TextAlign.center)
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: EspacoBaralho.medio,
            runSpacing: EspacoBaralho.medio,
            children: [
              for (final jogador in perderam)
                SizedBox(
                  width: 84,
                  child: Column(children: [
                    AvatarDoJogador(jogador: jogador, tamanho: 56, destaque: CoresBaralho.ambar),
                    Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(destinoDoPego(visao, jogador),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: CoresBaralho.ambar)),
                  ]),
                ),
            ],
          ),
      ],
    );
  }
}
