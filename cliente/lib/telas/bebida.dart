import 'dart:math';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';

/// Cofrinho de goles: cada vez que a carta pega alguém vale um ponto, e o
/// gole de verdade só sai quando o cofrinho enche. Na sala sem álcool, sai
/// uma prenda no lugar do gole.
extension VisualDoRitmo on RitmoDaBebida {
  String get titulo => switch (this) {
        RitmoDaBebida.devagar => '🐢 Devagar',
        RitmoDaBebida.normal => '🚶 Normal',
        RitmoDaBebida.raiz => '🔥 Raiz',
      };

  String get explicacao => switch (this) {
        RitmoDaBebida.devagar => '1 gole a cada 7 pontos',
        RitmoDaBebida.normal => '1 gole a cada 2 pontos',
        RitmoDaBebida.raiz => 'Todo ponto é gole',
      };

  String explicacaoNa(ConfiguracaoDoJogo configuracao) =>
      configuracao.semAlcool ? semAlcoolNoTexto(explicacao) : explicacao;
}

/// Os textos fixos do app (ajuda, descrições dos jogos, cartas na manga) falam
/// em gole; na sala sem álcool, viram prenda.
String semAlcoolNoTexto(String texto) {
  const trocas = [
    ('distribuem goles', 'passam uma prenda'),
    ('distribui goles', 'passa uma prenda'),
    ('distribuir os goles', 'passar a prenda'),
    ('Ninguém bebe', 'Ninguém paga prenda'),
    ('ninguém bebe', 'ninguém paga prenda'),
    ('todos bebem', 'todos levam ponto'),
    ('Todos bebem', 'Todos levam'),
    ('bebe 1 gole', 'paga 1 prenda'),
    ('Todo ponto é gole', 'Todo ponto é prenda'),
    ('goles', 'prendas'),
    ('gole', 'prenda'),
    ('🍺', '🎟️'),
  ];
  return trocas.fold(texto, (atual, troca) => atual.replaceAll(troca.$1, troca.$2));
}

/// O mesmo texto fixo, do jeito da sala: com bebida ou com prenda.
String paraASala(VisaoDaSala visao, String texto) =>
    visao.configuracao.semAlcool ? semAlcoolNoTexto(texto) : texto;

/// O que a carta fez com quem ela pegou.
String destinoDoPego(VisaoDaSala visao, Jogador jogador) {
  final porGole = visao.configuracao.pontosPorGole;
  final pagaAgora = porGole == 1 || (visao.rodada?.bebemAgora.contains(jogador.id) ?? false);
  if (visao.configuracao.semAlcool) {
    if (visao.rodada?.goles case final goles?) return 'paga $goles prendas 🎟️';
    if (pagaAgora) return 'paga prenda 🎟️';
    return '+1 ponto · ${jogador.cofrinho}/$porGole 🎟️';
  }
  if (visao.rodada?.goles case final goles?) return jogador.semAlcool ? '+$goles pontos ⭐' : 'bebe $goles 🍺';
  if (jogador.semAlcool) return '+1 ponto ⭐';
  if (pagaAgora) return 'bebe 🍺';
  return '+1 ponto · ${jogador.cofrinho}/$porGole 🍺';
}

/// Elogio: quem a turma escolhe distribui goles, menos nos ritmos mais calmos.
/// Na sala sem álcool, passa uma prenda para alguém.
String distribuiGoles(VisaoDaSala visao, int noRaiz) {
  if (visao.configuracao.semAlcool) return '💛 passa uma prenda';
  final goles = max(1, noRaiz ~/ visao.configuracao.pontosPorGole);
  return goles == 1 ? '💛 distribui 1 gole' : '💛 distribui $goles goles';
}

/// Placar: na sala sem álcool, as prendas pagas; quem joga sem álcool numa sala
/// com bebida conta pontos; os outros, goles de verdade.
String placarDe(VisaoDaSala visao, Jogador jogador) => visao.configuracao.semAlcool
    ? (jogador.goles == 1 ? '1 prenda' : '${jogador.goles} prendas')
    : jogador.placar;

/// Faixa de quem encheu o cofrinho nesta carta (na sala sem álcool, com a prenda).
class HoraDoGole extends StatelessWidget {
  const HoraDoGole({super.key, required this.visao});

  final VisaoDaSala visao;

  @override
  Widget build(BuildContext context) {
    final rodada = visao.rodada;
    if (rodada == null) return const SizedBox.shrink();
    if (visao.configuracao.semAlcool) return _HoraDaPrenda(visao: visao, rodada: rodada);
    final dose = rodada.goles;
    // No Raiz todo ponto já diz "bebe": a faixa seria repetição (menos na dose).
    if (dose == null && visao.configuracao.pontosPorGole == 1) return const SizedBox.shrink();
    final nomes = [for (final id in rodada.bebemAgora) ?visao.jogador(id)?.nome];
    if (nomes.isEmpty) return const SizedBox.shrink();
    final quem = nomes.length == 1
        ? '${nomes.single} bebe'
        : '${nomes.take(nomes.length - 1).join(', ')} e ${nomes.last} bebem';
    final texto = dose == null ? '🍺 Cofrinho cheio! $quem agora.' : '🍺 Dose! $quem $dose agora.';
    return _Faixa(
      chave: const Key('hora-do-gole'),
      children: [
        Text(texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

/// Sala sem álcool: cada prenda aparece, até no Raiz, porque cada uma é diferente.
/// No elogio, a prenda que quem a turma escolheu passa para alguém.
class _HoraDaPrenda extends StatelessWidget {
  const _HoraDaPrenda({required this.visao, required this.rodada});

  final VisaoDaSala visao;
  final Rodada rodada;

  @override
  Widget build(BuildContext context) {
    final prendas = [
      for (final id in rodada.bebemAgora)
        if ((visao.jogador(id), rodada.prendas[id]) case (final jogador?, final daPessoa?) when daPessoa.isNotEmpty)
          (jogador.nome, daPessoa),
    ];
    final escolhidos = [for (final id in rodada.revelacao?.escolhidos ?? const <String>[]) ?visao.jogador(id)?.nome];
    final paraDar = rodada.prendaParaDar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prendas.isNotEmpty)
          _Faixa(
            chave: const Key('hora-da-prenda'),
            children: [
              for (final (nome, daPessoa) in prendas) ...[
                Text('🎟️ Prenda para $nome', textAlign: TextAlign.center, style: _titulo),
                for (final prenda in daPessoa) Text(prenda, textAlign: TextAlign.center, style: _prenda),
              ],
            ],
          ),
        if (paraDar != null && escolhidos.isNotEmpty)
          _Faixa(
            chave: const Key('prenda-para-dar'),
            children: [
              Text(
                escolhidos.length == 1
                    ? '💛 ${escolhidos.single} escolhe quem paga esta prenda'
                    : '💛 ${escolhidos.take(escolhidos.length - 1).join(', ')} e ${escolhidos.last} '
                        'escolhem quem paga esta prenda',
                textAlign: TextAlign.center,
                style: _titulo,
              ),
              Text(paraDar, textAlign: TextAlign.center, style: _prenda),
            ],
          ),
      ],
    );
  }

  static const _titulo = TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600, fontSize: 16);
  static const _prenda = TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w600);
}

class _Faixa extends StatelessWidget {
  const _Faixa({required this.chave, required this.children});

  final Key chave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: chave,
      margin: const EdgeInsets.only(bottom: EspacoBaralho.base),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.ambarEscuro,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresBaralho.ambar),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EspacoBaralho.mini,
        children: children,
      ),
    );
  }
}
