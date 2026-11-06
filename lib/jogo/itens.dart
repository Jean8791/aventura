import 'dart:math';
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

class Coracao extends SpriteComponent with HasGameReference<AventuraJogo> {
  Coracao({required Vector2 posicao})
    : super(position: posicao, size: Vector2.all(tamanhoBloco));

  bool coletado = false;
  double _tempo = 0;
  late double _yBase;

  @override
  Future<void> onLoad() async {
    sprite = _folhaDeBlocos(game).getSpriteById(44);
    _yBase = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (coletado) {
      return;
    }
    _tempo += dt;
    position.y = _yBase + (_tempo * 4 % 2 < 1 ? 0 : -1.5);
  }

  void coletar() {
    coletado = true;
    add(MoveByEffect(Vector2(0, -16), EffectController(duration: 0.3)));
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.3),
        onComplete: removeFromParent,
      ),
    );
  }
}

class PlataformaMovel extends PositionComponent
    with HasGameReference<AventuraJogo> {
  PlataformaMovel({
    required this.inicio,
    required this.fim,
    this.periodo = 5,
    this.tileEsquerda = 1,
  }) : super(
         position: inicio.clone(),
         size: Vector2(tamanhoBloco * 3, tamanhoBloco),
       );

  final Vector2 inicio;
  final Vector2 fim;
  final double periodo;
  final int tileEsquerda;
  final Vector2 deslocamento = Vector2.zero();
  double _tempo = 0;

  @override
  Future<void> onLoad() async {
    final folha = _folhaDeBlocos(game);
    for (var i = 0; i < 3; i++) {
      add(
        SpriteComponent(
          sprite: folha.getSpriteById(tileEsquerda + i),
          position: Vector2(i * tamanhoBloco, 0),
          size: Vector2.all(tamanhoBloco),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    final t = (1 - cos(_tempo * 2 * pi / periodo)) / 2;
    final nova = inicio + (fim - inicio) * t;
    deslocamento.setFrom(nova - position);
    position.setFrom(nova);
  }
}
