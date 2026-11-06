import 'dart:ui';

import 'package:flame/components.dart';

import 'aventura_jogo.dart';

class Fundo extends Component with HasGameReference<AventuraJogo> {
  late final Image _imagem;
  final Paint _pintura = Paint()..filterQuality = FilterQuality.none;
  final Paint _ceu = Paint()..color = const Color(0xFFDFF6F5);

  @override
  Future<void> onLoad() async {
    _imagem = game.images.fromCache('fundo.png');
  }

  @override
  void render(Canvas canvas) {
    final tela = game.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, tela.x, tela.y), _ceu);
    final escala = tela.y / _imagem.height;
    final larguraDaFaixa = _imagem.width * escala;
    final deslocamento =
        -(game.camera.viewfinder.position.x *
            game.camera.viewfinder.zoom *
            0.3) %
        larguraDaFaixa;
    final origem = Rect.fromLTWH(
      0,
      0,
      _imagem.width.toDouble(),
      _imagem.height.toDouble(),
    );
    for (
      var x = deslocamento - larguraDaFaixa;
      x < tela.x;
      x += larguraDaFaixa
    ) {
      canvas.drawImageRect(
        _imagem,
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
