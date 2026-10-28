import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'voz.dart';

/// Mesmo formato do stub; no navegador fica vazio.
final falasFeitas = <({String texto, Personagem personagem})>[];

StreamSubscription<web.Event>? _destrava;

/// O iPhone só deixa falar depois de um toque na tela: o primeiro toque na
/// sala fala uma frase vazia, e daí em diante a voz pode falar quando a carta
/// muda sozinha (tempo real ou "passar sozinho").
void prepararVoz() {
  _destrava ??= const web.EventStreamProvider<web.Event>('pointerdown').forTarget(web.document).listen((_) {
    try {
      web.window.speechSynthesis.speak(web.SpeechSynthesisUtterance(''));
    } catch (_) {
      // Sem voz neste navegador: o jogo segue só na tela.
    }
    _destrava?.cancel();
  });
}

/// Uma voz em português, se o aparelho tiver; senão, a padrão com o idioma certo.
web.SpeechSynthesisVoice? _vozEmPortugues() {
  final vozes = web.window.speechSynthesis.getVoices().toDart;
  return vozes.where((voz) => voz.lang == 'pt-BR').firstOrNull ??
      vozes.where((voz) => voz.lang.startsWith('pt')).firstOrNull;
}

void falar(String texto, Personagem personagem) {
  try {
    final sintese = web.window.speechSynthesis;
    // Carta nova corta a anterior: a mesa não ouve duas cartas emboladas.
    sintese.cancel();
    final fala = web.SpeechSynthesisUtterance(texto)
      ..lang = 'pt-BR'
      ..pitch = personagem.tom
      ..rate = personagem.velocidade;
    final voz = _vozEmPortugues();
    if (voz != null) fala.voice = voz;
    sintese.speak(fala);
  } catch (_) {
    // Sem voz neste navegador: o jogo segue só na tela.
  }
}
