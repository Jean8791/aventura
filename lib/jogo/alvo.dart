import 'dart:ui';

import 'classes.dart';

abstract interface class Alvo {
  bool get vivo;

  Rect toRect();

  void receberGolpe(Golpe golpe, {double? deX});
}
