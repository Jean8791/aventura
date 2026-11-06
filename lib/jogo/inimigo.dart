import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import 'aventura_jogo.dart';
import 'fase.dart';

class Inimigo extends PositionComponent with HasGameReference<AventuraJogo> {
  Inimigo({required Vector2 posicao})
    : super(
        position: Vector2(
          posicao.x + (tamanhoBloco - 14) / 2,
          posicao.y + tamanhoBloco - 12,
        ),
        size: Vector2(14, 12),
      );

  static const double _velocidade = 22;
  static const double _gravidade = 1000;

  final Vector2 velocidade = Vector2.zero();
  double _direcao = -1;
  bool vivo = true;

  late final SpriteAnimationComponent _visual;
  late final Sprite _esmagado;

  @override
  Future<void> onLoad() async {
    final folha = SpriteSheet(
      image: game.images.fromCache('personagens.png'),
      srcSize: Vector2.all(24),
    );
    _esmagado = folha.getSpriteById(20);
    _visual = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList([
        folha.getSpriteById(18),
        folha.getSpriteById(19),
      ], stepTime: 0.3),
      size: Vector2.all(24),
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y),
    );
    add(_visual);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!vivo) {
      return;
    }
    final fase = game.fase!;
    final distancia = (fase.heroi.position.x - position.x).abs();
    if (distancia > 400) {
      return;
    }

    velocidade.x = _direcao * _velocidade;
    velocidade.y += _gravidade * dt;
    final resultado = fase.mover(position, size, velocidade, dt);

    final frente = _direcao > 0 ? position.x + size.x + 1 : position.x - 1;
    final semChaoNaFrente =
        resultado.noChao && !fase.temChaoEm(frente, position.y + size.y + 1);
    if (resultado.bateuParede || semChaoNaFrente) {
      _direcao = -_direcao;
    }
    _visual.scale.x = _direcao > 0 ? -1 : 1;
  }

  void virarDeCostasPara(double x) {
    _direcao = center.x < x ? -1 : 1;
  }

  void esmagar() {
    vivo = false;
    _visual.removeFromParent();
    add(
      SpriteComponent(
        sprite: _esmagado,
        size: Vector2.all(24),
        anchor: Anchor.bottomCenter,
        position: Vector2(size.x / 2, size.y),
      ),
    );
    add(
      TimerComponent(
        period: 0.4,
        removeOnFinish: true,
        onTick: removeFromParent,
      ),
    );
  }
}
