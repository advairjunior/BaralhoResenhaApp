import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/tema_baralho.dart';
import 'sala.dart';
import 'selfie.dart';

/// Quem a carta pegou: bebeu, conta a história ou é do casal já julgado.
/// Espelha a regra do servidor para mostrar o botão só a quem pode usar.
Set<String> protagonistasDa(Rodada rodada) => {
      ...?rodada.revelacao?.perderam,
      ...?rodada.revelacao?.escolhidos,
      if (rodada.modo == ModoDeJogo.tribunal && rodada.revelacao != null)
        if (rodada.alvo case final reu?) reu,
      if (rodada.revelacao?.contaAHistoria case final historia?) historia,
      if (rodada.modo == ModoDeJogo.casaisEmJogo && rodada.acertou != null) ...[
        if (rodada.palpiteiro case final palpiteiro?) palpiteiro,
        if (rodada.alvo case final alvo?) alvo,
      ],
    };

/// Tema da selfie de reação, de acordo com o que aconteceu na carta.
String temaDaReacao(Rodada rodada, String euId) {
  final revelacao = rodada.revelacao;
  return switch (rodada.modo) {
    ModoDeJogo.euNunca when revelacao?.contaAHistoria == euId => 'Cara de quem vai contar essa história 🎤',
    ModoDeJogo.euNunca => 'Cara de quem foi pego no "já fiz" 🙈',
    _ when revelacao?.elogio ?? false => 'Cara de xodó da turma 💛',
    ModoDeJogo.maisProvavel => 'Cara de quem foi escolhido pela turma 👉',
    ModoDeJogo.tribunal when revelacao?.escolhidos.isNotEmpty ?? false => 'Cara de quem foi condenado(a) pela turma 🔨',
    ModoDeJogo.tribunal => 'Cara de quem foi absolvido(a) 😇',
    ModoDeJogo.casaisEmJogo when rodada.acertou == true => 'Cara de casal em sintonia 💞',
    ModoDeJogo.casaisEmJogo => 'Cara de quem errou sobre o próprio par 😬',
    _ => 'Cara de quem foi pego 🍺',
  };
}

/// Na revelação: o botão da selfie de reação para quem foi pego e as fotos
/// que já foram para o mural nesta carta.
class MomentosDaRodada extends StatelessWidget {
  const MomentosDaRodada({super.key, required this.visao, required this.rodada, required this.acoes});

  final VisaoDaSala visao;
  final Rodada rodada;
  final AcoesDaSala acoes;

  @override
  Widget build(BuildContext context) {
    final daRodada = visao.momentos.where((m) => m.rodada == rodada.numero).toList();
    final souProtagonista = protagonistasDa(rodada).contains(visao.euId);
    if (daRodada.isEmpty && !souProtagonista) return const SizedBox.shrink();
    final jaTirei = daRodada.any((m) => m.jogadorId == visao.euId);

    return Padding(
      padding: const EdgeInsets.only(top: EspacoBaralho.grande),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (souProtagonista)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: CoresBaralho.ambar,
                side: const BorderSide(color: CoresBaralho.ambar),
              ),
              onPressed: () async {
                final foto = await tirarSelfie(context,
                    tema: temaDaReacao(rodada, visao.euId), titulo: 'Selfie pro mural!');
                if (foto != null) await acoes.registrarMomento(foto);
              },
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(jaTirei ? 'Tirar outra selfie pro mural' : 'Selfie de reação pro mural 📸'),
            ),
          if (daRodada.isNotEmpty) ...[
            const SizedBox(height: EspacoBaralho.medio),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: EspacoBaralho.pequeno,
              runSpacing: EspacoBaralho.pequeno,
              children: [for (final momento in daRodada) FotoDoMomento(momento: momento, lado: 88)],
            ),
          ],
        ],
      ),
    );
  }
}

/// Foto do mural com o nome por cima; tocar abre grande.
class FotoDoMomento extends StatelessWidget {
  const FotoDoMomento({super.key, required this.momento, this.lado = 120, this.comLegenda = false});

  final Momento momento;
  final double lado;
  final bool comLegenda;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => abrirMomento(context, momento),
      child: SizedBox(
        width: lado,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(children: [
                ImagemDoMomento(momento: momento, lado: lado),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Text(momento.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
            if (comLegenda)
              Padding(
                padding: const EdgeInsets.only(top: EspacoBaralho.mini),
                child: Text(momento.texto, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.3, color: CoresBaralho.textoSecundario)),
              ),
          ],
        ),
      ),
    );
  }
}

class ImagemDoMomento extends StatelessWidget {
  const ImagemDoMomento({super.key, required this.momento, required this.lado});

  final Momento momento;
  final double lado;

  @override
  Widget build(BuildContext context) => Image.network(
        momento.foto,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: lado,
          height: lado,
          color: CoresBaralho.superficieElevada,
          alignment: Alignment.center,
          child: const Text('📸', style: TextStyle(fontSize: 28)),
        ),
      );
}

Future<void> abrirMomento(BuildContext context, Momento momento) => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, limites) => ImagemDoMomento(momento: momento, lado: limites.maxWidth),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EspacoBaralho.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(momento.nome, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: EspacoBaralho.mini),
                  Text(momento.texto, style: const TextStyle(color: CoresBaralho.textoSecundario)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
