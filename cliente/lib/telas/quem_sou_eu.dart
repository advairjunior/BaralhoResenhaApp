import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'cronometro.dart';
import 'sala.dart';
import 'visual.dart';

/// Para quem não sabe por onde começar: perguntas que servem para qualquer coisa.
const ideiasDePergunta = [
  'Sou uma pessoa de verdade?',
  'Dá para comer?',
  'Caibo dentro de uma mochila?',
  'Tem em toda casa?',
  'Sou do Brasil?',
  'Apareço na TV?',
];

/// 🙈 Quem sou eu? antes do resultado. A pessoa da vez vê só a categoria e ideias de
/// pergunta; a turma vê quem ela é e só responde sim ou não. Quem criou a sala marca o resultado.
class PainelDoQuemSouEu extends StatelessWidget {
  const PainelDoQuemSouEu({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final souEu = rodada.alvo == visao.euId;
    final daVez = visao.jogador(rodada.alvo ?? '');
    final nome = daVez?.nome ?? 'A pessoa da vez';
    final texto = Theme.of(context).textTheme;
    return Column(
      key: const Key('quem-sou-eu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (souEu) ...[
          Text(
            'Você é: ${rodada.dica ?? '?'}',
            textAlign: TextAlign.center,
            style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: CoresBaralho.quemSouEu),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
          const Text(
            'Pergunte em voz alta. A turma só responde sim ou não.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoresBaralho.textoSecundario),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: EspacoBaralho.pequeno,
            runSpacing: EspacoBaralho.pequeno,
            children: [for (final ideia in ideiasDePergunta) Chip(label: Text(ideia))],
          ),
        ] else ...[
          if (daVez != null)
            Center(
              child: AvatarDoJogador(jogador: daVez, tamanho: 72, destaque: CoresBaralho.quemSouEu),
            ),
          const SizedBox(height: EspacoBaralho.pequeno),
          Text(
            '$nome é: ${rodada.texto}',
            textAlign: TextAlign.center,
            style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: EspacoBaralho.mini),
          const Text(
            '🤫 Só responda sim ou não. Não vale dar dica!',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoresBaralho.textoSecundario),
          ),
        ],
        const SizedBox(height: EspacoBaralho.base),
        Cronometro(
          key: ValueKey('quem-sou-eu-${rodada.numero}'),
          visao: visao,
          rodada: rodada,
          aoIniciar: acoes.iniciarCronometro,
        ),
        if (visao.souAnfitriao) ...[
          FilledButton(onPressed: () => acoes.resultadoDoQuemSouEu(acertou: true), child: const Text('✅ Acertou!')),
          TextButton(onPressed: () => acoes.resultadoDoQuemSouEu(acertou: false), child: const Text('⏰ Não acertou')),
          TextButton(onPressed: acoes.proxima, child: const Text('Pular carta')),
        ] else
          Text(
            '${visao.anfitriao?.nome ?? 'Quem criou a sala'} marca se $nome acertou',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoApagado),
          ),
      ],
    );
  }
}

/// Quem era, e o que aconteceu com a pessoa da vez.
class RevelacaoDoQuemSouEu extends StatelessWidget {
  const RevelacaoDoQuemSouEu({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final daVez = visao.jogador(rodada.alvo ?? '');
    final nome = daVez?.nome ?? 'A pessoa da vez';
    final acertou = revelacao.escolhidos.isNotEmpty;
    return Column(
      key: const Key('resultado-quem-sou-eu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (daVez != null)
          Center(
            child: AvatarDoJogador(
              jogador: daVez,
              tamanho: 96,
              destaque: acertou ? CoresBaralho.sucesso : CoresBaralho.coral,
            ),
          ),
        const SizedBox(height: EspacoBaralho.medio),
        Text(
          'Era: ${rodada.texto}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        Text(
          acertou ? '🎉 $nome acertou! Ganhou uma carta na manga.' : '⏰ Não deu tempo! $nome leva 1 ponto.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
