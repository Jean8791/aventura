import 'dart:ui';

import 'package:flame/components.dart';

import 'aventura_jogo.dart';

class Fundo extends Component with HasGameReference<AventuraJogo> {
  final Paint _pintura = Paint()..filterQuality = FilterQuality.none;
  final Paint _ceu = Paint();

  @override
  void render(Canvas canvas) {
    final dados = game.fase?.dados;
    final imagem = game.images.fromCache(dados?.fundo ?? 'fundo.png');
    _ceu.color = dados?.ceu ?? const Color(0xFFDFF6F5);
    final tela = game.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, tela.x, tela.y), _ceu);
    final escala = tela.y / imagem.height;
    final larguraDaFaixa = imagem.width * escala;
    final deslocamento =
        -(game.camera.viewfinder.position.x *
            game.camera.viewfinder.zoom *
            0.3) %
        larguraDaFaixa;
    final origem = Rect.fromLTWH(
      0,
      0,
      imagem.width.toDouble(),
      imagem.height.toDouble(),
    );
    for (
      var x = deslocamento - larguraDaFaixa;
      x < tela.x;
      x += larguraDaFaixa
    ) {
      canvas.drawImageRect(
        imagem,
        origem,
        Rect.fromLTWH(
          x.floorToDouble(),
          0,
          larguraDaFaixa.ceilToDouble() + 1,
          tela.y,
        ),
        _pintura,
      );
    }
  }
}
