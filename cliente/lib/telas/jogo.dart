import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'carta_de_baralho.dart';
import 'ajuda.dart';
import 'aponta_no_tres.dart';
import 'bebida.dart';
import 'cartas_na_manga.dart';
import 'casais.dart';
import 'controles_do_anfitriao.dart';
import 'cronometro.dart';
import 'imagem_e_acao.dart';
import 'jokenpo.dart';
import 'correio.dart';
import 'termine_a_frase.dart';
import 'duas_verdades.dart';
import 'chuta_ai.dart';
import 'configuracao_do_jogo.dart';
import 'momentos.dart';
import 'passar_sozinho.dart';
import 'regra_em_jogo.dart';
import 'sala.dart';
import 'suspense_da_votacao.dart';
import 'visual.dart';

const respostaJa = 'ja';
const respostaNunca = 'nunca';
const respostaSim = 'sim';
const respostaNao = 'nao';

/// O que acontece com quem a turma escolheu: ponto no cofrinho (ou gole), ou,
/// no elogio, distribui goles.
String destinoDoEscolhido(VisaoDaSala visao, Jogador jogador, {required bool elogio, int goles = 3}) =>
    elogio ? distribuiGoles(visao, goles) : destinoDoPego(visao, jogador);

class Jogo extends StatelessWidget {
  const Jogo({super.key, required this.visao, required this.acoes});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final rodada = visao.rodada!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Sala ${visao.codigo}', style: const TextStyle(fontSize: 16, letterSpacing: 2)),
        actions: [
          IconButton(
            tooltip: 'Placar',
            onPressed: () => abrirPlacar(context, visao, acoes),
            icon: const Text('🏆', style: TextStyle(fontSize: 22)),
          ),
          PopupMenuButton<String>(
            onSelected: (opcao) => switch (opcao) {
              'configurar' => abrirConfiguracao(
                  context,
                  configuracao: visao.configuracao,
                  podeEditar: visao.souAnfitriao,
                  aoMudar: acoes.configurar,
                ),
              'encerrar' => _confirmarEncerramento(context, acoes),
              'comando' => escolherQuemAssumeOComando(context, visao, acoes),
              'som' => acoes.alternarSom(),
              'voz' => acoes.alternarVoz(),
              'como-funciona' => abrirComoFunciona(context, visao),
              _ => confirmarSaida(context, acoes),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'como-funciona', child: Text('Como funciona o jogo ⓘ')),
              PopupMenuItem(
                value: 'configurar',
                child: Text(visao.souAnfitriao ? 'Nível e modos' : 'Ver nível e modos'),
              ),
              if (visao.souAnfitriao) ...[
                const PopupMenuItem(value: 'comando', child: Text('Passar o comando 👑')),
                const PopupMenuItem(value: 'encerrar', child: Text('Encerrar a noite 🏆')),
              ],
              PopupMenuItem(
                value: 'som',
                child: Text(acoes.somLigado ? '🔇 Desligar som e vibração' : '🔊 Ligar som e vibração'),
              ),
              // Só o celular de quem comanda lê as cartas em voz alta.
              if (visao.souAnfitriao)
                PopupMenuItem(
                  value: 'voz',
                  child: Text(acoes.vozLigada ? '🗣️ Desligar a voz das cartas' : '🗣️ Ligar a voz das cartas'),
                ),
              const PopupMenuItem(value: 'sair', child: Text('Sair da sala')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  EspacoBaralho.base, EspacoBaralho.pequeno, EspacoBaralho.base, EspacoBaralho.grande),
              children: [
                _PlacarAoVivo(visao: visao, acoes: acoes),
                if (visao.regra != null && rodada.modo != ModoDeJogo.regraRelampago)
                  RegraEmJogo(visao: visao, acoes: acoes),
                if (visao.esquenta case Esquenta(subiuAgora: true, :final agora))
                  _AvisoSobreACarta(texto: '🌡️ Esquentou! Agora é ${agora.emoji} ${agora.titulo}', cor: CoresBaralho.coral),
                if (visao.cartaTiradaPor case final nome?)
                  _AvisoSobreACarta(texto: '👎 $nome tirou a carta anterior', cor: CoresBaralho.textoApagado),
                // Quem está na foto do correio não vê a pergunta: fica de fora.
                if (rodada.modo == ModoDeJogo.correio && rodada.alvo == visao.euId && rodada.revelacao == null)
                  const DeForaDoCorreio()
                else
                  // Carta nova, carta virada: a chave nova faz a virada de novo.
                  CartaQueVira(key: ValueKey(rodada.numero), rodada: rodada),
                _BarraDaCarta(visao: visao, rodada: rodada, acoes: acoes),
                _Reacoes(rodada: rodada, acoes: acoes),
                DicaDePrimeiraVez(key: ValueKey('dica-${rodada.numero}'), visao: visao, rodada: rodada),
                const SizedBox(height: EspacoBaralho.base),
                // A mímica e o aponta no 3 têm a contagem no painel deles.
                if (rodada.cronometroSegundos != null &&
                    rodada.revelacao == null &&
                    rodada.modo != ModoDeJogo.imagemEAcao &&
                    !(rodada.modo == ModoDeJogo.maisProvavel && !rodada.votacao))
                  Cronometro(
                    key: ValueKey('cronometro-${rodada.numero}'),
                    visao: visao,
                    rodada: rodada,
                    aoIniciar: acoes.iniciarCronometro,
                  ),
                HoraDoGole(visao: visao),
                UsosDasCartas(visao: visao, rodada: rodada),
                _AreaDeAcao(visao: visao, rodada: rodada, acoes: acoes),
                PassarSozinho(key: ValueKey('passar-${rodada.numero}'), visao: visao, rodada: rodada, acoes: acoes),
                MinhaMao(visao: visao, rodada: rodada, acoes: acoes),
              ],
            ),
          ),
        ),
          ),
          if (rodada.revelacao case final revelacao?
              when rodada.modo == ModoDeJogo.maisProvavel ||
                  rodada.modo == ModoDeJogo.tribunal ||
                  rodada.modo == ModoDeJogo.impostor)
            Positioned.fill(
              child: SuspenseDaVotacao.da(
                key: ValueKey('suspense-${visao.codigo}-${rodada.numero}'),
                visao: visao,
                rodada: rodada,
                revelacao: revelacao,
              ),
            ),
        ],
      ),
    );
  }
}

/// Faixa discreta com os três mais pegos até agora; tocar abre o placar inteiro.
class _PlacarAoVivo extends StatelessWidget {
  const _PlacarAoVivo({required this.visao, required this.acoes});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final lideres = (visao.jogadores.where((j) => j.pontos > 0).toList()
          ..sort((a, b) => b.pontos.compareTo(a.pontos)))
        .take(3)
        .toList();
    if (lideres.isEmpty) return const SizedBox.shrink();
    return InkWell(
      key: const Key('placar-ao-vivo'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => abrirPlacar(context, visao, acoes),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspacoBaralho.mini),
        child: Text(
          '🏆 ${lideres.map((j) => '${j.nome} ${j.pontos}').join(' · ')}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: CoresBaralho.textoSecundario),
        ),
      ),
    );
  }
}

/// Reação rápida na carta: todo mundo vê a contagem, ninguém vê quem reagiu.
/// A carta que mais rende vira a carta da noite.
class _Reacoes extends StatelessWidget {
  const _Reacoes({required this.rodada, required this.acoes});

  static const emojis = ['😂', '🔥', '💀', '😱'];

  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final emoji in emojis)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.mini),
              child: _BotaoDeReacao(
                emoji: emoji,
                vezes: rodada.reacoes[emoji] ?? 0,
                minha: rodada.minhaReacao == emoji,
                aoTocar: () => acoes.reagir(emoji),
              ),
            ),
        ],
      );
}

class _BotaoDeReacao extends StatelessWidget {
  const _BotaoDeReacao({required this.emoji, required this.vezes, required this.minha, required this.aoTocar});

  final String emoji;
  final int vezes;
  final bool minha;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
        key: Key('reacao-$emoji'),
        color: minha ? CoresBaralho.ambar.withValues(alpha: 0.22) : CoresBaralho.superficieElevada,
        shape: StadiumBorder(side: BorderSide(color: minha ? CoresBaralho.ambar : CoresBaralho.borda)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  if (vezes > 0) ...[
                    const SizedBox(width: EspacoBaralho.mini),
                    Text('$vezes', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

/// Aviso curto em cima da carta.
class _AvisoSobreACarta extends StatelessWidget {
  const _AvisoSobreACarta({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
        child: Text(texto,
            textAlign: TextAlign.center, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
      );
}

/// Embaixo da carta: em que nível a noite está (Esquenta sozinho) e o
/// "Tira essa", para a carta que ninguém quer jogar.
class _BarraDaCarta extends StatelessWidget {
  const _BarraDaCarta({required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  Esquenta? get esquenta => visao.esquenta;
  bool get souAnfitriao => visao.souAnfitriao;

  Future<void> _tirar(BuildContext context) async {
    final tirar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tirar essa carta? 👎'),
        content: const Text('Ela sai do baralho desta noite e vem outra no lugar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Deixa')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tira essa'),
          ),
        ],
      ),
    );
    if (tirar == true) await acoes.tirar();
  }

  @override
  Widget build(BuildContext context) {
    final esquenta = this.esquenta;
    return Padding(
      padding: const EdgeInsets.only(top: EspacoBaralho.pequeno),
      child: Row(
        children: [
          if (esquenta != null)
            Expanded(
              child: Text(
                switch (esquenta.sobeEm) {
                  null => '🌡️ No máximo: ${esquenta.agora.emoji} ${esquenta.agora.titulo}',
                  1 => '🌡️ ${esquenta.agora.titulo} · esquenta na próxima',
                  final cartas => '🌡️ ${esquenta.agora.titulo} · esquenta em $cartas cartas',
                },
                style: const TextStyle(fontSize: 13, color: CoresBaralho.textoSecundario),
              ),
            )
          else
            const Spacer(),
          TextButton(
            key: const Key('como-joga'),
            style: TextButton.styleFrom(foregroundColor: CoresBaralho.textoSecundario),
            onPressed: () => abrirComoJoga(context, visao, rodada),
            child: const Text('ⓘ Como joga'),
          ),
          if (souAnfitriao)
          TextButton(
            key: const Key('tira-essa'),
            style: TextButton.styleFrom(foregroundColor: CoresBaralho.textoSecundario),
            onPressed: () => _tirar(context),
            child: const Text('👎 Tira essa'),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmarEncerramento(BuildContext context, AcoesDaSala acoes) async {
  final encerrar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Encerrar a noite? 🏆'),
      content: const Text('Todo mundo vai para os Prêmios da Noite e o mural. Dá para voltar com "Só mais uma".'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ainda não')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ver os prêmios'),
        ),
      ],
    ),
  );
  if (encerrar == true) await acoes.encerrar();
}

class _AreaDeAcao extends StatelessWidget {
  const _AreaDeAcao({required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final revelacao = rodada.revelacao;
    if (revelacao != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (rodada.modo) {
            ModoDeJogo.euNunca => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (revelacao.contadores.isNotEmpty)
                  _FilaDeHistorias(visao: visao, rodada: rodada, revelacao: revelacao, acoes: acoes),
                _RevelacaoEuNunca(visao: visao, revelacao: revelacao),
              ]),
            ModoDeJogo.casaisEmJogo => RevelacaoDoCasal(visao: visao, rodada: rodada, acoes: acoes),
            ModoDeJogo.tribunal => _RevelacaoDoTribunal(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.jurados => _RevelacaoDosJurados(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.impostor => _RevelacaoDoImpostor(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.maisProvavel when rodada.jokenpo =>
              RevelacaoDoJokenpo(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.maisProvavel when rodada.duelo =>
              _RevelacaoDoDuelo(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.imagemEAcao => RevelacaoDaMimica(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.correio => RevelacaoDoCorreio(visao: visao, rodada: rodada, revelacao: revelacao, acoes: acoes),
            ModoDeJogo.termineAFrase => RevelacaoDasFrases(visao: visao, revelacao: revelacao),
            ModoDeJogo.duasVerdades => RevelacaoDaMentira(visao: visao, rodada: rodada, revelacao: revelacao),
            ModoDeJogo.chutaAi => RevelacaoDosChutes(visao: visao, rodada: rodada, revelacao: revelacao),
            _ => _RevelacaoMaisProvavel(visao: visao, revelacao: revelacao),
          },
          MomentosDaRodada(visao: visao, rodada: rodada, acoes: acoes),
          const SizedBox(height: EspacoBaralho.grande),
          ProximaCarta(visao: visao, aoTocar: acoes.proxima),
        ],
      );
    }

    return switch (rodada.modo) {
      ModoDeJogo.euNunca => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: Row(children: [
            Expanded(child: _BotaoDeResposta(
              rotulo: '🙋 Já fiz',
              escolhido: rodada.minhaResposta == respostaJa,
              aoTocar: () => acoes.responder(respostaJa),
            )),
            const SizedBox(width: EspacoBaralho.medio),
            Expanded(child: _BotaoDeResposta(
              rotulo: '😇 Nunca fiz',
              escolhido: rodada.minhaResposta == respostaNunca,
              aoTocar: () => acoes.responder(respostaNunca),
            )),
          ]),
        ),
      ModoDeJogo.maisProvavel when !rodada.pedeResposta => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContagemParaApontar(visao: visao, rodada: rodada, aoContar: acoes.iniciarCronometro),
            const SizedBox(height: EspacoBaralho.grande),
            QuemFoiApontado(visao: visao, rodada: rodada, aoMarcar: acoes.marcarApontado),
            const SizedBox(height: EspacoBaralho.grande),
            ProximaCarta(visao: visao, aoTocar: acoes.proxima),
          ],
        ),
      ModoDeJogo.maisProvavel when rodada.jokenpo => PainelDoJokenpo(visao: visao, rodada: rodada, acoes: acoes),
      ModoDeJogo.maisProvavel when rodada.duelo => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: rodada.duelistas.contains(visao.euId)
              ? const Text('Você está no duelo! Capricha 🔥',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
              : Column(children: [
                  Text('Quem mandou melhor?', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: EspacoBaralho.medio),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final jogador in [for (final id in rodada.duelistas) ?visao.jogador(id)]) ...[
                      if (jogador.id != rodada.duelistas.first) const SizedBox(width: EspacoBaralho.medio),
                      _BotaoDeVoto(
                        key: Key('votar-${jogador.id}'),
                        jogador: jogador,
                        escolhido: rodada.minhaResposta == jogador.id,
                        aoTocar: () => acoes.responder(jogador.id),
                      ),
                    ],
                  ]),
                ]),
        ),
      ModoDeJogo.maisProvavel => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: Wrap(
            spacing: EspacoBaralho.pequeno,
            runSpacing: EspacoBaralho.pequeno,
            alignment: WrapAlignment.center,
            children: [
              for (final jogador in visao.jogadores)
                _BotaoDeVoto(
                  jogador: jogador,
                  escolhido: rodada.minhaResposta == jogador.id,
                  aoTocar: () => acoes.responder(jogador.id),
                ),
            ],
          ),
        ),
      ModoDeJogo.bebaSe => _MePegou(visao: visao, rodada: rodada, acoes: acoes),
      ModoDeJogo.regraRelampago => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A carta já mostra a regra: aqui só a isca e o vacilo.
            RegraEmJogo(visao: visao, acoes: acoes, mostrarTexto: false),
            ProximaCarta(visao: visao, aoTocar: acoes.proxima, rotulo: 'Valendo! Próxima carta'),
          ],
        ),
      ModoDeJogo.elogios => ProximaCarta(visao: visao, aoTocar: acoes.proxima, rotulo: 'Pronto! Próxima carta'),
      ModoDeJogo.musica => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _RodaDeMusica(visao: visao, rodada: rodada, acoes: acoes),
          ProximaCarta(visao: visao, aoTocar: acoes.proxima),
        ]),
      ModoDeJogo.correio => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: visao.euId == rodada.alvo
              ? const SizedBox.shrink()
              : EscreverBilhete(key: ValueKey('bilhete-${rodada.numero}'), visao: visao, rodada: rodada, acoes: acoes),
        ),
      // A pessoa da vez escreve primeiro; até lá, a turma só espera.
      ModoDeJogo.duasVerdades when rodada.afirmacoes.isEmpty => visao.euId == rodada.alvo
          ? EscreverDuasVerdades(key: ValueKey('duas-verdades-${rodada.numero}'), acoes: acoes)
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              EsperandoAsAfirmacoes(visao: visao, rodada: rodada),
              const SizedBox(height: EspacoBaralho.grande),
              if (visao.souAnfitriao) TextButton(onPressed: acoes.proxima, child: const Text('Pular carta')),
            ]),
      ModoDeJogo.duasVerdades => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: visao.euId == rodada.alvo
              ? MinhasAfirmacoes(rodada: rodada)
              : VotarNaMentira(rodada: rodada, acoes: acoes),
        ),
      ModoDeJogo.chutaAi => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: ChutarNumero(key: ValueKey('chute-${rodada.numero}'), rodada: rodada, acoes: acoes),
        ),
      ModoDeJogo.termineAFrase => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: rodada.escrevendo
              ? EscreverFrase(key: ValueKey('escrever-frase-${rodada.numero}'), rodada: rodada, acoes: acoes)
              : VotarNaFrase(rodada: rodada, acoes: acoes),
        ),
      ModoDeJogo.imagemEAcao => PainelDaMimica(visao: visao, rodada: rodada, acoes: acoes),
      ModoDeJogo.impostor => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _PistasDoImpostor(visao: visao, rodada: rodada),
          const SizedBox(height: EspacoBaralho.grande),
          _Respondendo(
            visao: visao,
            rodada: rodada,
            acoes: acoes,
            opcoes: Wrap(
              spacing: EspacoBaralho.pequeno,
              runSpacing: EspacoBaralho.pequeno,
              alignment: WrapAlignment.center,
              children: [
                for (final jogador in visao.jogadores)
                  if (jogador.id != visao.euId)
                    _BotaoDeVoto(
                      key: Key('votar-${jogador.id}'),
                      jogador: jogador,
                      escolhido: rodada.minhaResposta == jogador.id,
                      aoTocar: () => acoes.responder(jogador.id),
                    ),
              ],
            ),
          ),
        ]),
      ModoDeJogo.casaisEmJogo => RespostaDoCasal(visao: visao, rodada: rodada, acoes: acoes),
      ModoDeJogo.jurados => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: visao.euId == rodada.alvo
              ? const Text('⭐', key: Key('avaliado-esperando'), textAlign: TextAlign.center, style: TextStyle(fontSize: 56))
              : _Estrelas(nota: int.tryParse(rodada.minhaResposta ?? ''), aoDar: (nota) => acoes.responder('$nota')),
        ),
      ModoDeJogo.tribunal => _Respondendo(
          visao: visao,
          rodada: rodada,
          acoes: acoes,
          opcoes: visao.euId == rodada.alvo
              ? const Text('😬', key: Key('reu-esperando'), textAlign: TextAlign.center, style: TextStyle(fontSize: 56))
              : Row(children: [
                  Expanded(child: _BotaoDeResposta(
                    rotulo: '👍 Sim',
                    escolhido: rodada.minhaResposta == respostaSim,
                    aoTocar: () => acoes.responder(respostaSim),
                  )),
                  const SizedBox(width: EspacoBaralho.medio),
                  Expanded(child: _BotaoDeResposta(
                    rotulo: '👎 Não',
                    escolhido: rodada.minhaResposta == respostaNao,
                    aoTocar: () => acoes.responder(respostaNao),
                  )),
                ]),
        ),
    };
  }
}

class _Respondendo extends StatelessWidget {
  const _Respondendo({required this.visao, required this.rodada, required this.acoes, required this.opcoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;
  final Widget opcoes;

  @override
  Widget build(BuildContext context) {
    final votantes = [
      for (final jogador in visao.jogadores)
        if ((!_ficaDeFora(rodada) || jogador.id != rodada.alvo) &&
            !rodada.duelistas.contains(jogador.id) &&
            // A mesa não espera quem caiu, a não ser que já tenha respondido.
            (jogador.conectado || jogador.respondeu))
          jogador,
    ];
    final faltam = votantes.where((j) => !j.respondeu).toList();
    final souReu = (_ficaDeFora(rodada) && visao.euId == rodada.alvo) || rodada.duelistas.contains(visao.euId);
    final correio = rodada.modo == ModoDeJogo.correio;
    final frase = rodada.modo == ModoDeJogo.termineAFrase;
    // Escrevendo, "revelar" leva para a votação; com uma frase só, todo mundo sabe quem escreveu.
    final escrevendo = correio || rodada.escrevendo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          souReu
              ? (correio
                  ? 'A turma está escrevendo sobre você…'
                  : rodada.duelo
                      ? 'A turma vai votar em quem mandou melhor.'
                      : rodada.modo == ModoDeJogo.jurados
                          ? 'Os jurados estão te avaliando…'
                          : rodada.modo == ModoDeJogo.duasVerdades
                              ? 'A turma está tentando achar a sua mentira…'
                              : 'A turma está te julgando…')
              : correio
                  ? (rodada.minhaResposta == null ? 'Escreva em segredo:' : 'Bilhete guardado. Dá para trocar até revelar.')
                  : frase && rodada.escrevendo
                  ? (rodada.minhaResposta == null
                      ? 'Complete em segredo:'
                      : 'Frase guardada. Dá para trocar até todo mundo escrever.')
                  : frase && rodada.minhaResposta == null
                  ? 'Vote em segredo na melhor:'
                  : rodada.minhaResposta == null
                  ? switch (rodada.modo) {
                      ModoDeJogo.euNunca => 'Responda em segredo:',
                      ModoDeJogo.jurados => 'Dê sua nota em segredo:',
                      ModoDeJogo.impostor => 'Depois das pistas, vote em segredo em quem é o impostor:',
                      ModoDeJogo.duasVerdades => 'Qual é a mentira? Vote em segredo:',
                      ModoDeJogo.chutaAi => 'Chute em segredo:',
                      _ => 'Vote em segredo:',
                    }
                  : 'Resposta guardada. Dá para trocar até revelar.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.medio),
        opcoes,
        const SizedBox(height: EspacoBaralho.grande),
        Text(
          escrevendo
              ? '${rodada.respostas} de ${votantes.length} já escreveram'
              : rodada.modo == ModoDeJogo.chutaAi
                  ? '${rodada.respostas} de ${votantes.length} chutaram'
                  : rodada.duelo || frase || rodada.modo == ModoDeJogo.duasVerdades
                  ? '${rodada.respostas} de ${votantes.length} votaram'
                  : '${rodada.respostas} de ${votantes.length} responderam',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (faltam.isNotEmpty)
          Text(
            'Falta: ${faltam.map((j) => j.nome).join(', ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.textoApagado),
          ),
        const SizedBox(height: EspacoBaralho.medio),
        if (visao.souAnfitriao)
        Row(children: [
          Expanded(child: TextButton(onPressed: acoes.proxima, child: const Text('Pular carta'))),
          Expanded(
            child: TextButton(
              // No correio, com um bilhete só todo mundo sabe quem escreveu.
              onPressed: rodada.respostas >= (escrevendo ? 2 : 1) ? acoes.revelar : null,
              child: Text(frase && rodada.escrevendo ? 'Ir para a votação' : 'Revelar agora'),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Tribunal e correio: a carta é sobre alguém, que não vota nem escreve.
bool _ficaDeFora(Rodada rodada) =>
    rodada.modo == ModoDeJogo.tribunal ||
    rodada.modo == ModoDeJogo.correio ||
    rodada.modo == ModoDeJogo.jurados ||
    rodada.modo == ModoDeJogo.duasVerdades;

class _BotaoDeResposta extends StatelessWidget {
  const _BotaoDeResposta({required this.rotulo, required this.escolhido, required this.aoTocar});

  final String rotulo;
  final bool escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: escolhido
          ? FilledButton(onPressed: aoTocar, child: Text(rotulo, style: const TextStyle(fontSize: 18)))
          : OutlinedButton(onPressed: aoTocar, child: Text(rotulo, style: const TextStyle(fontSize: 18))),
    );
  }
}

class _BotaoDeVoto extends StatelessWidget {
  const _BotaoDeVoto({super.key, required this.jogador, required this.escolhido, required this.aoTocar});

  final Jogador jogador;
  final bool escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: escolhido ? CoresBaralho.ambarEscuro : CoresBaralho.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: escolhido ? CoresBaralho.ambar : CoresBaralho.borda, width: escolhido ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: SizedBox(
          width: 104,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EspacoBaralho.medio, horizontal: EspacoBaralho.pequeno),
            child: Column(children: [
              AvatarDoJogador(jogador: jogador, tamanho: 64),
              const SizedBox(height: EspacoBaralho.mini),
              Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Beba se: quem a carta pegou marca o próprio gole.
class _MePegou extends StatelessWidget {
  const _MePegou({
    required this.visao,
    required this.rodada,
    required this.acoes,
  });

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final beberam = [for (final id in rodada.beberam) ?visao.jogador(id)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 64,
              child: rodada.euBebi
                  ? FilledButton(onPressed: acoes.alternarBebi, child: Text('${_mePegou(visao, rodada)} ✓'))
                  : OutlinedButton(onPressed: acoes.alternarBebi, child: Text(_mePegou(visao, rodada))),
            ),
          ),
          if (visao.configuracao.passarSozinho) ...[
            const SizedBox(width: EspacoBaralho.pequeno),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 64,
                // Quem já respondeu que não pegou vê o botão marcado.
                child: !rodada.euBebi && rodada.prontos.contains(visao.euId)
                    ? FilledButton(onPressed: null, child: const Text('Não ✓'))
                    : OutlinedButton(
                        // Marcou "Me pegou" por engano? O "Não" desfaz.
                        onPressed: rodada.euBebi ? acoes.alternarBebi : acoes.marcarPronto,
                        child: const Text('Não 👍'),
                      ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: EspacoBaralho.medio),
        Text(
          beberam.isEmpty ? 'Marque se a carta pegou você.' : 'Pegou: ${beberam.map((j) => _comDestino(rodada, visao, j)).join(', ')}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.grande),
        ProximaCarta(visao: visao, aoTocar: acoes.proxima),
      ],
    );
  }
}

/// Quem a carta pegou e, se usou carta na manga, para onde foi: "Ana → 🎯 passou para Bia".
String _comDestino(Rodada rodada, VisaoDaSala visao, Jogador jogador) {
  final uso = rodada.usos.where((u) => u.quem == jogador.id).firstOrNull;
  final alvo = visao.jogador(uso?.alvo ?? '')?.nome;
  return switch (uso?.carta) {
    null || CartaNaManga.dobra => jogador.nome,
    CartaNaManga.escudo => '${jogador.nome} → 🛡️ se livrou',
    CartaNaManga.passaABola => '${jogador.nome} → 🎯 passou para $alvo',
    CartaNaManga.devolve => '${jogador.nome} → ↩️ devolveu para $alvo',
    CartaNaManga.batataQuente => '${jogador.nome} → 🥔 jogou em $alvo',
  };
}

/// "Me pegou! 🍺"; na dose, quanto bebe de verdade.
String _mePegou(VisaoDaSala visao, Rodada rodada) {
  final unidade = visao.eu.semAlcool ? '⭐' : '🍺';
  return switch (rodada.goles) {
    final goles? => visao.eu.semAlcool ? 'Me pegou! +$goles $unidade' : 'Me pegou! Bebe $goles $unidade',
    null => 'Me pegou! $unidade',
  };
}

class _RevelacaoEuNunca extends StatelessWidget {
  const _RevelacaoEuNunca({required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final ja = [for (final id in revelacao.jaFizeram) ?visao.jogador(id)];
    final nunca = [for (final id in revelacao.nuncaFizeram) ?visao.jogador(id)];
    final historia = revelacao.contaAHistoria == null ? null : visao.jogador(revelacao.contaAHistoria!);
    final titulo = Theme.of(context).textTheme.titleMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Com uma pessoa só, a foto grande já diz quem foi.
        if (historia != null)
          _DestaqueDaHistoria(visao: visao, jogador: historia)
        else if (ja.isEmpty)
          const _Recado(emoji: '😇', texto: 'Ninguém fez! Que turma comportada…')
        else if (nunca.isEmpty) ...[
          Text('Todo mundo já fez! Ninguém leva ponto 🙈', textAlign: TextAlign.center, style: titulo),
          const SizedBox(height: EspacoBaralho.medio),
          _ListaDePerdedores(visao: visao, jogadores: ja, mostrarDestino: false),
        ] else if (revelacao.minoriaLeva) ...[
          Text('Virou! A maioria já fez, então leva quem nunca fez 😇', textAlign: TextAlign.center, style: titulo),
          const SizedBox(height: EspacoBaralho.medio),
          _ListaDePerdedores(visao: visao, jogadores: nunca),
          const SizedBox(height: EspacoBaralho.medio),
          Text('Já fizeram: ${ja.map((j) => j.nome).join(', ')}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoApagado)),
        ] else ...[
          Text(ja.length == 1 ? 'Já fez:' : 'Já fizeram (${ja.length}):',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: EspacoBaralho.medio),
          _ListaDePerdedores(visao: visao, jogadores: ja),
        ],
      ],
    );
  }
}

class _RevelacaoMaisProvavel extends StatelessWidget {
  const _RevelacaoMaisProvavel({required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final ids = revelacao.escolhidos.isNotEmpty ? revelacao.escolhidos : revelacao.perderam;
    final maisVotados = [for (final id in ids) ?visao.jogador(id)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          maisVotados.length == 1
              ? 'A turma escolheu:'
              : (revelacao.elogio ? 'Empate! Todos levam:' : 'Empate! Todos bebem:'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: EspacoBaralho.medio),
        _ListaDePerdedores(visao: visao, jogadores: maisVotados, elogio: revelacao.elogio),
        const SizedBox(height: EspacoBaralho.grande),
        _VotosDeTodos(visao: visao, revelacao: revelacao),
      ],
    );
  }
}

/// Duelo: os dois lado a lado, com os votos; quem perdeu leva o ponto.
class _RevelacaoDoDuelo extends StatelessWidget {
  const _RevelacaoDoDuelo({required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final duelistas = [for (final id in rodada.duelistas) ?visao.jogador(id)];
    int votos(Jogador jogador) =>
        revelacao.votos.where((v) => v.jogadorId == jogador.id).fold(0, (soma, v) => soma + v.votos);
    final vencedor = revelacao.escolhidos.length == 1 ? visao.jogador(revelacao.escolhidos.single) : null;
    return Column(
      key: const Key('resultado-do-duelo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          vencedor != null ? '👑 ${vencedor.nome} venceu o duelo!' : '🤝 Empate! Os dois levam ponto.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: EspacoBaralho.base),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final jogador in duelistas)
              SizedBox(
                width: 140,
                child: Column(children: [
                  AvatarDoJogador(
                    jogador: jogador,
                    tamanho: jogador.id == vencedor?.id ? 104 : 84,
                    destaque: jogador.id == vencedor?.id ? CoresBaralho.ambar : null,
                  ),
                  const SizedBox(height: EspacoBaralho.mini),
                  Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(votos(jogador) == 1 ? '1 voto' : '${votos(jogador)} votos',
                      style: const TextStyle(color: CoresBaralho.textoSecundario)),
                  if (revelacao.perderam.contains(jogador.id))
                    Text(destinoDoPego(visao, jogador),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: CoresBaralho.ambar)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

/// Todo mundo da mesa com foto, nome e quantos votos levou.
class _VotosDeTodos extends StatelessWidget {
  const _VotosDeTodos({required this.visao, required this.revelacao});

  final VisaoDaSala visao;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    int votos(Jogador jogador) =>
        revelacao.votos.where((v) => v.jogadorId == jogador.id).fold(0, (soma, v) => soma + v.votos);
    final jogadores = [...visao.jogadores]..sort((a, b) => votos(b).compareTo(votos(a)));
    return Wrap(
      key: const Key('votos-de-todos'),
      alignment: WrapAlignment.center,
      spacing: EspacoBaralho.medio,
      runSpacing: EspacoBaralho.medio,
      children: [
        for (final jogador in jogadores)
          SizedBox(
            width: 76,
            child: Column(children: [
              AvatarDoJogador(
                jogador: jogador,
                tamanho: 52,
                destaque: revelacao.escolhidos.contains(jogador.id) ? CoresBaralho.ambar : null,
              ),
              const SizedBox(height: EspacoBaralho.mini),
              Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              Text(
                votos(jogador) == 1 ? '1 voto' : '${votos(jogador)} votos',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: CoresBaralho.textoApagado),
              ),
            ]),
          ),
      ],
    );
  }
}

class _ListaDePerdedores extends StatelessWidget {
  const _ListaDePerdedores({
    required this.visao,
    required this.jogadores,
    this.elogio = false,
    this.mostrarDestino = true,
  });

  final VisaoDaSala visao;
  final List<Jogador> jogadores;
  final bool elogio;

  /// Falso quando ninguém leva (todo mundo já fez): só as fotos.
  final bool mostrarDestino;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: EspacoBaralho.base,
      runSpacing: EspacoBaralho.base,
      children: [
        for (final jogador in jogadores)
          SizedBox(
            width: 100,
            child: Column(children: [
              AvatarDoJogador(jogador: jogador, tamanho: 84, destaque: CoresBaralho.ambar),
              const SizedBox(height: EspacoBaralho.mini),
              Text(jogador.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (mostrarDestino)
                Text(destinoDoEscolhido(visao, jogador, elogio: elogio),
                    style: const TextStyle(fontSize: 12, color: CoresBaralho.ambar)),
            ]),
          ),
      ],
    );
  }
}

/// Veredito do tribunal: o réu em destaque e o placar de sim e não, sem
/// dizer quem votou o quê (a turma é júri, não delator).
class _RevelacaoDoTribunal extends StatelessWidget {
  const _RevelacaoDoTribunal({required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final reu = visao.jogador(rodada.alvo ?? '');
    if (reu == null) return const Text('O réu saiu da sala. 🏃', textAlign: TextAlign.center);
    final sim = revelacao.jaFizeram.length;
    final nao = revelacao.nuncaFizeram.length;
    // Na zoeira, o "sim" condena; no elogio, o "não" condena e o "sim" elogia.
    final condenado = revelacao.perderam.contains(reu.id);
    final elogiado = revelacao.elogio && revelacao.escolhidos.contains(reu.id);
    final (titulo, detalhe) = switch ((revelacao.elogio, condenado || elogiado)) {
      (false, true) => ('Culpado(a)! 🔨', '${reu.nome} ${destinoDoEscolhido(visao, reu, elogio: false)}'),
      (false, false) => ('Absolvido(a)! 😇', 'A turma livrou a cara de ${reu.nome}.'),
      (true, true) when elogiado =>
        ('A turma concorda! 💛', '${reu.nome} ${destinoDoEscolhido(visao, reu, elogio: true, goles: 2)}'),
      (true, _) => ('A turma disse NÃO! 🔨', '${reu.nome} ${destinoDoPego(visao, reu)}'),
    };
    return Column(children: [
      AvatarDoJogador(
        jogador: reu,
        tamanho: 128,
        destaque: condenado ? CoresBaralho.ambar : CoresBaralho.tribunal,
      ),
      const SizedBox(height: EspacoBaralho.medio),
      Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      Text(detalhe, textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar, fontSize: 16)),
      const SizedBox(height: EspacoBaralho.medio),
      Text('👍 $sim   ·   👎 $nao',
          key: const Key('placar-do-tribunal'),
          style: Theme.of(context).textTheme.titleLarge),
    ]);
  }
}

/// Roda de Música: cada um canta na sua vez, na ordem sorteada, com a foto na tela.
class _RodaDeMusica extends StatefulWidget {
  const _RodaDeMusica({required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  State<_RodaDeMusica> createState() => _RodaDeMusicaState();
}

class _RodaDeMusicaState extends State<_RodaDeMusica> {
  @override
  void initState() {
    super.initState();
    _avisarSeForMinhaVez(null);
  }

  @override
  void didUpdateWidget(_RodaDeMusica antigo) {
    super.didUpdateWidget(antigo);
    _avisarSeForMinhaVez(_daVez(antigo.rodada));
  }

  static String? _daVez(Rodada rodada) =>
      rodada.pendentes.where((p) => p.motivo == MotivoPendente.cantar).firstOrNull?.jogadorId;

  /// Chegou a minha vez: o celular vibra, para ninguém precisar chamar.
  void _avisarSeForMinhaVez(String? antes) {
    final agora = _daVez(widget.rodada);
    if (agora == widget.visao.euId && agora != antes) HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    final visao = widget.visao;
    final rodada = widget.rodada;
    final acoes = widget.acoes;
    final fila = [for (final id in rodada.fila) ?visao.jogador(id)];
    final daVezId = rodada.pendentes.where((p) => p.motivo == MotivoPendente.cantar).firstOrNull?.jogadorId;
    final daVez = daVezId == null ? null : visao.jogador(daVezId);
    final indice = daVez == null ? fila.length : fila.indexWhere((j) => j.id == daVez.id);
    final travaram = [for (final id in rodada.travaram) ?visao.jogador(id)];
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.grande),
      padding: const EdgeInsets.all(EspacoBaralho.base),
      decoration: BoxDecoration(
        color: CoresBaralho.musica.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoresBaralho.musica),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (daVez == null)
          Text('A roda fechou! 🎶', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)
        else ...[
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarDoJogador(key: ValueKey(daVez.id), jogador: daVez, tamanho: 128, destaque: CoresBaralho.musica),
                const Positioned(right: -6, bottom: -4, child: Text('🎤', style: TextStyle(fontSize: 40))),
              ],
            ),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          Text(daVez.id == visao.euId ? '🎤 É a sua vez de cantar!' : '🎤 Vez de ${daVez.nome} cantar!',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          // Quem vem depois já se prepara: ninguém precisa ficar chamando.
          Text(
            '${indice + 1} de ${fila.length} · '
            '${indice + 1 < fila.length ? 'depois: ${fila[indice + 1].nome}' : 'fecha a roda!'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CoresBaralho.ambar),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          if (daVez.id == visao.euId)
            FilledButton(onPressed: acoes.marcarPronto, child: const Text('🎤 Cantei · próximo!'))
          else ...[
            // Reserva: quem está cantando sem o celular na mão.
            if (visao.souAnfitriao)
              OutlinedButton(onPressed: () => acoes.confirmarHistoria(daVez.id), child: Text('${daVez.nome} cantou ✓')),
            // Qualquer um da turma marca o travou, menos quem está cantando.
            TextButton(onPressed: () => acoes.marcarTravou(daVez.id), child: const Text('😵 Travou')),
          ],
        ],
        if (travaram.isNotEmpty)
          Text('😵 Travou: ${travaram.map((j) => j.nome).join(', ')}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.coral, fontWeight: FontWeight.w600)),
        const SizedBox(height: EspacoBaralho.medio),
        // Quem já cantou fica marcado; quem vem depois, apagado.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.pequeno,
          children: [
            for (final (i, jogador) in fila.indexed)
              Opacity(
                opacity: i > indice ? 0.45 : 1,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AvatarDoJogador(jogador: jogador, tamanho: 36),
                  Text(
                    rodada.travaram.contains(jogador.id) ? '😵' : (i < indice ? '✓' : jogador.nome),
                    style: const TextStyle(fontSize: 11),
                  ),
                ]),
              ),
          ],
        ),
      ]),
    );
  }
}

/// Jurados: 1 a 5 estrelas, em segredo. Tocar em outra estrela troca a nota.
class _Estrelas extends StatelessWidget {
  const _Estrelas({required this.nota, required this.aoDar});

  final int? nota;
  final ValueChanged<int> aoDar;

  @override
  Widget build(BuildContext context) {
    final escolhida = nota;
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var estrela = 1; estrela <= 5; estrela++)
            IconButton(
              key: Key('estrela-$estrela'),
              iconSize: 44,
              onPressed: () => aoDar(estrela),
              icon: Icon(
                escolhida != null && estrela <= escolhida ? Icons.star_rounded : Icons.star_border_rounded,
                color: CoresBaralho.ambar,
              ),
            ),
        ],
      ),
      if (escolhida != null)
        Text('Sua nota: ${'⭐' * escolhida}', style: const TextStyle(color: CoresBaralho.textoSecundario)),
    ]);
  }
}

/// Impostor: o tema e a ordem das pistas, faladas em voz alta antes do voto.
class _PistasDoImpostor extends StatelessWidget {
  const _PistasDoImpostor({required this.visao, required this.rodada});

  final VisaoDaSala visao;
  final Rodada rodada;

  @override
  Widget build(BuildContext context) {
    final ordem = [
      for (final id in rodada.fila)
        if (visao.jogador(id) case final jogador?) id == visao.euId ? 'Você' : jogador.nome,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rodada.dica case final dica?)
          Text(dica, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        Text(
          rodada.souImpostor
              ? 'Ninguém pode saber! Ouça as pistas e invente a sua. 🤫'
              : 'Dê uma pista sem entregar a palavra: o impostor está ouvindo. 👀',
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        Text(
          'Pistas, nesta ordem: ${ordem.join(' → ')}',
          key: const Key('ordem-das-pistas'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RevelacaoDoImpostor extends StatelessWidget {
  const _RevelacaoDoImpostor({required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final impostor = visao.jogador(revelacao.impostor ?? '');
    if (impostor == null) return const Text('O impostor saiu da sala. 🏃', textAlign: TextAlign.center);
    final erraram = [for (final id in revelacao.perderam) ?visao.jogador(id)];
    return Column(
      key: const Key('resultado-do-impostor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AvatarDoJogador(
            jogador: impostor,
            tamanho: 128,
            destaque: revelacao.pegaram ? CoresBaralho.impostor : CoresBaralho.ambar,
          ),
        ),
        const SizedBox(height: EspacoBaralho.medio),
        Text(
          revelacao.pegaram
              ? 'Pegaram! ${impostor.nome} era o impostor 🕵️'
              : '${impostor.nome} era o impostor e escapou! 😈',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('A palavra era: ${rodada.texto}',
            textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario, fontSize: 16)),
        const SizedBox(height: EspacoBaralho.medio),
        if (revelacao.pegaram)
          Text('${impostor.nome} ${destinoDoPego(visao, impostor)}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar, fontSize: 16))
        else if (erraram.isNotEmpty) ...[
          Text('Quem votou errado: ${erraram.map((j) => j.nome).join(', ')}',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: EspacoBaralho.pequeno),
          _ListaDePerdedores(visao: visao, jogadores: erraram, elogio: false),
        ],
        const SizedBox(height: EspacoBaralho.grande),
        _VotosDeTodos(visao: visao, revelacao: revelacao),
      ],
    );
  }
}

class _RevelacaoDosJurados extends StatelessWidget {
  const _RevelacaoDosJurados({required this.visao, required this.rodada, required this.revelacao});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;

  @override
  Widget build(BuildContext context) {
    final avaliado = visao.jogador(rodada.alvo ?? '');
    if (avaliado == null) return const Text('Quem estava sendo avaliado saiu da sala. 🏃', textAlign: TextAlign.center);
    final media = revelacao.media ?? 0;
    final aprovado = revelacao.escolhidos.contains(avaliado.id);
    final reprovado = revelacao.perderam.contains(avaliado.id);
    final (titulo, detalhe) = aprovado
        ? ('Aprovado(a) pelos jurados! 🏆', '${avaliado.nome} ${destinoDoEscolhido(visao, avaliado, elogio: true, goles: 2)}')
        : reprovado
            ? ('Reprovado(a) pelos jurados! 😬', '${avaliado.nome} ${destinoDoPego(visao, avaliado)}')
            : ('Na média 🤷', 'Nem aprovado(a), nem reprovado(a). Fica por isso mesmo.');
    return Column(children: [
      AvatarDoJogador(jogador: avaliado, tamanho: 128, destaque: aprovado ? CoresBaralho.ambar : CoresBaralho.jurados),
      const SizedBox(height: EspacoBaralho.medio),
      Text('⭐ ${media.toStringAsFixed(1).replaceAll('.', ',')}',
          key: const Key('media-dos-jurados'), style: Theme.of(context).textTheme.displaySmall),
      Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
      Text(detalhe, textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar, fontSize: 16)),
      if (revelacao.notas.isNotEmpty) ...[
        const SizedBox(height: EspacoBaralho.pequeno),
        Text('Notas: ${revelacao.notas.join(' · ')}',
            textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
      ],
    ]);
  }
}

/// "Conta essa": quem já fez conta a sua, um de cada vez, com a foto na tela.
class _FilaDeHistorias extends StatelessWidget {
  const _FilaDeHistorias({required this.visao, required this.rodada, required this.revelacao, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final Revelacao revelacao;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final contadores = [for (final id in revelacao.contadores) ?visao.jogador(id)];
    final daVezId = rodada.pendentes
        .where((p) => p.motivo == MotivoPendente.historia && revelacao.contadores.contains(p.jogadorId))
        .firstOrNull
        ?.jogadorId;
    final daVez = daVezId == null ? null : visao.jogador(daVezId);
    final indice = daVez == null ? contadores.length : contadores.indexWhere((j) => j.id == daVez.id);
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.grande),
      padding: const EdgeInsets.all(EspacoBaralho.base),
      decoration: BoxDecoration(
        color: CoresBaralho.coral.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoresBaralho.coral),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (daVez == null)
          Text('Todo mundo contou! 🎉', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)
        else ...[
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarDoJogador(key: ValueKey(daVez.id), jogador: daVez, tamanho: 128, destaque: CoresBaralho.coral),
                const Positioned(right: -6, bottom: -4, child: Text('🎤', style: TextStyle(fontSize: 40))),
              ],
            ),
          ),
          const SizedBox(height: EspacoBaralho.medio),
          Text('🎤 Conta essa, ${daVez.nome}!',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text('${indice + 1} de ${contadores.length}',
              textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar)),
          const SizedBox(height: EspacoBaralho.medio),
          if (daVez.id == visao.euId)
            FilledButton(onPressed: acoes.marcarPronto, child: const Text('🎤 Contei'))
          else if (visao.souAnfitriao)
            OutlinedButton(onPressed: () => acoes.confirmarHistoria(daVez.id), child: Text('${daVez.nome} contou ✓'))
          else
            Text('Esperando ${daVez.nome} contar…',
                textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.textoSecundario)),
        ],
        const SizedBox(height: EspacoBaralho.medio),
        // Quem já contou fica marcado; quem vem depois, apagado.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: EspacoBaralho.pequeno,
          children: [
            for (final (i, jogador) in contadores.indexed)
              Opacity(
                opacity: i > indice ? 0.45 : 1,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AvatarDoJogador(jogador: jogador, tamanho: 36),
                  Text(i < indice ? '✓' : jogador.nome, style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ],
        ),
      ]),
    );
  }
}

class _DestaqueDaHistoria extends StatelessWidget {
  const _DestaqueDaHistoria({required this.visao, required this.jogador});

  final VisaoDaSala visao;
  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.grande),
      padding: const EdgeInsets.all(EspacoBaralho.base),
      decoration: BoxDecoration(
        color: CoresBaralho.coral.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoresBaralho.coral),
      ),
      child: Column(children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarDoJogador(jogador: jogador, tamanho: 128, destaque: CoresBaralho.coral),
            const Positioned(right: -6, bottom: -4, child: Text('🎤', style: TextStyle(fontSize: 40))),
          ],
        ),
        const SizedBox(height: EspacoBaralho.medio),
        Text('${jogador.nome}, conta essa história!',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Text('Só ${jogador.nome} fez · ${destinoDoPego(visao, jogador)}',
            textAlign: TextAlign.center, style: const TextStyle(color: CoresBaralho.ambar)),
        const Text('A turma quer detalhes.',
            textAlign: TextAlign.center, style: TextStyle(color: CoresBaralho.textoSecundario)),
      ]),
    );
  }
}

class _Recado extends StatelessWidget {
  const _Recado({required this.emoji, required this.texto});

  final String emoji;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 40)),
      Text(texto, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
    ]);
  }
}

Future<void> abrirPlacar(BuildContext context, VisaoDaSala visao, AcoesDaSala acoes) {
  final ordenados = [...visao.jogadores]..sort((a, b) => b.pontos.compareTo(a.pontos));
  final porGole = visao.configuracao.pontosPorGole;
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(EspacoBaralho.grande, 0, EspacoBaralho.grande, EspacoBaralho.grande),
        children: [
          Text('🏆 Placar da noite', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: EspacoBaralho.base),
          for (final (posicao, jogador) in ordenados.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AvatarDoJogador(jogador: jogador),
              title: Text(jogador.nome + (jogador.id == visao.euId ? ' (você)' : '')),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (posicao == 0 && jogador.pontos > 0)
                    const Text('Rei(nha) da noite 👑', style: TextStyle(color: CoresBaralho.ambar)),
                  if (visao.configuracao.cartasNaManga && jogador.cartasNaManga > 0)
                    Text('🃏 ${jogador.cartasNaManga} na manga'),
                  if (!jogador.semAlcool && porGole > 1)
                    Text('${jogador.pontos == 1 ? '1 ponto' : '${jogador.pontos} pontos'} · '
                        'cofrinho ${jogador.cofrinho}/$porGole'),
                  if (!jogador.conectado) ...[
                    const Text('📵 Sem conexão', style: TextStyle(color: CoresBaralho.coral)),
                    if (visao.souAnfitriao && jogador.id != visao.euId)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => _confirmarTirarDaSala(context, jogador, acoes),
                          child: const Text('Tirar da sala'),
                        ),
                      ),
                  ],
                ],
              ),
              trailing: Text(jogador.placar,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
        ],
      ),
    ),
  );
}

/// Quem caiu e foi embora de vez sai do placar; se voltar, entra como pessoa nova.
Future<void> _confirmarTirarDaSala(BuildContext context, Jogador jogador, AcoesDaSala acoes) async {
  final tirar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Tirar ${jogador.nome} da sala?'),
      content: const Text('Os pontos saem do placar. Se voltar, entra como pessoa nova.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Deixar')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tirar', style: TextStyle(color: CoresBaralho.coral)),
        ),
      ],
    ),
  );
  if (tirar != true || !context.mounted) return;
  Navigator.pop(context);
  await acoes.tirarDaSala(jogador.id);
}
