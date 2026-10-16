import 'dart:math';

/// Onde fica o círculo da moldura dentro do quadro 9:16 da câmera,
/// em frações da largura e da altura do quadro.
const centroXDaMoldura = 0.5;
const centroYDaMoldura = 0.42;
const diametroDaMoldura = 0.78;

/// Lado, em pixels, da selfie enviada: pequena para a sala ficar leve.
const ladoDaSelfie = 360;

class Recorte {
  const Recorte(this.x, this.y, this.lado);

  final double x;
  final double y;
  final double lado;

  @override
  bool operator ==(Object other) =>
      other is Recorte && other.x == x && other.y == y && other.lado == lado;

  @override
  int get hashCode => Object.hash(x, y, lado);

  @override
  String toString() => 'Recorte($x, $y, $lado)';
}

/// Quadrado da foto que aparece dentro do círculo da moldura.
///
/// A prévia cobre um quadro 9:16, então só o miolo da foto aparece na tela;
/// o círculo é medido dentro desse miolo. Foto da câmera do sistema não
/// passou pela moldura: aí vale o quadrado do centro.
Recorte recorteDaSelfie(double largura, double altura, {required bool comMoldura}) {
  if (!comMoldura) {
    final lado = min(largura, altura);
    return Recorte((largura - lado) / 2, (altura - lado) / 2, lado);
  }
  const proporcaoDoQuadro = 9 / 16;
  final visivelLargura = largura / altura > proporcaoDoQuadro ? altura * proporcaoDoQuadro : largura;
  final visivelAltura = visivelLargura / proporcaoDoQuadro;
  final lado = min(visivelLargura * diametroDaMoldura, min(largura, altura));
  final x = (largura - visivelLargura) / 2 + visivelLargura * centroXDaMoldura - lado / 2;
  final y = (altura - visivelAltura) / 2 + visivelAltura * centroYDaMoldura - lado / 2;
  return Recorte(x.clamp(0, largura - lado).toDouble(), y.clamp(0, altura - lado).toDouble(), lado);
}
