import 'tocador_de_som.dart';

/// Os momentos da mesa que merecem barulho.
enum Som {
  /// As respostas secretas apareceram.
  revelacao,

  /// Alguém quebrou a regra-relâmpago.
  vacilo,

  /// O cronômetro da carta chegou a zero.
  tempo,
}

/// Som e vibração deste celular; quem não quer barulho desliga pelo menu.
bool somLigado = true;

void tocar(Som som) {
  if (somLigado) tocarSom(som);
}
