import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'bebida.dart';
import 'noites_prontas.dart';
import 'visual.dart';

/// Nível, modos e Zona Segura. Quem criou a sala mexe; os outros só veem.
class ConfiguracaoDoJogoEditor extends StatelessWidget {
  const ConfiguracaoDoJogoEditor({
    super.key,
    required this.configuracao,
    required this.podeEditar,
    required this.aoMudar,
  });

  final ConfiguracaoDoJogo configuracao;
  final bool podeEditar;
  final ValueChanged<ConfiguracaoDoJogo> aoMudar;

  Future<void> _escolherNivel(BuildContext context, NivelDaCarta nivel) async {
    if (nivel == NivelDaCarta.original && !await _turmaTopouOOriginal(context)) return;
    aoMudar(configuracao.copiar(nivel: nivel));
  }

  Future<void> _escolherNoite(BuildContext context, NoitePronta noite) async {
    if (noite.configuracao.nivel == NivelDaCarta.original && !await _turmaTopouOOriginal(context)) return;
    aoMudar(noite.configuracao);
  }

  Future<bool> _turmaTopouOOriginal(BuildContext context) async {
    final topou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 Baralho Original'),
        content: const Text(
          'Aqui as cartas são pesadas como as dos baralhos de loja: '
          'sexo sem rodeio e perguntas bem indiscretas.\n\n'
          'A turma toda topou?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Melhor não')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bora ver!'),
          ),
        ],
      ),
    );
    return topou == true;
  }

  void _alternarModo(BuildContext context, ModoDeJogo modo, bool ligado) {
    final modos = {...configuracao.modos};
    ligado ? modos.add(modo) : modos.remove(modo);
    if (modos.isEmpty) {
      avisar(context, 'Deixe pelo menos um modo ligado.');
      return;
    }
    aoMudar(configuracao.copiar(modos: modos));
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Noites prontas', style: texto.titleMedium),
        Text(
          'Um toque e a noite está montada. Dá para ajustar tudo embaixo depois.',
          style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoApagado),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        NoitesProntas(
          configuracao: configuracao,
          aoEscolher: podeEditar ? (noite) => _escolherNoite(context, noite) : null,
        ),
        const SizedBox(height: EspacoBaralho.base),
        Text(configuracao.esquentar ? 'Até onde pode esquentar' : 'Nível das cartas', style: texto.titleMedium),
        const SizedBox(height: EspacoBaralho.pequeno),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: EspacoBaralho.pequeno,
          crossAxisSpacing: EspacoBaralho.pequeno,
          childAspectRatio: 1.55,
          children: [
            for (final nivel in NivelDaCarta.values)
              _CartaoDeNivel(
                nivel: nivel,
                escolhido: configuracao.nivel == nivel,
                aoTocar: podeEditar ? () => _escolherNivel(context, nivel) : null,
              ),
          ],
        ),
        SwitchListTile(
          key: const Key('esquentar'),
          contentPadding: EdgeInsets.zero,
          value: configuracao.esquentar,
          onChanged: podeEditar ? (ligado) => aoMudar(configuracao.copiar(esquentar: ligado)) : null,
          title: const Text('🌡️  Esquenta sozinho'),
          subtitle: Text(
            configuracao.nivel == NivelDaCarta.leve
                ? 'Escolha um nível acima do Leve para a noite ter para onde esquentar.'
                : 'Começa no Leve e sobe um nível a cada $cartasPorNivel cartas, '
                      'até ${configuracao.nivel.emoji} ${configuracao.nivel.titulo}.',
            style: const TextStyle(color: CoresBaralho.textoApagado),
          ),
        ),
        const SizedBox(height: EspacoBaralho.base),
        Text('Ritmo da bebida', style: texto.titleMedium),
        Text(
          'Cada vez que a carta pega alguém vale 1 ponto. O gole só sai quando o cofrinho enche.',
          style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoApagado),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final ritmo in RitmoDaBebida.values) ...[
              if (ritmo != RitmoDaBebida.values.first) const SizedBox(width: EspacoBaralho.pequeno),
              Expanded(
                child: _CartaoDeRitmo(
                  ritmo: ritmo,
                  escolhido: configuracao.cofrinho == null && configuracao.ritmo == ritmo,
                  aoTocar: podeEditar ? () => aoMudar(configuracao.copiar(ritmo: ritmo)) : null,
                ),
              ),
            ],
          ],
        ),
        _TamanhoDoCofrinho(
          pontos: configuracao.pontosPorGole,
          aoMudar: podeEditar ? (pontos) => aoMudar(configuracao.copiar(cofrinho: pontos)) : null,
        ),
        SwitchListTile(
          key: const Key('passar-sozinho'),
          contentPadding: EdgeInsets.zero,
          value: configuracao.passarSozinho,
          onChanged: podeEditar ? (ligado) => aoMudar(configuracao.copiar(passarSozinho: ligado)) : null,
          title: const Text('⏩  Passar a carta sozinho'),
          subtitle: const Text(
            'Quando todo mundo responde ou marca "Pronto", a carta passa em 3 segundos. '
            'Qualquer um pode segurar.',
            style: TextStyle(color: CoresBaralho.textoApagado),
          ),
        ),
        SwitchListTile(
          key: const Key('cartas-na-manga'),
          contentPadding: EdgeInsets.zero,
          value: configuracao.cartasNaManga,
          onChanged: podeEditar ? (ligado) => aoMudar(configuracao.copiar(cartasNaManga: ligado)) : null,
          title: const Text('🃏  Cartas na manga'),
          subtitle: const Text(
            'Estilo Uno: Escudo, Passa a bola, Batata quente, Dobra e Devolve. '
            'Cada um começa com uma e ganha mais vencendo.',
            style: TextStyle(color: CoresBaralho.textoApagado),
          ),
        ),
        const SizedBox(height: EspacoBaralho.base),
        Text('Jogos na mistura', style: texto.titleMedium),
        Text(
          'Ligue um jogo para jogar só ele, ou vários para embaralhar as cartas, '
          'sem repetir o mesmo jogo muitas vezes seguidas.',
          style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoApagado),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        _ResumoDaMistura(modos: configuracao.modos),
        if (podeEditar && configuracao.modos.length < ModoDeJogo.values.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('ligar-todos'),
              onPressed: () => aoMudar(configuracao.copiar(modos: ModoDeJogo.values.toSet())),
              child: const Text('🎲 Ligar todos os jogos'),
            ),
          ),
        for (final modo in ModoDeJogo.values)
          SwitchListTile(
            key: Key('modo-${modo.name}'),
            contentPadding: EdgeInsets.zero,
            value: configuracao.modos.contains(modo),
            onChanged: podeEditar ? (ligado) => _alternarModo(context, modo, ligado) : null,
            title: Text('${modo.emoji}  ${modo.titulo}'),
            subtitle: Text(modo.explicacao, style: const TextStyle(color: CoresBaralho.textoApagado)),
          ),
        const Divider(color: CoresBaralho.borda, height: EspacoBaralho.grande),
        SwitchListTile(
          key: const Key('zona-segura'),
          contentPadding: EdgeInsets.zero,
          value: configuracao.zonaSegura,
          onChanged: podeEditar ? (ligado) => aoMudar(configuracao.copiar(zonaSegura: ligado)) : null,
          title: const Text('🛟  Zona Segura'),
          subtitle: const Text(
            'Tira as cartas sobre ex, ciúme e traição, que podem virar DR de verdade.',
            style: TextStyle(color: CoresBaralho.textoApagado),
          ),
        ),
        if (!podeEditar)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text(
              'Só quem criou a sala muda as configurações.',
              style: texto.bodyMedium?.copyWith(color: CoresBaralho.textoApagado),
            ),
          ),
      ],
    );
  }
}

/// Em uma linha, como a noite vai ser jogada: um jogo só ou a mistura.
class _ResumoDaMistura extends StatelessWidget {
  const _ResumoDaMistura({required this.modos});

  final Set<ModoDeJogo> modos;

  @override
  Widget build(BuildContext context) {
    final ligados = [
      for (final modo in ModoDeJogo.values)
        if (modos.contains(modo)) modo,
    ];
    final nomes = ligados.map((modo) => modo.titulo).toList();
    final texto = ligados.length == 1
        ? '🎯 Só ${nomes.single}'
        : '🎲 Misturando: ${nomes.take(nomes.length - 1).join(', ')} e ${nomes.last}';
    return Container(
      key: const Key('resumo-da-mistura'),
      padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio, vertical: EspacoBaralho.pequeno),
      decoration: BoxDecoration(color: CoresBaralho.ambarEscuro, borderRadius: BorderRadius.circular(12)),
      child: Text(
        texto,
        style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Ajuste fino do cofrinho: 1 gole a cada quantos pontos. Vale também no meio do jogo.
class _TamanhoDoCofrinho extends StatelessWidget {
  const _TamanhoDoCofrinho({required this.pontos, required this.aoMudar});

  final int pontos;
  final ValueChanged<int>? aoMudar;

  @override
  Widget build(BuildContext context) {
    final mudar = aoMudar;
    return Padding(
      padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🐷 Cofrinho de $pontos ${pontos == 1 ? 'ponto' : 'pontos'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  pontos == 1 ? 'Todo ponto é gole.' : 'Encheu, bebe 1 gole.',
                  style: const TextStyle(fontSize: 12, color: CoresBaralho.textoApagado),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            key: const Key('cofrinho-menos'),
            onPressed: mudar == null || pontos <= 1 ? null : () => mudar(pontos - 1),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: EspacoBaralho.pequeno),
          IconButton.outlined(
            key: const Key('cofrinho-mais'),
            onPressed: mudar == null || pontos >= ConfiguracaoDoJogo.cofrinhoMaximo ? null : () => mudar(pontos + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _CartaoDeRitmo extends StatelessWidget {
  const _CartaoDeRitmo({required this.ritmo, required this.escolhido, required this.aoTocar});

  final RitmoDaBebida ritmo;
  final bool escolhido;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhido ? CoresBaralho.ambarEscuro : CoresBaralho.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: escolhido ? CoresBaralho.ambar : CoresBaralho.borda, width: escolhido ? 2 : 1),
      ),
      child: InkWell(
        key: Key('ritmo-${ritmo.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(EspacoBaralho.medio),
          child: Column(
            children: [
              Text(ritmo.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: EspacoBaralho.mini),
              Text(
                ritmo.explicacao,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.3, color: CoresBaralho.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoDeNivel extends StatelessWidget {
  const _CartaoDeNivel({required this.nivel, required this.escolhido, required this.aoTocar});

  final NivelDaCarta nivel;
  final bool escolhido;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhido ? CoresBaralho.ambarEscuro : CoresBaralho.superficieElevada,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: escolhido ? CoresBaralho.ambar : CoresBaralho.borda, width: escolhido ? 2 : 1),
      ),
      child: InkWell(
        key: Key('nivel-${nivel.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(EspacoBaralho.medio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${nivel.emoji} ${nivel.titulo}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: EspacoBaralho.mini),
              Expanded(
                child: Text(
                  nivel.explicacao,
                  style: const TextStyle(fontSize: 12, height: 1.3, color: CoresBaralho.textoSecundario),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> abrirConfiguracao(
  BuildContext context, {
  required ConfiguracaoDoJogo configuracao,
  required bool podeEditar,
  required Future<void> Function(ConfiguracaoDoJogo) aoMudar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      var atual = configuracao;
      return StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, rolagem) => ListView(
            controller: rolagem,
            padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
            children: [
              ConfiguracaoDoJogoEditor(
                configuracao: atual,
                podeEditar: podeEditar,
                aoMudar: (nova) {
                  setState(() => atual = nova);
                  aoMudar(nova);
                },
              ),
              const SizedBox(height: EspacoBaralho.base),
              Text(
                'As mudanças valem a partir da próxima carta.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CoresBaralho.textoApagado),
              ),
            ],
          ),
        ),
      );
    },
  );
}
