import 'som.dart';

/// Fora do navegador (testes) só anota o que teria tocado.
final sonsTocados = <Som>[];

void tocarSom(Som som) => sonsTocados.add(som);

void prepararSom() {}
