import 'package:web/web.dart' as web;

/// Mesmo formato do stub; no navegador fica vazio.
final linksAbertos = <String>[];

/// Abre numa aba nova, para não tirar ninguém da sala.
void abrirLink(String url) => web.window.open(url, '_blank');
