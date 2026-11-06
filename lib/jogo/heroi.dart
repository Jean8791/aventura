import 'dart:math';

import 'package:flame/components.dart';

import 'aventura_jogo.dart';
import 'classes.dart';
import 'fase.dart';
import 'poderes.dart';
import 'sons.dart';

class Heroi extends PositionComponent with HasGameReference<AventuraJogo> {
  Heroi({required this.classe, required Vector2 posicao})
    : super(position: posicao, size: Vector2(largura, altura));

  static const double largura = 12;
  static const double altura = 16;

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

  final ClasseDeHeroi classe;
  final Vector2 velocidade = Vector2.zero();
  double direcao = 1;
  double _recarga = 0;
  double _passos = 0;

  bool noChao = false;
  double _coyote = 0;
  double _bufferPulo = 0;
  double _invencivel = 0;
  bool _congelado = false;
  bool _puloCortavel = false;

  late final SpriteComponent _visual;

  @override
  Future<void> onLoad() async {
    _visual = SpriteComponent(
      sprite: Sprite(game.images.fromCache(classe.imagem)),
      size: Vector2.all(20),
      anchor: Anchor.bottomCenter,
      position: Vector2(largura / 2, altura + 1),
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
      this.direcao = direcao;
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

    _recarga = max(0, _recarga - dt);
    if (controle.consumirPedidoDeAtaque() && _recarga == 0) {
      _recarga = classe.recarga;
      _usarPoder();
    }

    final pesAntes = position.y + size.y;
    velocidade.y = min(velocidade.y + _gravidade * dt, _quedaMaxima);
    final resultado = _fase.mover(position, size, velocidade, dt);
    noChao = resultado.noChao || _pousarEmInimigoPreso(pesAntes);

    if (_invencivel > 0) {
      _invencivel = max(0, _invencivel - dt);
      _visual.opacity = _invencivel == 0 || (_invencivel * 10).floor().isEven
          ? 1
          : 0.35;
    }

    _animar(dt);
  }

  bool _pousarEmInimigoPreso(double pesAntes) {
    if (velocidade.y < 0) {
      return false;
    }
    for (final inimigo in _fase.inimigos) {
      if (!inimigo.vivo || !inimigo.preso) {
        continue;
      }
      final bolha = inimigo.areaDaBolha;
      final topo = bolha.top + 2;
      final pes = position.y + size.y;
      final sobreposicaoX =
          position.x + size.x > bolha.left + 2 && position.x < bolha.right - 2;
      if (sobreposicaoX && pesAntes <= topo + 4 && pes >= topo - 1) {
        position.y = topo - size.y;
        velocidade.y = 0;
        return true;
      }
    }
    return false;
  }

  void _animar(double dt) {
    _visual.scale.x = direcao;
    if (!noChao) {
      _visual.position.y = altura + 1;
      _visual.scale.y = velocidade.y < 0 ? 1.08 : 0.96;
      return;
    }
    _visual.scale.y = 1;
    if (velocidade.x.abs() > 5) {
      _passos += dt * 14;
      _visual.position.y = altura + 1 - (sin(_passos).abs() * 1.6);
    } else {
      _passos = 0;
      _visual.position.y = altura + 1;
    }
  }

  void _usarPoder() {
    final frente = Vector2(center.x + direcao * 8, position.y + 7);
    switch (classe.poder) {
      case Golpe.espada:
        _fase.add(Espadada(heroi: this));
      case Golpe.raio:
        Sons.tocar('raio', volume: 0.4);
        _fase.add(Raio(origem: frente, direcao: direcao));
      case Golpe.fogo:
        _fase.add(BolaDeFogo(origem: frente, direcao: direcao));
      case Golpe.agua:
        _fase.add(Bolha(origem: frente, direcao: direcao));
      case Golpe.terra:
        _fase.criarPedraNaFrente(this);
      case Golpe.pisao:
        break;
    }
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
    _visual
      ..scale.y = 1
      ..position.y = altura + 1;
  }
}
