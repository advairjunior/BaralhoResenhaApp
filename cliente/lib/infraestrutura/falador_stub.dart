import 'voz.dart';

/// Fora do navegador (testes) só anota o que teria falado.
final falasFeitas = <({String texto, Personagem personagem})>[];

void falar(String texto, Personagem personagem) => falasFeitas.add((texto: texto, personagem: personagem));

void prepararVoz() {}
