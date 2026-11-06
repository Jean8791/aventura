import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

import 'alvo.dart';
import 'aventura_jogo.dart';
import 'classes.dart';
import 'fase.dart';
import 'heroi.dart';
import 'inimigo.dart';
import 'itens.dart';
import 'sons.dart';

final _aleatorio = Random();

enum EstadoDoChefe {
  entrando,
  flutuando,
  avisando,
  descendo,
  investindo,
  tonto,
  subindo,
  derrotado,
}

class Chefe extends PositionComponent
    with HasGameReference<AventuraJogo>
    implements Alvo {
  Chefe({required this.arena, required this.vidaMaxima})
    : vida = vidaMaxima,
      super(size: Vector2(28, 34));

  static const nome = 'Feiticeiro das Sombras';

  static const _danoPorGolpe = {
    Golpe.espada: 2,
    Golpe.raio: 1,
    Golpe.fogo: 2,
    Golpe.terra: 2,
    Golpe.agua: 1,
    Golpe.pisao: 2,
  };

  final Rect arena;
  final int vidaMaxima;
  int vida;
  EstadoDoChefe estado = EstadoDoChefe.entrando;

  double _tempo = 0;
  double _invencivel = 0;
  double _proximoOrbe = 1.5;
  double _direcao = 1;
  double _direcaoDaInvestida = 1;
  int _ciclos = 0;
  bool _soltouCoracao = false;
  late final SpriteComponent _visual;
  late final _Estrelas _estrelas;

  Fase get _fase => game.fase!;

  double get _alturaDeVoo => arena.top + 18;

  double get _chao => arena.bottom - size.y;

  @override
  bool get vivo => estado != EstadoDoChefe.derrotado;

  bool get machucaAoEncostar =>
      vivo && estado != EstadoDoChefe.tonto && estado != EstadoDoChefe.entrando;

  @override
  Future<void> onLoad() async {
    position = Vector2(arena.center.dx - size.x / 2, arena.top - 70);
    _visual = SpriteComponent(
      sprite: Sprite(game.images.fromCache('inimigos/feiticeiro.png')),
      size: Vector2.all(46),
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y + 4),
    );
    _estrelas = _Estrelas()..position = Vector2(size.x / 2, -6);
    add(_visual);
    game.vidaDoChefe.value = vida / vidaMaxima;
  }

  @override
  void update(double dt) {
    super.update(dt);
    dt = min(dt, 1 / 30);
    _tempo += dt;
    if (_invencivel > 0) {
      _invencivel = max(0, _invencivel - dt);
      _visual.paint.colorFilter =
          _invencivel > 0 && (_invencivel * 20).floor().isOdd
          ? const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop)
          : null;
    }

    switch (estado) {
      case EstadoDoChefe.entrando:
        position.y = min(_alturaDeVoo, position.y + 40 * dt);
        if (position.y >= _alturaDeVoo && _tempo > 2) {
          _mudarPara(EstadoDoChefe.flutuando);
        }
      case EstadoDoChefe.flutuando:
        _flutuar(dt);
      case EstadoDoChefe.avisando:
        _visual.position.x = size.x / 2 + sin(_tempo * 60) * 2;
        if (_tempo > 0.9) {
          _visual.position.x = size.x / 2;
          final alvo = _heroiMaisProximo();
          _direcaoDaInvestida = alvo == null || alvo.center.x >= center.x
              ? 1
              : -1;
          _mudarPara(EstadoDoChefe.descendo);
        }
      case EstadoDoChefe.descendo:
        position.y = min(_chao, position.y + 230 * dt);
        if (position.y >= _chao) {
          _mudarPara(EstadoDoChefe.investindo);
        }
      case EstadoDoChefe.investindo:
        position.x += _direcaoDaInvestida * 150 * dt;
        _visual.scale.x = _direcaoDaInvestida;
        final limiteEsquerdo = arena.left;
        final limiteDireito = arena.right - size.x;
        if (position.x <= limiteEsquerdo || position.x >= limiteDireito) {
          position.x = position.x.clamp(limiteEsquerdo, limiteDireito);
          Sons.tocar('pisao', volume: 0.7);
          add(_estrelas);
          _mudarPara(EstadoDoChefe.tonto);
        }
      case EstadoDoChefe.tonto:
        if (_tempo > 3.2) {
          _estrelas.removeFromParent();
          _ciclos++;
          _mudarPara(EstadoDoChefe.subindo);
        }
      case EstadoDoChefe.subindo:
        position.y = max(_alturaDeVoo, position.y - 90 * dt);
        if (position.y <= _alturaDeVoo) {
          if (_ciclos % 3 == 0) {
            _invocarSlimes();
          }
          _mudarPara(EstadoDoChefe.flutuando);
        }
      case EstadoDoChefe.derrotado:
        break;
    }
  }

  void _mudarPara(EstadoDoChefe novo) {
    estado = novo;
    _tempo = 0;
  }

  void _flutuar(double dt) {
    final alvoX = _direcao > 0 ? arena.right - size.x - 24 : arena.left + 24;
    final passo = 45 * dt;
    if ((alvoX - position.x).abs() <= passo) {
      position.x = alvoX;
      _direcao = -_direcao;
    } else {
      position.x += (alvoX - position.x).sign * passo;
    }
    position.y = _alturaDeVoo + sin(_tempo * 2) * 8;
    _visual.scale.x = _direcao;

    _proximoOrbe -= dt;
    if (_proximoOrbe <= 0) {
      _proximoOrbe = 2.6;
      _lancarOrbe();
    }
    if (_tempo > 6) {
      _mudarPara(EstadoDoChefe.avisando);
    }
  }

  Heroi? _heroiMaisProximo() {
    Heroi? melhor;
    var menor = double.infinity;
    for (final heroi in _fase.herois) {
      if (!heroi.ativo) {
        continue;
      }
      final distancia = heroi.center.distanceTo(center);
      if (distancia < menor) {
        menor = distancia;
        melhor = heroi;
      }
    }
    return melhor;
  }

  void _lancarOrbe() {
    final alvo = _heroiMaisProximo();
    if (alvo == null) {
      return;
    }
    if (_fase.alvosExtras.whereType<Orbe>().where((o) => o.vivo).length >= 2) {
      return;
    }
    final saida = Vector2(center.x, position.y + size.y * 0.55);
    final direcao = (alvo.center - saida)..normalize();
    final orbe = Orbe(origem: saida, direcao: direcao);
    _fase.alvosExtras.add(orbe);
    _fase.add(orbe);
    Sons.tocar('bolha', volume: 0.4);
  }

  void _invocarSlimes() {
    final vivos = _fase.inimigos.where((i) => i.vivo).length;
    if (vivos >= 3) {
      return;
    }
    final heroi = _heroiMaisProximo();
    final ladoOposto = heroi != null && heroi.center.x < arena.center.dx
        ? arena.right - 20 - tamanhoBloco
        : arena.left + 20;
    for (final x in [ladoOposto]) {
      final slime = Inimigo(
        tipo: TipoDeInimigo.slime,
        posicao: Vector2(x, arena.bottom - tamanhoBloco),
      );
      _fase.inimigos.add(slime);
      _fase.add(slime);
    }
    Sons.tocar('checkpoint', volume: 0.4);
  }

  @override
  void receberGolpe(Golpe golpe, {double? deX}) {
    if (!vivo || estado == EstadoDoChefe.entrando || _invencivel > 0) {
      return;
    }
    final dano = _danoPorGolpe[golpe] ?? 1;
    vida = max(0, vida - (estado == EstadoDoChefe.tonto ? dano * 2 : dano));
    _invencivel = 0.35;
    game.vidaDoChefe.value = vida / vidaMaxima;
    Sons.tocar('acerto', volume: 0.6);
    if (!_soltouCoracao && vida <= vidaMaxima / 2) {
      _soltouCoracao = true;
      final coracao = Coracao(
        posicao: Vector2(
          arena.center.dx - tamanhoBloco / 2,
          arena.bottom - tamanhoBloco,
        ),
      );
      _fase.coracoes.add(coracao);
      _fase.add(coracao);
    }
    if (vida <= 0) {
      _derrotar();
    }
  }

  void _derrotar() {
    estado = EstadoDoChefe.derrotado;
    _estrelas.removeFromParent();
    _visual.paint.colorFilter = null;
    for (final orbe in _fase.alvosExtras.whereType<Orbe>()) {
      orbe.estourar();
    }
    for (final inimigo in _fase.inimigos) {
      if (inimigo.vivo) {
        inimigo.receberGolpe(Golpe.espada);
        inimigo.receberGolpe(Golpe.espada);
      }
    }
    Sons.tocar('pisao', volume: 0.8);
    _fase.add(
      ParticleSystemComponent(
        position: center,
        particle: Particle.generate(
          count: 40,
          lifespan: 1.2,
          generator: (_) => AcceleratedParticle(
            speed: Vector2(
              _aleatorio.nextDouble() * 260 - 130,
              _aleatorio.nextDouble() * -220 - 20,
            ),
            acceleration: Vector2(0, 260),
            child: CircleParticle(
              radius: 1.5 + _aleatorio.nextDouble() * 2,
              paint: Paint()
                ..color = _aleatorio.nextBool()
                    ? const Color(0xFFFF4FD8)
                    : const Color(0xFF9B5DE5),
            ),
          ),
        ),
      ),
    );
    _visual.add(
      SequenceEffect([
        RotateEffect.by(pi * 4, EffectController(duration: 1.2)),
      ]),
    );
    _visual.add(OpacityEffect.fadeOut(EffectController(duration: 1.2)));
    add(
      TimerComponent(
        period: 1.6,
        removeOnFinish: true,
        onTick: _fase.chefeDerrotado,
      ),
    );
  }

  void reiniciarAtaque() {
    if (!vivo) {
      return;
    }
    for (final orbe in _fase.alvosExtras.whereType<Orbe>()) {
      orbe.estourar();
    }
    _estrelas.removeFromParent();
    _visual.position.x = size.x / 2;
    _mudarPara(EstadoDoChefe.subindo);
  }
}

class Orbe extends PositionComponent
    with HasGameReference<AventuraJogo>
    implements Alvo {
  Orbe({required Vector2 origem, required this.direcao})
    : super(position: origem, size: Vector2.all(12), anchor: Anchor.center);

  final Vector2 direcao;
  double _vida = 6;
  double _tempo = 0;
  bool _estourado = false;
  final Paint _fora = Paint()..color = const Color(0xCC3D1A63);
  final Paint _brilho = Paint()..color = const Color(0xFFFF4FD8);
  final Paint _centro = Paint()..color = const Color(0xFFFFFFFF);

  @override
  bool get vivo => !_estourado;

  @override
  void update(double dt) {
    super.update(dt);
    if (_estourado) {
      return;
    }
    _tempo += dt;
    _vida -= dt;
    position += direcao * 55 * dt;
    final fase = game.fase!;
    if (_vida <= 0 ||
        fase.solido(
          (position.x / tamanhoBloco).floor(),
          (position.y / tamanhoBloco).floor(),
        )) {
      estourar();
    }
  }

  @override
  void receberGolpe(Golpe golpe, {double? deX}) => estourar();

  void estourar() {
    if (_estourado) {
      return;
    }
    _estourado = true;
    game.fase?.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: Particle.generate(
          count: 8,
          lifespan: 0.35,
          generator: (_) => AcceleratedParticle(
            speed: Vector2(
              _aleatorio.nextDouble() * 120 - 60,
              _aleatorio.nextDouble() * 120 - 60,
            ),
            child: CircleParticle(radius: 1.4, paint: _brilho),
          ),
        ),
      ),
    );
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final pulso = 1 + sin(_tempo * 10) * 0.12;
    final centro = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(centro, 6 * pulso, _fora);
    canvas.drawCircle(centro, 3.4 * pulso, _brilho);
    canvas.drawCircle(centro, 1.4, _centro);
  }
}

class _Estrelas extends PositionComponent {
  double _tempo = 0;
  final Paint _amarelo = Paint()..color = const Color(0xFFFFE066);

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
  }

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < 3; i++) {
      final angulo = _tempo * 4 + i * 2 * pi / 3;
      canvas.drawCircle(Offset(cos(angulo) * 12, sin(angulo) * 4), 2, _amarelo);
    }
  }
}
