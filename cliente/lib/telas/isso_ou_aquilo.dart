import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';
import 'visual.dart';

/// ⚖️ Isso ou aquilo: dois botões grandes, um para cada opção. Dá para trocar até revelar.
class EscolherUmaDasDuas extends StatelessWidget {
  const EscolherUmaDasDuas({super.key, required this.rodada, required this.acoes});

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    // Os dois botões com a mesma altura, mesmo quando uma opção é mais comprida.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (indice, opcao) in rodada.opcoes.indexed) ...[
            if (indice > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: EspacoBaralho.pequeno),
                child: Center(
                  child: Text('ou', style: TextStyle(color: CoresBaralho.textoApagado)),
                ),
              ),
            Expanded(
              child: _Opcao(
                key: Key('opcao-$indice'),
                texto: opcao,
                escolhida: rodada.minhaResposta == '$indice',
                aoTocar: () => acoes.responder('$indice'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({super.key, required this.texto, required this.escolhida, required this.aoTocar});

  final String texto;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhida ? CoresBaralho.issoOuAquilo : CoresBaralho.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: escolhida ? CoresBaralho.issoOuAquilo : CoresBaralho.borda, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: aoTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(EspacoBaralho.medio),
            child: Center(
              child: Text(
                escolhida ? '$texto ✓' : texto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, height: 1.25, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quem escolheu cada lado, com as fotos, e quem ficou na minoria.
class RevelacaoDasEscolhas extends StatelessWidget {
  const RevelacaoDasEscolhas({super.key, required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  String _nomes(Iterable<String> ids) => ids.map((id) => visao.jogador(id)?.nome ?? '?').join(', ');

  String get _resumo {
    final lados = revelacao.lados;
    if (lados.any((lado) => lado.isEmpty)) return 'Todo mundo do mesmo lado: ninguém leva.';
    if (revelacao.perderam.isEmpty) return 'Empate: ninguém leva.';
    final perderam = revelacao.perderam;
    return 'Ficou na minoria: ${_nomes(perderam)} ${perderam.length == 1 ? 'leva' : 'levam'} 1 ponto';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('lados'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (indice, lado) in revelacao.lados.indexed) ...[
              if (indice > 0) const SizedBox(width: EspacoBaralho.medio),
              Expanded(
                child: _Lado(
                  visao: visao,
                  titulo: indice < rodada.opcoes.length ? rodada.opcoes[indice] : '?',
                  jogadores: lado,
                  minoria: lado.isNotEmpty && lado.every(revelacao.perderam.contains),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: EspacoBaralho.base),
        Text(_resumo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _Lado extends StatelessWidget {
  const _Lado({required this.visao, required this.titulo, required this.jogadores, required this.minoria});

  final VisaoDaSala visao;
  final String titulo;
  final List<String> jogadores;
  final bool minoria;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: CoresBaralho.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: minoria ? CoresBaralho.coral : CoresBaralho.borda, width: minoria ? 2 : 1),
      ),
      child: Column(
        children: [
          Text(
            '$titulo · ${jogadores.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: EspacoBaralho.pequeno),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: EspacoBaralho.pequeno,
            runSpacing: EspacoBaralho.pequeno,
            children: [
              for (final jogador in [for (final id in jogadores) ?visao.jogador(id)])
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      AvatarDoJogador(jogador: jogador, tamanho: 40),
                      Text(
                        jogador.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
