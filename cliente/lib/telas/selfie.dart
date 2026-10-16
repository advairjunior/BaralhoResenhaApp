import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../dominio/recorte_da_selfie.dart';
import '../infraestrutura/camera_do_app.dart';
import '../infraestrutura/reduzir_selfie.dart';
import '../tema/tema_baralho.dart';
import 'camera_do_cartao.dart';
import 'visual.dart';

/// Tema da careta: a selfie já nasce engraçada.
const caretas = [
  'Cara de quem dormiu no sofá 🛋️',
  'Cara de quem foi pego no flagra 😳',
  'Cara de quem viu a fatura do cartão 💳',
  'Cara de quem vai contar um segredo 🤫',
  'Cara de quem já tá alegrinho 🥴',
  'Cara de quem esqueceu o aniversário de casamento 😬',
  'Sua melhor cara de galã 😎',
  'Cara de quem ouviu a sogra chegando 👀',
  'Cara de quem comeu o último pedaço escondido 🍕',
  'Cara de quem mandou áudio de 5 minutos 🎙️',
];

/// Gerador do sorteio da careta; os testes fixam um.
Random sorteioDaCareta = Random();

/// Abre a câmera do app já na selfie. Se ela não abrir, cai na câmera do
/// celular. Devolve a foto pronta para enviar ou nulo se a pessoa desistiu.
Future<Uint8List?> tirarSelfie(BuildContext context, {String? tema, String titulo = 'Hora da selfie!'}) async {
  final careta = tema ?? caretas[sorteioDaCareta.nextInt(caretas.length)];
  final resposta = await Navigator.push<RespostaDaCamera>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraDoCartao(
        camera: fabricaDeCamera(),
        lenteInicial: LenteDaCamera.frontal,
        cartao: (context, fundo) => MolduraDaSelfie(fundo: fundo, careta: careta, titulo: titulo),
      ),
    ),
  );
  if (resposta == null || !context.mounted) return null;

  Uint8List foto;
  var comMoldura = true;
  if (resposta.usarCameraDoSistema) {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (arquivo == null) return null;
    foto = await arquivo.readAsBytes();
    comMoldura = false;
  } else {
    foto = resposta.foto!;
  }

  try {
    return await reduzirSelfie(foto, comMoldura: comMoldura);
  } catch (_) {
    if (context.mounted) avisar(context, 'Não deu para preparar a foto. Tente de novo.');
    return null;
  }
}

/// O quadro da câmera: escurece tudo fora do círculo, que é exatamente o
/// pedaço que vira a selfie.
class MolduraDaSelfie extends StatelessWidget {
  const MolduraDaSelfie({super.key, required this.fundo, required this.careta, this.titulo = 'Hora da selfie!'});

  final Widget fundo;
  final String careta;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final diametro = limites.maxWidth * diametroDaMoldura;
        final centro = Offset(limites.maxWidth * centroXDaMoldura, limites.maxHeight * centroYDaMoldura);
        return Stack(
          fit: StackFit.expand,
          children: [
            fundo,
            CustomPaint(painter: _Furo(centro: centro, raio: diametro / 2)),
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            Positioned(
              top: centro.dy + diametro / 2 + 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  const Text('Tema da careta:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    careta,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: CoresBaralho.ambar, fontSize: 19, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Furo extends CustomPainter {
  const _Furo({required this.centro, required this.raio});

  final Offset centro;
  final double raio;

  @override
  void paint(Canvas canvas, Size tamanho) {
    final circulo = Path()..addOval(Rect.fromCircle(center: centro, radius: raio));
    final sombra = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & tamanho), circulo);
    canvas.drawPath(sombra, Paint()..color = Colors.black.withValues(alpha: 0.62));
    canvas.drawPath(
      circulo,
      Paint()
        ..color = CoresBaralho.ambar
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Furo antigo) => antigo.centro != centro || antigo.raio != raio;
}
