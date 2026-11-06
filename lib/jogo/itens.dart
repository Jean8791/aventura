import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';

import 'aventura_jogo.dart';
import 'fase.dart';

SpriteSheet _folhaDeBlocos(AventuraJogo jogo) => SpriteSheet(
  image: jogo.images.fromCache('blocos.png'),
  srcSize: Vector2.all(tamanhoBloco),
);

class Moeda extends SpriteAnimationComponent
    with HasGameReference<AventuraJogo> {
  Moeda({required Vector2 posicao})
    : super(position: posicao, size: Vector2.all(tamanhoBloco));

  bool coletada = false;

  @override
  Future<void> onLoad() async {
    final folha = _folhaDeBlocos(game);
    animation = SpriteAnimation.spriteList([
      folha.getSpriteById(151),
      folha.getSpriteById(152),
    ], stepTime: 0.35);
  }

  void coletar() {
    coletada = true;
    add(MoveByEffect(Vector2(0, -14), EffectController(duration: 0.25)));
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.25),
        onComplete: removeFromParent,
      ),
    );
  }
}

class Mola extends SpriteComponent with HasGameReference<AventuraJogo> {
  Mola({required Vector2 posicao})
    : super(position: posicao, size: Vector2.all(tamanhoBloco));

  late final Sprite _parada;
  late final Sprite _esticada;

  Rect get areaDeImpulso =>
      Rect.fromLTWH(position.x + 2, position.y + 8, size.x - 4, size.y - 8);

  @override
  Future<void> onLoad() async {
    final folha = _folhaDeBlocos(game);
    _parada = folha.getSpriteById(107);
    _esticada = folha.getSpriteById(108);
    sprite = _parada;
  }

  void impulsionar() {
    sprite = _esticada;
    add(
      TimerComponent(
        period: 0.25,
        removeOnFinish: true,
        onTick: () => sprite = _parada,
      ),
    );
  }
}

class Bandeira extends PositionComponent with HasGameReference<AventuraJogo> {
  Bandeira({
    required Vector2 posicao,
    required this.alturaEmBlocos,
    this.chegada = false,
  }) : super(
         position: posicao,
         size: Vector2(tamanhoBloco, tamanhoBloco * alturaEmBlocos),
       );

  final int alturaEmBlocos;
  final bool chegada;
  bool ativa = false;

  late final SpriteAnimationComponent _pano;

  @override
  Future<void> onLoad() async {
    final folha = _folhaDeBlocos(game);
    for (var i = 1; i < alturaEmBlocos; i++) {
      add(
        SpriteComponent(
          sprite: folha.getSpriteById(131),
          position: Vector2(0, i * tamanhoBloco),
          size: Vector2.all(tamanhoBloco),
        ),
      );
    }
    _pano = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList([
        folha.getSpriteById(111),
        folha.getSpriteById(112),
      ], stepTime: 0.3),
      size: Vector2.all(tamanhoBloco),
      playing: chegada,
    );
    if (!chegada) {
      _pano.opacity = 0.45;
    }
    add(_pano);
  }

  void ativar() {
    ativa = true;
    _pano
      ..opacity = 1
      ..playing = true;
  }
}
