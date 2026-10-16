import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'ajuda.dart';
import 'configuracao_do_jogo.dart';
import 'sala.dart';
import 'selfie.dart';
import 'visual.dart';

String linkDaSala(String codigo) => '${Uri.base.removeFragment()}#/sala/$codigo';

class Lobby extends StatelessWidget {
  const Lobby({super.key, required this.visao, required this.acoes});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final podeComecar = visao.jogadores.length >= 2;
    return Scaffold(
      appBar: AppBar(
        // Na sala não tem volta: sair é pelo botão, que tira a pessoa do jogo.
        automaticallyImplyLeading: false,
        title: const Text('Sala de espera'),
        actions: [
          IconButton(
            tooltip: 'Como funciona o jogo',
            onPressed: () => abrirComoFunciona(context, visao),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: 'Sair da sala',
            onPressed: () => confirmarSaida(context, acoes),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(EspacoBaralho.grande),
              children: [
                _CodigoDaSala(codigo: visao.codigo),
                const SizedBox(height: EspacoBaralho.grande),
                Text('Na mesa (${visao.jogadores.length})', style: texto.titleMedium),
                const SizedBox(height: EspacoBaralho.pequeno),
                Wrap(
                  spacing: EspacoBaralho.medio,
                  runSpacing: EspacoBaralho.base,
                  children: [
                    for (final jogador in visao.jogadores)
                      _JogadorNaMesa(
                        jogador: jogador,
                        souEu: jogador.id == visao.euId,
                        trocarFoto: () async {
                          final foto = await tirarSelfie(context);
                          if (foto != null) await acoes.trocarFoto(foto);
                        },
                      ),
                  ],
                ),
                // Pares só importam quando o Casais em Jogo está na mistura.
                if (visao.jogadores.length > 1 && visao.configuracao.modos.contains(ModoDeJogo.casaisEmJogo)) ...[
                  const SizedBox(height: EspacoBaralho.base),
                  _ParDoCasal(visao: visao, acoes: acoes),
                ],
                const SizedBox(height: EspacoBaralho.grande),
                ConfiguracaoDoJogoEditor(
                  configuracao: visao.configuracao,
                  podeEditar: visao.souAnfitriao,
                  aoMudar: acoes.configurar,
                ),
                const SizedBox(height: EspacoBaralho.grande),
                if (visao.souAnfitriao)
                  FilledButton(
                    onPressed: podeComecar ? acoes.comecar : null,
                    child: Text(podeComecar ? 'Começar a resenha 🍻' : 'Esperando a turma entrar…'),
                  )
                else
                  Text(
                    'Esperando ${visao.anfitriao?.nome ?? 'o anfitrião'} começar…',
                    textAlign: TextAlign.center,
                    style: texto.titleMedium?.copyWith(color: CoresBaralho.textoSecundario),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca o par do casal (para o Casais em Jogo) e mostra os casais da mesa.
class _ParDoCasal extends StatelessWidget {
  const _ParDoCasal({required this.visao, required this.acoes});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  Future<void> _escolher(BuildContext context) async {
    final outros = visao.jogadores.where((j) => j.id != visao.euId).toList();
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(EspacoBaralho.base, 0, EspacoBaralho.base, EspacoBaralho.base),
          children: [
            Text('Quem é o seu par? 💞', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: EspacoBaralho.pequeno),
            for (final jogador in outros)
              ListTile(
                leading: AvatarDoJogador(jogador: jogador),
                title: Text(jogador.nome),
                subtitle: jogador.parId != null && jogador.parId != visao.euId
                    ? Text('Já está com ${visao.jogador(jogador.parId!)?.nome ?? 'alguém'}')
                    : null,
                onTap: () => Navigator.pop(context, jogador.id),
              ),
            ListTile(
              leading: const Text('🙋', style: TextStyle(fontSize: 28)),
              title: const Text('Ninguém, vim sozinho(a)'),
              onTap: () => Navigator.pop(context, ''),
            ),
          ],
        ),
      ),
    );
    if (escolha == null) return;
    await acoes.definirPar(escolha.isEmpty ? null : escolha);
  }

  @override
  Widget build(BuildContext context) {
    final meuPar = visao.eu.parId == null ? null : visao.jogador(visao.eu.parId!);
    final casais = <String>[
      for (final jogador in visao.jogadores)
        if (jogador.parId case final parId?)
          if (jogador.id.compareTo(parId) < 0)
            if (visao.jogador(parId) case final par?) '${jogador.nome} 💞 ${par.nome}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: CoresBaralho.superficieElevada,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CoresBaralho.borda),
          ),
          child: ListTile(
            key: const Key('meu-par'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: meuPar == null
                ? const Text('💞', style: TextStyle(fontSize: 26))
                : AvatarDoJogador(jogador: meuPar, tamanho: 36, destaque: CoresBaralho.casais),
            title: Text(meuPar == null ? 'Marcar seu par' : 'Seu par: ${meuPar.nome}'),
            subtitle: const Text('Para o Casais em Jogo', style: TextStyle(color: CoresBaralho.textoApagado)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _escolher(context),
          ),
        ),
        if (casais.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
            child: Text(casais.join('   ·   '),
                textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
          ),
      ],
    );
  }
}

class _JogadorNaMesa extends StatelessWidget {
  const _JogadorNaMesa({required this.jogador, required this.souEu, required this.trocarFoto});

  final Jogador jogador;
  final bool souEu;
  final VoidCallback trocarFoto;

  @override
  Widget build(BuildContext context) {
    final rosto = Stack(
      clipBehavior: Clip.none,
      children: [
        AvatarDoJogador(jogador: jogador, tamanho: 72, destaque: souEu ? CoresBaralho.ambar : null),
        if (jogador.anfitriao)
          const Positioned(top: -8, left: -4, child: Text('👑', style: TextStyle(fontSize: 20))),
        if (jogador.semAlcool)
          const Positioned(bottom: -4, left: -4, child: Text('🥤', style: TextStyle(fontSize: 18))),
        if (souEu)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: CoresBaralho.ambar, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera_rounded, size: 14, color: CoresBaralho.fundo),
            ),
          ),
      ],
    );
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          souEu
              ? Tooltip(
                  message: jogador.foto == null ? 'Tirar selfie' : 'Trocar selfie',
                  child: GestureDetector(key: const Key('minha-selfie'), onTap: trocarFoto, child: rosto),
                )
              : rosto,
          const SizedBox(height: EspacoBaralho.mini),
          Text(
            souEu ? 'Você' : jogador.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CodigoDaSala extends StatelessWidget {
  const _CodigoDaSala({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    final link = linkDaSala(codigo);
    return Container(
      padding: const EdgeInsets.all(EspacoBaralho.grande),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2410), CoresBaralho.superficie],
        ),
        border: Border.all(color: CoresBaralho.borda),
      ),
      child: Column(
        children: [
          const Text('Código da sala', style: TextStyle(color: CoresBaralho.textoSecundario)),
          SelectableText(
            codigo,
            style: const TextStyle(
                fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: 10, color: CoresBaralho.ambar),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          Container(
            padding: const EdgeInsets.all(EspacoBaralho.medio),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(data: link, size: 168, padding: EdgeInsets.zero),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          const Text('A turma aponta a câmera e já entra.',
              style: TextStyle(color: CoresBaralho.textoSecundario)),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) avisar(context, 'Link copiado! Manda no grupo da turma.');
            },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Copiar link'),
          ),
        ],
      ),
    );
  }
}
