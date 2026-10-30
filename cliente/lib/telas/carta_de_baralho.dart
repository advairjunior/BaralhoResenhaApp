import 'dart:math';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'visual.dart';

/// Proporção de carta de baralho de verdade (63 × 88 mm).
const proporcaoDaCarta = 63 / 88;

/// Tinta da carta: o texto é sempre escuro sobre papel claro, como carta impressa,
/// mesmo com o app escuro.
const _tinta = Color(0xFF241812);

/// O desenho que cobre o papel de cada jogo. É o que faz uma carta de Chuta aí
/// (um alvo) não parecer uma de Eu Nunca (bolinhas), mesmo de longe.
enum _Estampa { bolinhas, listras, xadrez, ondas, zigueZague, alvo, pautado, envelope, alerta, dividido, bolhas, confete, simbolo }

/// O visual de cada jogo: a cor do naipe (faixa do topo e estampa), o papel e o desenho do papel.
class _TemaDaCarta {
  const _TemaDaCarta({
    required this.cor,
    required this.papel,
    required this.estampa,
    this.simbolo,
    this.corDoTitulo = Colors.white,
  });

  final Color cor;
  final Color papel;
  final _Estampa estampa;

  /// Na estampa de símbolo: o que se repete no papel (?, ♪, ★…).
  final String? simbolo;

  /// Texto da faixa do topo: branco, menos na regra-relâmpago (amarelo no preto).
  final Color corDoTitulo;

  /// Tom mais escuro do naipe, para o degradê da faixa e os selos.
  Color get escura => Color.lerp(cor, Colors.black, 0.28)!;
}

_TemaDaCarta _temaDo(ModoDeJogo modo) => switch (modo) {
      ModoDeJogo.euNunca =>
        const _TemaDaCarta(cor: Color(0xFF7C3AED), papel: Color(0xFFF6F0FF), estampa: _Estampa.bolinhas),
      ModoDeJogo.maisProvavel =>
        const _TemaDaCarta(cor: Color(0xFF2563EB), papel: Color(0xFFEFF5FF), estampa: _Estampa.listras),
      ModoDeJogo.bebaSe =>
        const _TemaDaCarta(cor: Color(0xFFD97706), papel: Color(0xFFFFF7E6), estampa: _Estampa.bolhas),
      ModoDeJogo.regraRelampago => const _TemaDaCarta(
          cor: Color(0xFF1C1A16),
          papel: Color(0xFFFFE45C),
          estampa: _Estampa.zigueZague,
          corDoTitulo: Color(0xFFFFE45C),
        ),
      ModoDeJogo.tribunal =>
        const _TemaDaCarta(cor: Color(0xFF0F766E), papel: Color(0xFFEDFAF7), estampa: _Estampa.xadrez),
      ModoDeJogo.elogios =>
        const _TemaDaCarta(cor: Color(0xFFE11D48), papel: Color(0xFFFFF1F3), estampa: _Estampa.simbolo, simbolo: '♥'),
      ModoDeJogo.correio =>
        const _TemaDaCarta(cor: Color(0xFFE4572E), papel: Color(0xFFFFF6EF), estampa: _Estampa.envelope),
      ModoDeJogo.imagemEAcao =>
        const _TemaDaCarta(cor: Color(0xFF16A34A), papel: Color(0xFFEEFBF3), estampa: _Estampa.confete),
      ModoDeJogo.jurados =>
        const _TemaDaCarta(cor: Color(0xFFC026D3), papel: Color(0xFFFDF2FF), estampa: _Estampa.simbolo, simbolo: '★'),
      ModoDeJogo.musica =>
        const _TemaDaCarta(cor: Color(0xFF0284C7), papel: Color(0xFFEFF9FF), estampa: _Estampa.simbolo, simbolo: '♪'),
      ModoDeJogo.impostor =>
        const _TemaDaCarta(cor: Color(0xFF334155), papel: Color(0xFFF1F5F9), estampa: _Estampa.ondas),
      ModoDeJogo.termineAFrase =>
        const _TemaDaCarta(cor: Color(0xFF65A30D), papel: Color(0xFFF8FDEE), estampa: _Estampa.pautado),
      ModoDeJogo.duasVerdades =>
        const _TemaDaCarta(cor: Color(0xFFEA580C), papel: Color(0xFFFFF5ED), estampa: _Estampa.zigueZague),
      ModoDeJogo.chutaAi =>
        const _TemaDaCarta(cor: Color(0xFF4338CA), papel: Color(0xFFF0F1FF), estampa: _Estampa.alvo),
      ModoDeJogo.batataQuente =>
        const _TemaDaCarta(cor: Color(0xFF92400E), papel: Color(0xFFFFF4E5), estampa: _Estampa.bolinhas),
      ModoDeJogo.issoOuAquilo =>
        const _TemaDaCarta(cor: Color(0xFFDB2777), papel: Color(0xFFFFF0F7), estampa: _Estampa.dividido),
      ModoDeJogo.quemSouEu =>
        const _TemaDaCarta(cor: Color(0xFF0891B2), papel: Color(0xFFECFEFF), estampa: _Estampa.simbolo, simbolo: '?'),
      ModoDeJogo.palavraProibida =>
        const _TemaDaCarta(cor: Color(0xFFB91C1C), papel: Color(0xFFFFF5F5), estampa: _Estampa.alerta),
      ModoDeJogo.quemEscreveu =>
        const _TemaDaCarta(cor: Color(0xFF1E3A8A), papel: Color(0xFFF2F5FF), estampa: _Estampa.simbolo, simbolo: '“'),
    };

/// O selo do nível no rodapé: do verde tranquilo ao preto em brasa.
Color _corDoNivel(NivelDaCarta nivel) => switch (nivel) {
      NivelDaCarta.leve => const Color(0xFF16A34A),
      NivelDaCarta.resenha => const Color(0xFFD97706),
      NivelDaCarta.picante => const Color(0xFFDC2626),
      NivelDaCarta.original => const Color(0xFF1A0A06),
    };

/// O que vai em cima do título: o jeito de jogar esta carta.
String? _jeitoDaCarta(Rodada rodada) => switch (rodada) {
      Rodada(jokenpo: true) => '✊✋✌️ PEDRA, PAPEL E TESOURA',
      Rodada(duelo: true) => '⚔️ DUELO · A TURMA VOTA',
      Rodada(:final goles?) => '🍺 DOSE DE VERDADE · BEBE $goles',
      Rodada(contaEssa: true) => '🎤 CONTA ESSA · QUEM JÁ FEZ CONTA',
      Rodada(modo: ModoDeJogo.imagemEAcao, :final dica?) => '🎭 ${dica.toUpperCase()}',
      Rodada(elogio: true, modo: ModoDeJogo.tribunal) => '💛 ELOGIO · A TURMA DECIDE',
      Rodada(elogio: true) => '💛 ELOGIO · VOTAÇÃO NO CELULAR',
      Rodada(modo: ModoDeJogo.maisProvavel, votacao: true) => '🗳️ VOTAÇÃO NO CELULAR',
      Rodada(modo: ModoDeJogo.maisProvavel) => '👉 TODO MUNDO APONTA NO 3',
      Rodada(modo: ModoDeJogo.tribunal) => '👍 SIM OU 👎 NÃO, EM SEGREDO',
      Rodada(modo: ModoDeJogo.elogios) => 'NINGUÉM BEBE, TODO MUNDO SE ACHA',
      Rodada(modo: ModoDeJogo.correio) => '📮 BILHETE ANÔNIMO',
      Rodada(modo: ModoDeJogo.jurados) => '⭐ NOTA DE 1 A 5, EM SEGREDO',
      Rodada(modo: ModoDeJogo.musica) => '🎵 CADA UM CANTA NA SUA VEZ',
      Rodada(modo: ModoDeJogo.impostor) => '🕵️ TEM UM IMPOSTOR NA MESA',
      Rodada(modo: ModoDeJogo.issoOuAquilo) => '🤷 A MINORIA LEVA',
      Rodada(modo: ModoDeJogo.quemSouEu, :final dica?) => '🙈 ${dica.toUpperCase()} · SÓ SIM OU NÃO',
      Rodada(modo: ModoDeJogo.palavraProibida) => '🚫 EXPLIQUE SEM DIZER AS PROIBIDAS',
      Rodada(modo: ModoDeJogo.quemEscreveu) => '🖊️ RESPOSTA SECRETA · ADIVINHE O AUTOR',
      _ => null,
    };

/// Quanto mais apimentada, mais "quente" a borda: o Leve é só papel, o
/// Original ganha borda em brasa.
Gradient? _calorDo(NivelDaCarta nivel) => switch (nivel) {
      NivelDaCarta.picante => const LinearGradient(colors: [Color(0xFFFF6B3D), Color(0xFFE5243B)]),
      NivelDaCarta.original =>
        const LinearGradient(colors: [Color(0xFF1A0A06), Color(0xFFE5243B), Color(0xFF1A0A06)]),
      _ => null,
    };

/// A carta da rodada, dada com a virada do baralho: começa de costas e vira.
class CartaQueVira extends StatefulWidget {
  const CartaQueVira({super.key, required this.rodada});

  final Rodada rodada;

  @override
  State<CartaQueVira> createState() => _CartaQueViraState();
}

class _CartaQueViraState extends State<CartaQueVira> with SingleTickerProviderStateMixin {
  late final _virada = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_virada.isAnimating || _virada.isCompleted) return;
    // Quem pediu menos movimento recebe a carta já virada.
    if (MediaQuery.of(context).disableAnimations) {
      _virada.value = 1;
    } else {
      _virada.forward();
    }
  }

  @override
  void dispose() {
    _virada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: AspectRatio(
          aspectRatio: proporcaoDaCarta,
          child: AnimatedBuilder(
            animation: _virada,
            builder: (context, _) {
              final angulo = pi * (1 - Curves.easeOutBack.transform(_virada.value).clamp(0.0, 1.0));
              final deCostas = angulo > pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angulo),
                child: deCostas
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: const CostasDaCarta(),
                      )
                    : FrenteDaCarta(rodada: widget.rodada),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FrenteDaCarta extends StatelessWidget {
  const FrenteDaCarta({super.key, required this.rodada});

  final Rodada rodada;

  double get _tamanhoDoTexto {
    final letras = rodada.texto.length;
    if (letras > 120) return 21;
    if (letras > 80) return 24;
    if (letras > 50) return 27;
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    final tema = _temaDo(rodada.modo);
    final calor = _calorDo(rodada.nivel);
    final jeito = _jeitoDaCarta(rodada);
    // No duelo e no pedra, papel e tesoura, o selo é o próprio jogo: vai para a faixa.
    final titulo = rodada.jokenpo || rodada.duelo ? jeito! : '${rodada.modo.emoji}  ${rodada.modo.titulo}';
    final selo = rodada.jokenpo || rodada.duelo ? null : jeito;
    return Container(
      key: const Key('frente-da-carta'),
      padding: EdgeInsets.all(calor == null ? 0 : 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: calor,
        color: calor == null ? tema.papel : null,
        boxShadow: [
          BoxShadow(
            color: (calor == null ? tema.cor : const Color(0xFFE5243B)).withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(calor == null ? 22 : 18),
        child: ColoredBox(
          color: tema.papel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Faixa(tema: tema, titulo: titulo),
              Expanded(
                child: CustomPaint(
                  painter: _PintorDaEstampa(tema),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                    child: Column(
                      children: [
                        if (selo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tema.papel,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: tema.cor.withValues(alpha: 0.55)),
                            ),
                            child: Text(
                              selo,
                              key: const Key('jeito-de-votar'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: tema.escura),
                            ),
                          ),
                        Expanded(
                          child: Center(
                            child: Text(
                              rodada.texto,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _tamanhoDoTexto,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: _tinta,
                              ),
                            ),
                          ),
                        ),
                        if (rodada.modo == ModoDeJogo.regraRelampago)
                          Padding(
                            padding: const EdgeInsets.only(bottom: EspacoBaralho.pequeno),
                            // Quantas vezes faltam aparece na caixa da regra, embaixo.
                            child: Text(rodada.vezDaRegra ? 'A regra continua valendo' : 'Vale pelas próximas cartas',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _tinta)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _Rodape(tema: tema, nivel: rodada.nivel),
            ],
          ),
        ),
      ),
    );
  }
}

/// A faixa do topo, na cor do jogo: o emoji e o nome, grandes, para reconhecer o
/// jogo do outro lado da mesa.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.tema, required this.titulo});

  final _TemaDaCarta tema;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tema.cor, tema.escura],
        ),
      ),
      child: Text(
        titulo.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          height: 1.2,
          color: tema.corDoTitulo,
          shadows: const [Shadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
      ),
    );
  }
}

/// O rodapé: o selo do nível, cheio, na cor do calor da carta.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.tema, required this.nivel});

  final _TemaDaCarta tema;
  final NivelDaCarta nivel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: _corDoNivel(nivel), borderRadius: BorderRadius.circular(999)),
          child: Text(
            '${nivel.emoji} ${nivel.titulo.toUpperCase()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Desenha a estampa do jogo no papel, bem clarinha, para o texto continuar
/// fácil de ler.
class _PintorDaEstampa extends CustomPainter {
  _PintorDaEstampa(this.tema);

  final _TemaDaCarta tema;

  @override
  void paint(Canvas canvas, Size tamanho) {
    final regra = tema.estampa == _Estampa.zigueZague && tema.cor == const Color(0xFF1C1A16);
    final tinta = Paint()
      ..color = tema.cor.withValues(alpha: regra ? 0.12 : 0.09)
      ..style = PaintingStyle.fill;
    final traco = Paint()
      ..color = tema.cor.withValues(alpha: regra ? 0.14 : 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final w = tamanho.width;
    final h = tamanho.height;
    switch (tema.estampa) {
      case _Estampa.bolinhas:
        for (var y = 10.0, linha = 0; y < h; y += 26, linha++) {
          for (var x = linha.isEven ? 10.0 : 23.0; x < w; x += 26) {
            canvas.drawCircle(Offset(x, y), 5, tinta);
          }
        }
      case _Estampa.listras:
        traco.strokeWidth = 7;
        for (var x = -h; x < w; x += 24) {
          canvas.drawLine(Offset(x, h), Offset(x + h, 0), traco);
        }
      case _Estampa.xadrez:
        for (var y = 0.0, linha = 0; y < h; y += 22, linha++) {
          for (var x = linha.isEven ? 0.0 : 22.0; x < w; x += 44) {
            canvas.drawRect(Rect.fromLTWH(x, y, 22, 22), tinta);
          }
        }
      case _Estampa.ondas:
        for (var y = 14.0; y < h; y += 26) {
          final onda = Path()..moveTo(0, y);
          for (var x = 0.0; x < w; x += 28) {
            onda.quadraticBezierTo(x + 7, y - 8, x + 14, y);
            onda.quadraticBezierTo(x + 21, y + 8, x + 28, y);
          }
          canvas.drawPath(onda, traco);
        }
      case _Estampa.zigueZague:
        traco.strokeWidth = 3;
        for (var y = 14.0; y < h; y += 24) {
          final raio = Path()..moveTo(0, y);
          for (var x = 0.0; x < w; x += 20) {
            raio.lineTo(x + 10, y - 8);
            raio.lineTo(x + 20, y);
          }
          canvas.drawPath(raio, traco);
        }
      case _Estampa.alvo:
        final centro = Offset(w / 2, h / 2);
        traco.strokeWidth = 10;
        for (var r = 26.0; r < max(w, h); r += 30) {
          canvas.drawCircle(centro, r, traco);
        }
      case _Estampa.pautado:
        traco.strokeWidth = 1.5;
        for (var y = 24.0; y < h; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(w, y), traco);
        }
        canvas.drawLine(const Offset(28, 0), Offset(28, h),
            Paint()
              ..color = const Color(0xFFE11D48).withValues(alpha: 0.18)
              ..strokeWidth = 2);
      case _Estampa.envelope:
        // A borda listrada de carta por avião: vermelho e azul.
        const faixa = 9.0;
        final azul = Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.22);
        final vermelho = Paint()..color = tema.cor.withValues(alpha: 0.26);
        var i = 0;
        for (var x = -20.0; x < w + 20; x += 18, i++) {
          final pincel = i.isEven ? vermelho : azul;
          canvas.drawPath(
              Path()
                ..moveTo(x, 0)
                ..lineTo(x + 9, 0)
                ..lineTo(x + 9 - faixa, faixa)
                ..lineTo(x - faixa, faixa)
                ..close(),
              pincel);
          canvas.drawPath(
              Path()
                ..moveTo(x, h)
                ..lineTo(x + 9, h)
                ..lineTo(x + 9 + faixa, h - faixa)
                ..lineTo(x + faixa, h - faixa)
                ..close(),
              pincel);
        }
      case _Estampa.alerta:
        traco
          ..strokeWidth = 12
          ..color = tema.cor.withValues(alpha: 0.08);
        for (var x = -h; x < w; x += 34) {
          canvas.drawLine(Offset(x, 0), Offset(x + h, h), traco);
        }
      case _Estampa.dividido:
        canvas.drawPath(
            Path()
              ..moveTo(0, 0)
              ..lineTo(w, 0)
              ..lineTo(0, h)
              ..close(),
            Paint()..color = tema.cor.withValues(alpha: 0.10));
        canvas.drawPath(
            Path()
              ..moveTo(w, 0)
              ..lineTo(w, h)
              ..lineTo(0, h)
              ..close(),
            Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.08));
      case _Estampa.bolhas:
        final sorte = Random(7);
        for (var i = 0; i < 26; i++) {
          canvas.drawCircle(Offset(sorte.nextDouble() * w, sorte.nextDouble() * h), 4 + sorte.nextDouble() * 12,
              traco..strokeWidth = 2);
        }
      case _Estampa.confete:
        final sorte = Random(3);
        const cores = [Color(0xFF16A34A), Color(0xFFF59E0B), Color(0xFF2563EB), Color(0xFFE11D48)];
        for (var i = 0; i < 46; i++) {
          canvas.save();
          canvas.translate(sorte.nextDouble() * w, sorte.nextDouble() * h);
          canvas.rotate(sorte.nextDouble() * pi);
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2, 10, 4), const Radius.circular(2)),
              Paint()..color = cores[i % cores.length].withValues(alpha: 0.18));
          canvas.restore();
        }
      case _Estampa.simbolo:
        final pincel = TextPainter(
          text: TextSpan(
            text: tema.simbolo ?? '•',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: tema.cor.withValues(alpha: 0.11)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        for (var y = 0.0, linha = 0; y < h; y += 44, linha++) {
          for (var x = linha.isEven ? 6.0 : 30.0; x < w; x += 48) {
            pincel.paint(canvas, Offset(x, y));
          }
        }
    }
  }

  @override
  bool shouldRepaint(_PintorDaEstampa antigo) => antigo.tema != tema;
}

/// As costas, iguais para todas as cartas: ninguém adivinha o que vem.
class CostasDaCarta extends StatelessWidget {
  const CostasDaCarta({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF2A1A0E),
        border: Border.all(color: CoresBaralho.ambar, width: 3),
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CoresBaralho.ambar.withValues(alpha: 0.5)),
          gradient: const RadialGradient(colors: [Color(0xFF5A3510), Color(0xFF2A1A0E)]),
        ),
        child: CustomPaint(
          painter: _PintorDasCostas(),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A0E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CoresBaralho.ambar, width: 2),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🃏', style: TextStyle(fontSize: 64)),
                  SizedBox(height: EspacoBaralho.pequeno),
                  Text('Baralho da\nResenha',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CoresBaralho.ambar, height: 1.1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A trama de losangos das costas, como nos baralhos de verdade.
class _PintorDasCostas extends CustomPainter {
  @override
  void paint(Canvas canvas, Size tamanho) {
    final linha = Paint()
      ..color = CoresBaralho.ambar.withValues(alpha: 0.16)
      ..strokeWidth = 1.5;
    final diagonal = tamanho.width + tamanho.height;
    for (var x = -tamanho.height; x < diagonal; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x + tamanho.height, tamanho.height), linha);
      canvas.drawLine(Offset(x, tamanho.height), Offset(x + tamanho.height, 0), linha);
    }
  }

  @override
  bool shouldRepaint(_PintorDasCostas antigo) => false;
}
