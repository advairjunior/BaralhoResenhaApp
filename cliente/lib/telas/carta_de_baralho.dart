import 'dart:math';

import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'visual.dart';

/// Proporção de carta de baralho de verdade (63 × 88 mm).
const proporcaoDaCarta = 63 / 88;

/// Papel e tinta da carta: sempre claros, como carta impressa, mesmo com o
/// app escuro.
const _papel = Color(0xFFFFF8EE);
const _tinta = Color(0xFF241812);

/// O visual de cada jogo: a cor da moldura (o "naipe"), a cor do papel e o
/// emoji que se repete nos cantos e no fundo.
class _TemaDaCarta {
  const _TemaDaCarta({required this.moldura, required this.papel, required this.titulo});

  final Color moldura;
  final Color papel;
  final Color titulo;
}

_TemaDaCarta _temaDo(ModoDeJogo modo) => switch (modo) {
      ModoDeJogo.euNunca =>
        const _TemaDaCarta(moldura: Color(0xFF7446E8), papel: Color(0xFFF7F1FF), titulo: Color(0xFF5A2FC9)),
      ModoDeJogo.maisProvavel =>
        const _TemaDaCarta(moldura: Color(0xFF2F74E0), papel: Color(0xFFEFF5FF), titulo: Color(0xFF1F57B0)),
      ModoDeJogo.bebaSe =>
        const _TemaDaCarta(moldura: Color(0xFFE88A00), papel: _papel, titulo: Color(0xFFA85F00)),
      ModoDeJogo.regraRelampago =>
        const _TemaDaCarta(moldura: Color(0xFF1C1A16), papel: Color(0xFFFFE45C), titulo: Color(0xFF1C1A16)),
      ModoDeJogo.casaisEmJogo =>
        const _TemaDaCarta(moldura: Color(0xFFD9327C), papel: Color(0xFFFFF0F6), titulo: Color(0xFFB21E61)),
      ModoDeJogo.tribunal =>
        const _TemaDaCarta(moldura: Color(0xFF0E8C7E), papel: Color(0xFFEDFAF7), titulo: Color(0xFF0A6B60)),
      ModoDeJogo.elogios =>
        const _TemaDaCarta(moldura: Color(0xFFE0A100), papel: Color(0xFFFFFAE8), titulo: Color(0xFF9A6A00)),
      ModoDeJogo.correio =>
        const _TemaDaCarta(moldura: Color(0xFFD9452A), papel: Color(0xFFFFF3EC), titulo: Color(0xFFA8321C)),
      ModoDeJogo.imagemEAcao =>
        const _TemaDaCarta(moldura: Color(0xFF1B8A5A), papel: Color(0xFFEEFBF4), titulo: Color(0xFF13693F)),
    };

/// O que vai em cima do título: o jeito de jogar esta carta.
String? _jeitoDaCarta(Rodada rodada) => switch (rodada) {
      Rodada(duelo: true) => '⚔️ DUELO · A TURMA VOTA',
      Rodada(modo: ModoDeJogo.imagemEAcao, :final dica?) => '🎭 ${dica.toUpperCase()}',
      Rodada(elogio: true, modo: ModoDeJogo.tribunal) => '💛 ELOGIO · A TURMA DECIDE',
      Rodada(elogio: true) => '💛 ELOGIO · VOTAÇÃO NO CELULAR',
      Rodada(modo: ModoDeJogo.maisProvavel, votacao: true) => '🗳️ VOTAÇÃO NO CELULAR',
      Rodada(modo: ModoDeJogo.maisProvavel) => '👉 TODO MUNDO APONTA NO 3',
      Rodada(modo: ModoDeJogo.tribunal) => '👍 SIM OU 👎 NÃO, EM SEGREDO',
      Rodada(modo: ModoDeJogo.elogios) => 'NINGUÉM BEBE, TODO MUNDO SE ACHA',
      Rodada(modo: ModoDeJogo.correio) => '📮 BILHETE ANÔNIMO',
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
    final cantos = '${rodada.modo.emoji}\n${rodada.nivel.emoji}';
    return Container(
      key: const Key('frente-da-carta'),
      padding: EdgeInsets.all(calor == null ? 0 : 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: calor,
        color: calor == null ? tema.papel : null,
        boxShadow: [
          BoxShadow(
            color: (calor == null ? tema.moldura : const Color(0xFFE5243B)).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(color: tema.papel, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tema.moldura, width: 2.5),
          ),
          child: Stack(
            children: [
              // O "naipe" grande e apagado ao fundo.
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.08,
                    child: Text(rodada.modo.emoji, style: const TextStyle(fontSize: 190)),
                  ),
                ),
              ),
              Positioned(top: 8, left: 10, child: _Canto(texto: cantos)),
              Positioned(
                bottom: 8,
                right: 10,
                child: Transform.rotate(angle: pi, child: _Canto(texto: cantos)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(44, 16, 44, 16),
                child: Column(
                  children: [
                    if (_jeitoDaCarta(rodada) case final jeito?)
                      Text(
                        jeito,
                        key: const Key('jeito-de-votar'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: tema.titulo),
                      ),
                    Text(
                      rodada.modo.titulo.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: tema.titulo,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          rodada.texto,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _tamanhoDoTexto,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: _tinta,
                          ),
                        ),
                      ),
                    ),
                    if (rodada.modo == ModoDeJogo.regraRelampago)
                      const Padding(
                        padding: EdgeInsets.only(bottom: EspacoBaralho.pequeno),
                        child: Text('Vale pelas próximas 3 cartas',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tinta)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: tema.moldura.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${rodada.nivel.emoji} ${rodada.nivel.titulo}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tema.titulo),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Índice do canto, como num baralho: o naipe (jogo) em cima do nível.
class _Canto extends StatelessWidget {
  const _Canto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.15));
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
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🃏', style: TextStyle(fontSize: 72)),
              SizedBox(height: EspacoBaralho.pequeno),
              Text('Baralho da\nResenha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CoresBaralho.ambar, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}
