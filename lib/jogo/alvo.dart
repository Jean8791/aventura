import 'dart:ui';

import 'classes.dart';

abstract interface class Alvo {
  bool get vivo;

  Rect toRect();

  /// [forca] > 1 é golpe carregado: o dano é multiplicado.
  void receberGolpe(Golpe golpe, {double? deX, int forca = 1});
}
