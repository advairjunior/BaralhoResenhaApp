import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../dominio/recorte_da_selfie.dart';

/// Recorta o círculo da moldura e salva um JPEG pequeno pelo canvas do
/// navegador: a foto da câmera tem megabytes; a selfie sai com dezenas de KB.
Future<Uint8List> reduzirSelfie(Uint8List foto, {required bool comMoldura}) async {
  final original = web.Blob(<web.BlobPart>[foto.toJS].toJS);
  // createImageBitmap já respeita a orientação gravada pelo iPhone.
  final imagem = await web.window.createImageBitmap(original).toDart;
  final recorte = recorteDaSelfie(imagem.width.toDouble(), imagem.height.toDouble(), comMoldura: comMoldura);

  final canvas = web.HTMLCanvasElement()
    ..width = ladoDaSelfie
    ..height = ladoDaSelfie;
  final contexto = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  contexto.drawImage(
      imagem, recorte.x, recorte.y, recorte.lado, recorte.lado, 0, 0, ladoDaSelfie, ladoDaSelfie);
  imagem.close();

  final pronto = Completer<web.Blob?>();
  canvas.toBlob(((web.Blob? jpeg) => pronto.complete(jpeg)).toJS, 'image/jpeg', 0.82.toJS);
  final jpeg = await pronto.future;
  if (jpeg == null) throw StateError('O navegador não gerou a foto.');
  final conteudo = await jpeg.arrayBuffer().toDart;
  return conteudo.toDart.asUint8List();
}
