import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'som.dart';

/// Mesmo formato do stub; no navegador fica vazio.
final sonsTocados = <Som>[];

web.AudioContext? _audio;
StreamSubscription<web.Event>? _destrava;

/// O navegador só libera o som depois de um toque na tela: o primeiro toque
/// na sala destrava, e daí em diante o som pode tocar quando a carta muda
/// sozinha (tempo real).
void prepararSom() {
  _destrava ??= const web.EventStreamProvider<web.Event>('pointerdown').forTarget(web.document).listen((_) {
    try {
      _contexto();
    } catch (_) {
      // Sem Web Audio: o jogo segue mudo.
    }
  });
}

web.AudioContext _contexto() {
  final audio = _audio ??= web.AudioContext();
  if (audio.state == 'suspended') audio.resume();
  return audio;
}

/// Sons feitos na hora, sem arquivo: notas curtas que somem sozinhas.
void tocarSom(Som som) {
  try {
    final audio = _contexto();
    switch (som) {
      case Som.revelacao:
        // Arpejo subindo: dó, mi, sol, dó.
        for (final (indice, frequencia) in [523.25, 659.25, 783.99, 1046.5].indexed) {
          _nota(audio, frequencia, inicio: indice * 0.08, duracao: 0.35, forma: 'triangle');
        }
      case Som.vacilo:
        // Sirene: duas notas alternando.
        for (var vez = 0; vez < 4; vez++) {
          _nota(audio, vez.isEven ? 880 : 660, inicio: vez * 0.14, duracao: 0.13, forma: 'sawtooth', volume: 0.12);
        }
      case Som.tempo:
        // Dois apitos longos de fim de tempo.
        for (var vez = 0; vez < 2; vez++) {
          _nota(audio, 440, inicio: vez * 0.3, duracao: 0.25, forma: 'square', volume: 0.12);
        }
    }
  } catch (_) {
    // Sem Web Audio: fica só a vibração.
  }
  _vibrar(switch (som) {
    Som.revelacao => [60],
    Som.vacilo => [200, 80, 200],
    Som.tempo => [400],
  });
}

void _nota(web.AudioContext audio, double frequencia,
    {required double inicio, required double duracao, required String forma, double volume = 0.2}) {
  final comeca = audio.currentTime + inicio;
  final oscilador = audio.createOscillator()..type = forma;
  oscilador.frequency.value = frequencia;
  final volumeDaNota = audio.createGain();
  volumeDaNota.gain
    ..setValueAtTime(0.0001, comeca)
    ..exponentialRampToValueAtTime(volume, comeca + 0.02)
    ..exponentialRampToValueAtTime(0.0001, comeca + duracao);
  oscilador.connect(volumeDaNota);
  volumeDaNota.connect(audio.destination);
  oscilador.start(comeca);
  oscilador.stop(comeca + duracao + 0.05);
}

/// iPhone não vibra pelo navegador: lá fica só o som.
void _vibrar(List<int> padrao) {
  try {
    web.window.navigator.vibrate([for (final ms in padrao) ms.toJS].toJS);
  } catch (_) {
    // Sem vibração neste aparelho.
  }
}
