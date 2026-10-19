import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';
import 'visual.dart';

/// Quem está no comando escolhe para quem passa: a bateria vai acabar, ou
/// outra pessoa quer conduzir a noite.
Future<void> escolherQuemAssumeOComando(BuildContext context, VisaoDaSala visao, AcoesDaSala acoes) async {
  final outros = visao.jogadores.where((j) => j.id != visao.euId).toList();
  final escolha = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(EspacoBaralho.base, 0, EspacoBaralho.base, EspacoBaralho.base),
        children: [
          Text('Quem assume o comando? 👑', style: Theme.of(context).textTheme.titleLarge),
          const Padding(
            padding: EdgeInsets.only(top: EspacoBaralho.mini, bottom: EspacoBaralho.pequeno),
            child: Text('Essa pessoa passa a puxar, pular e revelar as cartas.',
                style: TextStyle(color: CoresBaralho.textoSecundario)),
          ),
          for (final jogador in outros)
            ListTile(
              leading: AvatarDoJogador(jogador: jogador),
              title: Text(jogador.nome),
              onTap: () => Navigator.pop(context, jogador.id),
            ),
        ],
      ),
    ),
  );
  if (escolha != null) await acoes.passarComando(escolha);
}

/// Puxar a próxima carta é com quem criou a sala: com todo mundo podendo,
/// vira bagunça. Para os outros fica o aviso de quem eles estão esperando.
class ProximaCarta extends StatelessWidget {
  const ProximaCarta({
    super.key,
    required this.visao,
    required this.aoTocar,
    this.rotulo = 'Próxima carta',
  });

  final VisaoDaSala visao;
  final VoidCallback aoTocar;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    if (visao.souAnfitriao) {
      return FilledButton(key: const Key('proxima-carta'), onPressed: aoTocar, child: Text(rotulo));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacoBaralho.medio),
      child: Text(
        'Esperando ${visao.anfitriao?.nome ?? 'quem criou a sala'} puxar a próxima carta 🃏',
        key: const Key('esperando-anfitriao'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: CoresBaralho.textoApagado),
      ),
    );
  }
}
