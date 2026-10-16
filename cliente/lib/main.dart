import 'package:flutter/material.dart';

import 'infraestrutura/api_baralho.dart';
import 'infraestrutura/sessoes_locais.dart';
import 'tema/tema_baralho.dart';
import 'telas/inicio.dart';
import 'telas/sala.dart';

void main() => runApp(BaralhoResenhaApp());

class BaralhoResenhaApp extends StatelessWidget {
  BaralhoResenhaApp({super.key, ApiBaralho? api, SessoesLocais? sessoes})
      : api = api ?? ApiBaralho(),
        sessoes = sessoes ?? SessoesLocais();

  final ApiBaralho api;
  final SessoesLocais sessoes;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baralho da Resenha',
      debugShowCheckedModeBanner: false,
      theme: TemaBaralho.escuro,
      // Link da sala (QR Code) abre só a sala, sem a tela inicial por baixo.
      onGenerateInitialRoutes: (rota) => [_rota(RouteSettings(name: rota))],
      onGenerateRoute: _rota,
    );
  }

  Route<void> _rota(RouteSettings configuracao) {
    final uri = Uri.parse(configuracao.name ?? '/');
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'sala') {
      final codigo = uri.pathSegments.last.toUpperCase();
      return MaterialPageRoute<void>(
        settings: configuracao,
        builder: (_) => TelaDaSala(key: ValueKey(codigo), codigo: codigo, api: api, sessoes: sessoes),
      );
    }
    return MaterialPageRoute<void>(
      settings: configuracao,
      builder: (_) => Inicio(api: api, sessoes: sessoes),
    );
  }
}
