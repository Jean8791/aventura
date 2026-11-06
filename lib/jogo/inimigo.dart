import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import 'alvo.dart';
import 'aventura_jogo.dart';
import 'classes.dart';
import 'fase.dart';
import 'sons.dart';

enum TipoDeInimigo {
  slime('inimigos/slime.png', vida: 1, velocidade: 22),
  slimeDeFogo('inimigos/slime_fogo.png', vida: 2, velocidade: 30),
  morcego('inimigos/morcego.png', vida: 1, velocidade: 0),
  golem('inimigos/golem.png', vida: 4, velocidade: 14, escala: 1.4);

  const TipoDeInimigo(
    this.imagem, {
    required this.vida,
    required this.velocidade,
    this.escala = 1,
  });

  final String imagem;
  final int vida;
  final double velocidade;
  final double escala;

  static TipoDeInimigo? peloNome(String nome) => switch (nome) {
    'inimigo' || 'slime' => slime,
    'slime_fogo' => slimeDeFogo,
    'morcego' => morcego,
    'golem' => golem,
    _ => null,
  };

  static const _danoBase = {
    Golpe.espada: 2,
    Golpe.raio: 1,
    Golpe.fogo: 2,
    Golpe.terra: 2,
    Golpe.pisao: 1,
    Golpe.agua: 0,
  };

  int danoDe(Golpe golpe) {
    final base = _danoBase[golpe]!;
    return switch ((this, golpe)) {
      (slimeDeFogo, Golpe.fogo) => 0,
      (golem, Golpe.raio) => base * 2,
      (golem, Golpe.fogo) => 1,
      (morcego, Golpe.raio) => base * 2,
      _ => base,
    };
  }
}

class Inimigo extends PositionComponent
    with HasGameReference<AventuraJogo>
    implements Alvo {
  Inimigo({required this.tipo, required Vector2 posicao})
    : vida = tipo.vida,
      _origem = posicao.clone(),
      super(
        position: Vector2(
          posicao.x + (tamanhoBloco - 13 * tipo.escala) / 2,
          posicao.y + tamanhoBloco - 13 * tipo.escala,
        ),
        size: Vector2.all(13 * tipo.escala),
      );

  static const double _gravidade = 1000;
  static const double _tempoPreso = 4;

  final TipoDeInimigo tipo;
  final Vector2 _origem;
  final Vector2 velocidade = Vector2.zero();
  int vida;
  @override
  bool vivo = true;
  double _direcao = -1;
  double _preso = 0;
  double _relogio = Random().nextDouble() * 10;
  double _piscando = 0;

  late final SpriteComponent _visual;
  CircleComponent? _bolha;

  bool get preso => _preso > 0;

  double get _raioDaBolha => max(size.x, size.y) * 0.85;

  Rect get areaDaBolha =>
      Rect.fromCircle(center: Offset(center.x, center.y), radius: _raioDaBolha);

  Rect get topo => Rect.fromLTWH(position.x - 2, position.y - 2, size.x + 4, 6);

  @override
  Future<void> onLoad() async {
    final lado = 16 * 1.15 * tipo.escala;
    _visual = SpriteComponent(
      sprite: Sprite(game.images.fromCache(tipo.imagem)),
      size: Vector2.all(lado),
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y + 1),
    );
    add(_visual);
    if (tipo == TipoDeInimigo.morcego) {
      position.setValues(_origem.x, _origem.y);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!vivo) {
      return;
    }
    final fase = game.fase!;
    if (fase.distanciaAoHeroiMaisProximo(position.x) > 420) {
      return;
    }
    dt = min(dt, 1 / 30);
    _relogio += dt;

    if (_piscando > 0) {
      _piscando = max(0, _piscando - dt);
      _visual.paint.colorFilter =
          _piscando > 0 && (_piscando * 20).floor().isOdd
          ? const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop)
          : null;
    }

    if (preso) {
      _preso -= dt;
      position.y += sin(_relogio * 4) * 6 * dt;
      _bolha?.paint.color = Color.fromARGB(
        _preso < 1 && (_preso * 8).floor().isEven ? 40 : 110,
        120,
        200,
        255,
      );
      if (_preso <= 0) {
        _soltar();
      }
      return;
    }

    if (tipo == TipoDeInimigo.morcego) {
      position.x = _origem.x + sin(_relogio * 0.9) * 50;
      position.y = _origem.y + sin(_relogio * 3) * 12;
      _visual.scale.x = cos(_relogio * 0.9) > 0 ? -1 : 1;
      return;
    }

    velocidade.x = _direcao * tipo.velocidade;
    velocidade.y += _gravidade * dt;
    final resultado = fase.mover(position, size, velocidade, dt);
    final frente = _direcao > 0 ? position.x + size.x + 1 : position.x - 1;
    final semChaoNaFrente =
        resultado.noChao && !fase.temChaoEm(frente, position.y + size.y + 1);
    if (resultado.bateuParede || semChaoNaFrente) {
      _direcao = -_direcao;
    }
    _visual.scale.x = _direcao > 0 ? 1 : -1;
  }

  void virarDeCostasPara(double x) {
    _direcao = center.x < x ? -1 : 1;
  }

  @override
  void receberGolpe(Golpe golpe, {double? deX}) {
    if (!vivo) {
      return;
    }
    if (golpe == Golpe.agua) {
      if (tipo == TipoDeInimigo.slimeDeFogo) {
        _derrotar();
      } else {
        _prender();
      }
      return;
    }
    final dano = tipo.danoDe(golpe);
    if (dano == 0) {
      _mostrarImune();
      return;
    }
    vida -= dano;
    if (vida <= 0) {
      _derrotar();
      return;
    }
    _piscando = 0.3;
    Sons.tocar('acerto', volume: 0.4);
    if (deX != null && tipo != TipoDeInimigo.morcego) {
      _direcao = center.x < deX ? -1 : 1;
      add(
        MoveByEffect(Vector2(_direcao * 6, 0), EffectController(duration: 0.1)),
      );
    }
  }

  void _prender() {
    if (preso) {
      _preso = _tempoPreso;
      return;
    }
    _preso = _tempoPreso;
    velocidade.setZero();
    Sons.tocar('bolha', volume: 0.5);
    final raio = _raioDaBolha;
    _bolha = CircleComponent(
      radius: raio,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = const Color(0x6E78C8FF),
      children: [
        CircleComponent(
          radius: raio,
          paint: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xCCFFFFFF),
        ),
        CircleComponent(
          radius: raio * 0.18,
          position: Vector2(raio * 0.5, raio * 0.45),
          paint: Paint()..color = const Color(0xDDFFFFFF),
        ),
      ],
    );
    add(_bolha!);
  }

  void _soltar() {
    _preso = 0;
    _bolha?.removeFromParent();
    _bolha = null;
    if (tipo == TipoDeInimigo.morcego) {
      _origem.setValues(position.x, position.y);
    }
  }

  void _mostrarImune() {
    Sons.tocar('acerto', volume: 0.2);
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2.all(1.15), EffectController(duration: 0.08)),
        ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.08)),
      ]),
    );
  }

  void esmagar() => receberGolpe(Golpe.pisao);

  void _derrotar() {
    vivo = false;
    _bolha?.removeFromParent();
    Sons.tocar('pisao');
    final aleatorio = Random();
    parent?.add(
      ParticleSystemComponent(
        position: center,
        particle: Particle.generate(
          count: 14,
          lifespan: 0.45,
          generator: (_) => AcceleratedParticle(
            speed: Vector2(
              aleatorio.nextDouble() * 160 - 80,
              aleatorio.nextDouble() * -140 - 20,
            ),
            acceleration: Vector2(0, 400),
            child: CircleParticle(
              radius: 1.2 + aleatorio.nextDouble() * 1.4,
              paint: Paint()..color = const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2(1.4, 0.2),
        EffectController(duration: 0.15),
        onComplete: removeFromParent,
      ),
    );
  }
}
