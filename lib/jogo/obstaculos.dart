import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import 'aventura_jogo.dart';
import 'classes.dart';
import 'fase.dart';
import 'sons.dart';

final _aleatorio = Random();

enum TipoDeObstaculo {
  gelo('obstaculos_gelo.png', Color(0xFFCFEFFF)),
  rachada('obstaculos_rachada.png', Color(0xFF8B9BB4));

  const TipoDeObstaculo(this.imagem, this.corDosCacos);

  final String imagem;
  final Color corDosCacos;

  bool quebraCom(Golpe golpe) => switch (this) {
    gelo => golpe == Golpe.fogo,
    rachada => golpe == Golpe.espada || golpe == Golpe.raio,
  };
}

ParticleSystemComponent _explosao(
  Vector2 centro,
  Color cor, {
  int quantidade = 12,
  double tamanho = 1.6,
}) => ParticleSystemComponent(
  position: centro,
  particle: Particle.generate(
    count: quantidade,
    lifespan: 0.5,
    generator: (_) => AcceleratedParticle(
      speed: Vector2(
        _aleatorio.nextDouble() * 160 - 80,
        _aleatorio.nextDouble() * -150 - 20,
      ),
      acceleration: Vector2(0, 420),
      child: CircleParticle(
        radius: tamanho * (0.6 + _aleatorio.nextDouble()),
        paint: Paint()..color = cor,
      ),
    ),
  ),
);

class BlocoDeElemento extends SpriteComponent
    with HasGameReference<AventuraJogo> {
  BlocoDeElemento({
    required this.tipo,
    required this.coluna,
    required this.linha,
  }) : super(
         position: Vector2(coluna * tamanhoBloco, linha * tamanhoBloco),
         size: Vector2.all(tamanhoBloco),
       );

  final TipoDeObstaculo tipo;
  final int coluna;
  final int linha;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(tipo.imagem));
  }

  void tremer() {
    add(
      SequenceEffect([
        MoveByEffect(Vector2(1.5, 0), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(-3, 0), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(1.5, 0), EffectController(duration: 0.04)),
      ]),
    );
  }

  void quebrar() {
    Sons.tocar(tipo == TipoDeObstaculo.gelo ? 'bolha' : 'pisao', volume: 0.6);
    parent?.add(_explosao(center, tipo.corDosCacos, quantidade: 14));
    removeFromParent();
  }
}

class Fogueira extends PositionComponent with HasGameReference<AventuraJogo> {
  Fogueira({required Vector2 posicao})
    : super(position: posicao, size: Vector2.all(tamanhoBloco));

  bool acesa = true;
  double _tempo = _aleatorio.nextDouble() * 5;
  final Paint _lenha = Paint()..color = const Color(0xFF7A4A2A);
  final Paint _lenhaClara = Paint()..color = const Color(0xFFA8683B);
  final Paint _fogoFora = Paint()..color = const Color(0xFFFF6B1A);
  final Paint _fogoDentro = Paint()..color = const Color(0xFFFFD23F);
  final Paint _cinza = Paint()..color = const Color(0xFF6B6B6B);

  Rect get areaQueQueima =>
      Rect.fromLTWH(position.x + 3, position.y + 5, size.x - 6, size.y - 5);

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
  }

  void apagar() {
    if (!acesa) {
      return;
    }
    acesa = false;
    Sons.tocar('bolha', volume: 0.6);
    parent?.add(
      _explosao(center, const Color(0xCCEEEEEE), quantidade: 16, tamanho: 2.2),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(2, 14, 14, 3), _lenha);
    canvas.drawRect(const Rect.fromLTWH(4, 12, 10, 2), _lenhaClara);
    if (!acesa) {
      canvas.drawRect(const Rect.fromLTWH(5, 11, 8, 2), _cinza);
      return;
    }
    final balanco = sin(_tempo * 9) * 1.2;
    final altura = 10 + sin(_tempo * 13) * 1.5;
    final fora = Path()
      ..moveTo(3, 14)
      ..quadraticBezierTo(4, 6, 9 + balanco, 14 - altura)
      ..quadraticBezierTo(14, 6, 15, 14)
      ..close();
    canvas.drawPath(fora, _fogoFora);
    final dentro = Path()
      ..moveTo(6, 14)
      ..quadraticBezierTo(7, 9, 9 - balanco * 0.6, 14 - altura * 0.6)
      ..quadraticBezierTo(12, 9, 12, 14)
      ..close();
    canvas.drawPath(dentro, _fogoDentro);
  }
}

class Diamante extends SpriteComponent with HasGameReference<AventuraJogo> {
  Diamante({required Vector2 posicao})
    : super(position: posicao, size: Vector2.all(tamanhoBloco));

  bool coletado = false;
  double _tempo = 0;
  late final double _yBase;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache('diamante.png'));
    _yBase = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (coletado) {
      return;
    }
    _tempo += dt;
    position.y = _yBase + sin(_tempo * 3) * 1.5;
  }

  void coletar() {
    coletado = true;
    Sons.tocar('checkpoint', volume: 0.7);
    parent?.add(_explosao(center, const Color(0xFF7FDBFF), quantidade: 16));
    add(MoveByEffect(Vector2(0, -20), EffectController(duration: 0.3)));
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.3),
        onComplete: removeFromParent,
      ),
    );
  }
}
