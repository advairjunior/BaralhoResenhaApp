import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Abre a janela de compartilhar do sistema com a imagem (WhatsApp,
/// Instagram, salvar nas fotos). Onde o navegador não tem essa janela, como
/// no computador, o arquivo é baixado.
Future<void> compartilharImagem(Uint8List bytes, String nome) =>
    SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png', name: nome)],
      fileNameOverrides: [nome],
    ));

/// Várias fotos de uma vez: no celular abre "Salvar imagens"; no
/// computador, baixa os arquivos.
Future<void> compartilharFotos(List<({Uint8List bytes, String nome})> fotos) =>
    SharePlus.instance.share(ShareParams(
      files: [for (final foto in fotos) XFile.fromData(foto.bytes, mimeType: 'image/jpeg', name: foto.nome)],
      fileNameOverrides: [for (final foto in fotos) foto.nome],
    ));
