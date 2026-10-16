import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../dominio/modelos.dart';
import '../infraestrutura/compartilhar_imagem.dart';
import '../tema/tema_baralho.dart';
import 'momentos.dart';
import 'sala.dart';
import 'visual.dart';

/// Fim da noite: os Prêmios num cartão para mandar no grupo e o mural com
/// as selfies de reação.
class FimDaNoite extends StatefulWidget {
  const FimDaNoite({super.key, required this.visao, required this.acoes, this.hoje});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  /// Data impressa no cartão; os testes fixam uma.
  final DateTime? hoje;

  @override
  State<FimDaNoite> createState() => _FimDaNoiteState();
}

class _FimDaNoiteState extends State<FimDaNoite> {
  final _cartao = GlobalKey();
  var _compartilhando = false;

  Future<void> _compartilhar() async {
    setState(() => _compartilhando = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final limite = _cartao.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (limite == null) throw StateError('Não foi possível gerar a imagem.');
      final proporcao = (1080 / limite.size.width).clamp(1.0, 4.0).toDouble();
      final imagem = await limite.toImage(pixelRatio: proporcao);
      final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
      if (dados == null) throw StateError('Não foi possível gerar a imagem.');
      await compartilharImagem(dados.buffer.asUint8List(), 'premios-da-noite.png');
    } catch (_) {
      if (mounted) avisar(context, 'Não deu para gerar a imagem. Tente de novo.');
    } finally {
      if (mounted) setState(() => _compartilhando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visao = widget.visao;
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Fim da noite'),
        actions: [
          IconButton(
            tooltip: 'Sair da sala',
            onPressed: () => confirmarSaida(context, widget.acoes),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(EspacoBaralho.base),
              children: [
                RepaintBoundary(
                  key: _cartao,
                  child: CartaoDosPremios(visao: visao, hoje: widget.hoje ?? DateTime.now()),
                ),
                const SizedBox(height: EspacoBaralho.base),
                FilledButton.icon(
                  onPressed: _compartilhando ? null : _compartilhar,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Mandar no grupo da turma'),
                ),
                if (visao.momentos.isNotEmpty) ...[
                  const SizedBox(height: EspacoBaralho.enorme),
                  Text('📸 Mural da noite (${visao.momentos.length})', style: texto.titleLarge),
                  const SizedBox(height: EspacoBaralho.mini),
                  MuralParaSalvar(visao: visao, acoes: widget.acoes),
                ],
                const SizedBox(height: EspacoBaralho.enorme),
                if (visao.souAnfitriao)
                  OutlinedButton(onPressed: widget.acoes.retomar, child: const Text('Só mais uma rodada 🍻'))
                else
                  Text(
                    '${visao.anfitriao?.nome ?? 'Quem criou a sala'} pode puxar "só mais uma".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CoresBaralho.textoApagado),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O cartão que vai para o WhatsApp: resumo da noite, prêmios com as
/// selfies e um pedacinho do mural.
class CartaoDosPremios extends StatelessWidget {
  const CartaoDosPremios({super.key, required this.visao, required this.hoje});

  final VisaoDaSala visao;
  final DateTime hoje;

  static String _duracao(int minutos) =>
      minutos < 60 ? '$minutos min' : '${minutos ~/ 60}h${(minutos % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final resumo = visao.resumo;
    final premios = visao.premios ?? const [];
    final data = '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
    return Container(
      padding: const EdgeInsets.all(EspacoBaralho.grande),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2410), Color(0xFF1E1714), Color(0xFF2A1022)],
        ),
        border: Border.all(color: CoresBaralho.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 44)),
          const Text('Prêmios da Noite', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          Text('Baralho da Resenha · $data', textAlign: TextAlign.center,
              style: const TextStyle(color: CoresBaralho.textoSecundario)),
          if (resumo != null) ...[
            const SizedBox(height: EspacoBaralho.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Numero(valor: '${resumo.cartas}', rotulo: 'cartas'),
                if (resumo.minutos > 0) _Numero(valor: _duracao(resumo.minutos), rotulo: 'de resenha'),
                if (resumo.goles > 0) _Numero(valor: '${resumo.goles}', rotulo: 'goles'),
                if (resumo.pontos > 0) _Numero(valor: '${resumo.pontos}', rotulo: 'pontos 🥤'),
              ],
            ),
          ],
          const SizedBox(height: EspacoBaralho.grande),
          if (premios.isEmpty)
            const Text('Noite comportada demais para prêmios 😇', textAlign: TextAlign.center,
                style: TextStyle(color: CoresBaralho.textoSecundario))
          else
            for (final premio in premios) _LinhaDoPremio(premio: premio, visao: visao),
          if (visao.momentos.isNotEmpty) ...[
            const SizedBox(height: EspacoBaralho.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final momento in visao.momentos.reversed.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImagemDoMomento(momento: momento, lado: 64),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: EspacoBaralho.base),
          const Text('🃏 baralho da resenha', textAlign: TextAlign.center,
              style: TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: EspacoBaralho.medio),
        child: Column(children: [
          Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CoresBaralho.ambar)),
          Text(rotulo, style: const TextStyle(fontSize: 12, color: CoresBaralho.textoSecundario)),
        ]),
      );
}

class _LinhaDoPremio extends StatelessWidget {
  const _LinhaDoPremio({required this.premio, required this.visao});

  final Premio premio;
  final VisaoDaSala visao;

  @override
  Widget build(BuildContext context) {
    final ganhadores = [for (final id in premio.jogadores) ?visao.jogador(id)];
    return Container(
      margin: const EdgeInsets.only(bottom: EspacoBaralho.medio),
      padding: const EdgeInsets.all(EspacoBaralho.medio),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52.0 + (ganhadores.length - 1).clamp(0, 2) * 26,
            height: 52,
            child: Stack(children: [
              for (final (posicao, jogador) in ganhadores.take(3).indexed)
                Positioned(
                  left: posicao * 26.0,
                  child: AvatarDoJogador(jogador: jogador, tamanho: 52, destaque: CoresBaralho.ambar),
                ),
            ]),
          ),
          const SizedBox(width: EspacoBaralho.medio),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${premio.emoji} ${premio.titulo}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(ganhadores.map((j) => j.nome).join(' e '),
                    style: const TextStyle(color: CoresBaralho.ambar, fontWeight: FontWeight.w600)),
                Text(premio.descricao,
                    style: const TextStyle(fontSize: 12, color: CoresBaralho.textoSecundario)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O mural não fica guardado: cada um escolhe as fotos que quer e salva no
/// próprio celular antes de a sala fechar.
class MuralParaSalvar extends StatefulWidget {
  const MuralParaSalvar({super.key, required this.visao, required this.acoes});

  final VisaoDaSala visao;
  final AcoesDaSala acoes;

  @override
  State<MuralParaSalvar> createState() => _MuralParaSalvarState();
}

class _MuralParaSalvarState extends State<MuralParaSalvar> {
  final _escolhidas = <String>{};
  var _salvando = false;

  // Fotos já baixadas ao abrir a tela. O Safari só abre o "Salvar imagem"
  // logo depois do toque: se o app ainda fosse buscar as fotos, ele recusaria.
  final _baixadas = <String, Future<Uint8List?>>{};

  List<Momento> get _momentos => widget.visao.momentos;

  @override
  void initState() {
    super.initState();
    _adiantarDownloads();
  }

  @override
  void didUpdateWidget(MuralParaSalvar antigo) {
    super.didUpdateWidget(antigo);
    _adiantarDownloads();
  }

  void _adiantarDownloads() {
    for (final momento in _momentos) {
      _baixadas.putIfAbsent(
          momento.id, () => widget.acoes.baixarFoto(momento.foto).then<Uint8List?>((b) => b, onError: (_) => null));
    }
  }

  void _alternar(Momento momento) => setState(() {
        if (!_escolhidas.remove(momento.id)) _escolhidas.add(momento.id);
      });

  Future<void> _salvar() async {
    final fotos = _escolhidas.isEmpty ? _momentos : _momentos.where((m) => _escolhidas.contains(m.id)).toList();
    setState(() => _salvando = true);
    try {
      final arquivos = <({Uint8List bytes, String nome})>[];
      for (final (posicao, momento) in fotos.indexed) {
        // A que falhou ao abrir a tela é buscada de novo agora.
        final bytes = await _baixadas[momento.id] ?? await widget.acoes.baixarFoto(momento.foto);
        _baixadas[momento.id] = Future.value(bytes);
        arquivos.add((bytes: bytes, nome: 'baralho-da-resenha-${_semAcento(momento.nome)}-${posicao + 1}.jpg'));
      }
      await compartilharFotos(arquivos);
    } on Object catch (erro) {
      if (mounted) avisar(context, erro is StateError ? 'Não deu para salvar. Tente de novo.' : erro);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  static String _semAcento(String nome) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final letra in nome.toLowerCase().split('')) {
      final posicao = de.indexOf(letra);
      buffer.write(posicao >= 0 ? para[posicao] : letra);
    }
    return buffer.toString().replaceAll(RegExp('[^a-z0-9]+'), '-');
  }

  @override
  Widget build(BuildContext context) {
    final minhas = _momentos.where((m) => m.jogadorId == widget.visao.euId).map((m) => m.id).toSet();
    final quantas = _escolhidas.isEmpty ? _momentos.length : _escolhidas.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'As fotos somem quando a sala fechar. Escolha as que quiser e salve no seu celular.',
          style: TextStyle(color: CoresBaralho.textoSecundario),
        ),
        const SizedBox(height: EspacoBaralho.medio),
        Wrap(
          spacing: EspacoBaralho.pequeno,
          children: [
            if (minhas.isNotEmpty)
              ActionChip(
                label: const Text('Só as minhas'),
                onPressed: () => setState(() => _escolhidas
                  ..clear()
                  ..addAll(minhas)),
              ),
            if (_escolhidas.isNotEmpty)
              ActionChip(label: const Text('Limpar escolha'), onPressed: () => setState(_escolhidas.clear)),
          ],
        ),
        const SizedBox(height: EspacoBaralho.pequeno),
        LayoutBuilder(
          builder: (context, limites) {
            final lado = (limites.maxWidth - EspacoBaralho.medio) / 2;
            return Wrap(
              spacing: EspacoBaralho.medio,
              runSpacing: EspacoBaralho.base,
              children: [
                for (final momento in _momentos)
                  _FotoParaEscolher(
                    momento: momento,
                    lado: lado,
                    escolhida: _escolhidas.contains(momento.id),
                    aoTocar: () => _alternar(momento),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: EspacoBaralho.base),
        const Text('Toque para escolher · segure para ver grande',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: CoresBaralho.textoApagado)),
        const SizedBox(height: EspacoBaralho.medio),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_rounded),
          label: Text(_escolhidas.isEmpty
              ? 'Salvar todas no celular ($quantas)'
              : 'Salvar ${quantas == 1 ? 'a escolhida' : 'as $quantas escolhidas'}'),
        ),
      ],
    );
  }
}

class _FotoParaEscolher extends StatelessWidget {
  const _FotoParaEscolher({
    required this.momento,
    required this.lado,
    required this.escolhida,
    required this.aoTocar,
  });

  final Momento momento;
  final double lado;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('mural-${momento.id}'),
      onTap: aoTocar,
      onLongPress: () => abrirMomento(context, momento),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: escolhida ? CoresBaralho.ambar : Colors.transparent, width: 3),
            ),
            child: IgnorePointer(child: FotoDoMomento(momento: momento, lado: lado - 6, comLegenda: true)),
          ),
          if (escolhida)
            const Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: CoresBaralho.ambar,
                child: Icon(Icons.check_rounded, size: 18, color: CoresBaralho.fundo),
              ),
            ),
        ],
      ),
    );
  }
}
