import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import 'aventura_jogo.dart';
import 'fase.dart';
import 'sons.dart';

enum EstadoHeroi { parado, andando, pulando }

class Heroi extends PositionComponent with HasGameReference<AventuraJogo> {
  Heroi({required this.indiceSprite, required Vector2 posicao})
    : super(position: posicao, size: Vector2(largura, altura));

  static const double largura = 14;
  static const double altura = 18;

  static const double _gravidade = 1000;
  static const double _velocidadeDoPulo = 400;
  static const double _velocidadeAoSoltarPulo = 270;
  static const double _quedaMaxima = 450;
  static const double _velocidadeMaxima = 105;
  static const double _aceleracaoNoChao = 900;
  static const double _aceleracaoNoAr = 600;
  static const double _atrito = 1100;
  static const double _tempoCoyote = 0.12;
  static const double _tempoDoBufferDePulo = 0.15;
  static const double _tempoInvencivel = 1.5;

  final int indiceSprite;
  final Vector2 velocidade = Vector2.zero();

  bool noChao = false;
  double _coyote = 0;
  double _bufferPulo = 0;
  double _invencivel = 0;
  bool _congelado = false;
  bool _puloCortavel = false;

  late final SpriteAnimationGroupComponent<EstadoHeroi> _visual;

  @override
  Future<void> onLoad() async {
    final folha = SpriteSheet(
      image: game.images.fromCache('personagens.png'),
      srcSize: Vector2.all(24),
    );
    final a = folha.getSpriteById(indiceSprite);
    final b = folha.getSpriteById(indiceSprite + 1);
    _visual = SpriteAnimationGroupComponent<EstadoHeroi>(
      animations: {
        EstadoHeroi.parado: SpriteAnimation.spriteList([a], stepTime: 1),
        EstadoHeroi.andando: SpriteAnimation.spriteList([a, b], stepTime: 0.14),
        EstadoHeroi.pulando: SpriteAnimation.spriteList([b], stepTime: 1),
      },
      current: EstadoHeroi.parado,
      size: Vector2.all(24),
      anchor: Anchor.bottomCenter,
      position: Vector2(largura / 2, altura),
    );
    add(_visual);
  }

  Fase get _fase => game.fase!;

  @override
  void update(double dt) {
    super.update(dt);
    if (_congelado) {
      return;
    }
    dt = min(dt, 1 / 30);
    final controle = game.controle;

    var direcao = 0.0;
    if (controle.esquerda) direcao -= 1;
    if (controle.direita) direcao += 1;

    final aceleracao = noChao ? _aceleracaoNoChao : _aceleracaoNoAr;
    if (direcao != 0) {
      velocidade.x = (velocidade.x + direcao * aceleracao * dt).clamp(
        -_velocidadeMaxima,
        _velocidadeMaxima,
      );
      _visual.scale.x = direcao;
    } else if (noChao) {
      final reducao = _atrito * dt;
      velocidade.x = velocidade.x.abs() <= reducao
          ? 0
          : velocidade.x - velocidade.x.sign * reducao;
    }

    if (controle.consumirPedidoDePulo()) {
      _bufferPulo = _tempoDoBufferDePulo;
    } else {
      _bufferPulo = max(0, _bufferPulo - dt);
    }
    _coyote = noChao ? _tempoCoyote : max(0, _coyote - dt);

    if (_bufferPulo > 0 && _coyote > 0) {
      velocidade.y = -_velocidadeDoPulo;
      _puloCortavel = true;
      _bufferPulo = 0;
      _coyote = 0;
      noChao = false;
      Sons.tocar('pulo', volume: 0.35);
    }
    if (velocidade.y >= 0) {
      _puloCortavel = false;
    }
    if (_puloCortavel &&
        !controle.seguraPulo &&
        velocidade.y < -_velocidadeAoSoltarPulo) {
      velocidade.y = -_velocidadeAoSoltarPulo;
      _puloCortavel = false;
    }

    velocidade.y = min(velocidade.y + _gravidade * dt, _quedaMaxima);
    final resultado = _fase.mover(position, size, velocidade, dt);
    noChao = resultado.noChao;

    if (_invencivel > 0) {
      _invencivel = max(0, _invencivel - dt);
      _visual.opacity = _invencivel == 0 || (_invencivel * 10).floor().isEven
          ? 1
          : 0.35;
    }

    _visual.current = !noChao
        ? EstadoHeroi.pulando
        : velocidade.x.abs() > 5
        ? EstadoHeroi.andando
        : EstadoHeroi.parado;
  }

  void quicarNoInimigo() {
    velocidade.y = game.controle.seguraPulo ? -_velocidadeDoPulo : -260;
    _puloCortavel = false;
  }

  void impulsionarPelaMola() {
    velocidade.y = -620;
    _puloCortavel = false;
    noChao = false;
    Sons.tocar('mola', volume: 0.5);
  }

  void levarDano({required double origemX}) {
    if (_invencivel > 0 || _congelado) {
      return;
    }
    _invencivel = _tempoInvencivel;
    velocidade
      ..x = (center.x < origemX ? -1 : 1) * 60
      ..y = -180;
    Sons.tocar('dano', volume: 0.5);
    game.perderCoracao();
  }

  void caiuNoBuraco() {
    if (_congelado) {
      return;
    }
    Sons.tocar('dano', volume: 0.5);
    _congelado = true;
    velocidade.setZero();
    game.perderCoracao(caiu: true);
  }

  void reaparecer(Vector2 posicao) {
    position.setFrom(posicao);
    velocidade.setZero();
    _congelado = false;
    _invencivel = _tempoInvencivel;
  }

  void congelar() {
    _congelado = true;
    velocidade.setZero();
    _visual.current = EstadoHeroi.parado;
  }
}
