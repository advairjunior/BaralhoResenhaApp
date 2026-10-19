import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Mesmo formato do stub: se a sala pediu para a tela não apagar.
bool telaAcordada = false;

web.WakeLockSentinel? _trava;
StreamSubscription<web.Event>? _visibilidade;

/// Com a tela apagada o navegador congela a aba: a conexão cai e a pessoa perde
/// a vez de votar. O pedido some quando a aba sai da frente, então volta a
/// ser feito quando ela reaparece.
void manterTelaAcordada(bool ligar) {
  telaAcordada = ligar;
  if (ligar) {
    _pedir();
    _visibilidade ??= web.document.onVisibilityChange.listen((_) {
      if (telaAcordada && web.document.visibilityState == 'visible') _pedir();
    });
  } else {
    _visibilidade?.cancel();
    _visibilidade = null;
    _trava?.release();
    _trava = null;
  }
}

Future<void> _pedir() async {
  if (_trava case final trava? when !trava.released) return;
  try {
    _trava = await web.window.navigator.wakeLock.request('screen').toDart;
  } catch (_) {
    // Navegador sem suporte ou bateria fraca: o jogo segue, só a tela pode apagar.
  }
}
