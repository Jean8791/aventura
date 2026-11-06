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
  transformando,
  derrotado,
}

class EstagioDoChefe {
  const EstagioDoChefe({
    required this.imagem,
    required this.escala,
    required this.corDaAura,
    required this.intervaloDosOrbes,
    required this.velocidadeDosOrbes,
    required this.angulosDosOrbes,
    required this.maximoDeOrbes,
    required this.orbesNaChuva,
    required this.velocidadeDaInvestida,
    required this.investidaDupla,
    required this.tempoTonto,
    required this.ciclosEntreReforcos,
    required this.reforcos,
  });

  final String imagem;
  final double escala;
  final Color? corDaAura;
  final double intervaloDosOrbes;
  final double velocidadeDosOrbes;
  final List<double> angulosDosOrbes;
  final int maximoDeOrbes;
  final int orbesNaChuva;
  final double velocidadeDaInvestida;
  final bool investidaDupla;
  final double tempoTonto;
  final int ciclosEntreReforcos;
  final List<TipoDeInimigo> reforcos;
}

const estagiosDoChefe = [
  EstagioDoChefe(
    imagem: 'inimigos/feiticeiro.png',
    escala: 1,
    corDaAura: null,
    intervaloDosOrbes: 2.6,
    velocidadeDosOrbes: 55,
    angulosDosOrbes: [0],
    maximoDeOrbes: 2,
    orbesNaChuva: 0,
    velocidadeDaInvestida: 150,
    investidaDupla: false,
    tempoTonto: 3.2,
    ciclosEntreReforcos: 3,
    reforcos: [TipoDeInimigo.slime],
  ),
  EstagioDoChefe(
    imagem: 'inimigos/feiticeiro_bravo.png',
    escala: 1.12,
    corDaAura: Color(0x55FF7A1A),
    intervaloDosOrbes: 2.1,
    velocidadeDosOrbes: 68,
    angulosDosOrbes: [-0.28, 0.28],
    maximoDeOrbes: 4,
    orbesNaChuva: 3,
    velocidadeDaInvestida: 185,
    investidaDupla: false,
    tempoTonto: 2.7,
    ciclosEntreReforcos: 2,
    reforcos: [TipoDeInimigo.slimeDeFogo],
  ),
  EstagioDoChefe(
    imagem: 'inimigos/feiticeiro_furioso.png',
    escala: 1.25,
    corDaAura: Color(0x77FF2A2A),
    intervaloDosOrbes: 1.7,
    velocidadeDosOrbes: 78,
    angulosDosOrbes: [-0.38, 0, 0.38],
    maximoDeOrbes: 6,
    orbesNaChuva: 5,
    velocidadeDaInvestida: 215,
    investidaDupla: true,
    tempoTonto: 2.3,
    ciclosEntreReforcos: 2,
    reforcos: [TipoDeInimigo.slimeDeFogo, TipoDeInimigo.morcego],
  ),
];

class Chefe extends PositionComponent
    with HasGameReference<AventuraJogo>
    implements Alvo {
  Chefe({required this.arena, required this.vidaMaxima})
    : vida = vidaMaxima,
      super(size: Vector2(28, 34));

  static const nome = 'Feiticeiro das Sombras';
  static const _tempoDeTransformacao = 2.6;

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
  int estagio = 0;
  EstadoDoChefe estado = EstadoDoChefe.entrando;

  double _tempo = 0;
  double _invencivel = 0;
  double _proximoOrbe = 1.5;
  double _direcao = 1;
  double _direcaoDaInvestida = 1;
  int _ciclos = 0;
  bool _soltouCoracao = false;
  bool _choveuNesteVoo = false;
  bool _segundaInvestida = false;
  late final SpriteComponent _visual;
  late final _Estrelas _estrelas;
  late final CircleComponent _aura;

  Fase get _fase => game.fase!;

  EstagioDoChefe get _config => estagiosDoChefe[estagio];

  double get _alturaDeVoo => arena.top + 18;

  double get _chao => arena.bottom - size.y;

  @override
  bool get vivo => estado != EstadoDoChefe.derrotado;

  bool get machucaAoEncostar =>
      vivo &&
      estado != EstadoDoChefe.tonto &&
      estado != EstadoDoChefe.entrando &&
      estado != EstadoDoChefe.transformando;

  @override
  Future<void> onLoad() async {
    position = Vector2(arena.center.dx - size.x / 2, arena.top - 70);
    _aura = CircleComponent(
      radius: 26,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 2),
      paint: Paint()..color = const Color(0x00000000),
    );
    _visual = SpriteComponent(
      sprite: Sprite(game.images.fromCache(_config.imagem)),
      size: Vector2.all(46),
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y + 4),
    );
    _estrelas = _Estrelas()..position = Vector2(size.x / 2, -6);
    add(_aura);
    add(_visual);
    _publicarVida();
  }

  void _publicarVida() {
    game.vidaDoChefe.value = vida / vidaMaxima;
    game.estagioDoChefe.value = estagio;
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
    final corDaAura = _config.corDaAura;
    if (corDaAura != null && vivo) {
      final pulso = 0.75 + 0.25 * sin(_tempo * 6);
      _aura.paint.color = corDaAura.withValues(alpha: corDaAura.a * pulso);
      _aura.radius = 24 * _config.escala + 3 * sin(_tempo * 6);
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
        if (_tempo > 0.9 - estagio * 0.15) {
          _visual.position.x = size.x / 2;
          final alvo = _heroiMaisProximo();
          _direcaoDaInvestida = alvo == null || alvo.center.x >= center.x
              ? 1
              : -1;
          _segundaInvestida = false;
          _mudarPara(EstadoDoChefe.descendo);
        }
      case EstadoDoChefe.descendo:
        position.y = min(_chao, position.y + 230 * dt);
        if (position.y >= _chao) {
          _mudarPara(EstadoDoChefe.investindo);
        }
      case EstadoDoChefe.investindo:
        position.x += _direcaoDaInvestida * _config.velocidadeDaInvestida * dt;
        _visual.scale.x = _direcaoDaInvestida * _config.escala;
        final limiteEsquerdo = arena.left;
        final limiteDireito = arena.right - size.x;
        if (position.x <= limiteEsquerdo || position.x >= limiteDireito) {
          position.x = position.x.clamp(limiteEsquerdo, limiteDireito);
          Sons.tocar('pisao', volume: 0.7);
          if (_config.investidaDupla && !_segundaInvestida) {
            _segundaInvestida = true;
            _direcaoDaInvestida = -_direcaoDaInvestida;
          } else {
            add(_estrelas);
            _mudarPara(EstadoDoChefe.tonto);
          }
        }
      case EstadoDoChefe.tonto:
        if (_tempo > _config.tempoTonto) {
          _estrelas.removeFromParent();
          _ciclos++;
          _mudarPara(EstadoDoChefe.subindo);
        }
      case EstadoDoChefe.subindo:
        position.y = max(_alturaDeVoo, position.y - 90 * dt);
        if (position.y <= _alturaDeVoo) {
          if (_ciclos % _config.ciclosEntreReforcos == 0) {
            _chamarReforcos();
          }
          _mudarPara(EstadoDoChefe.flutuando);
        }
      case EstadoDoChefe.transformando:
        _transformando(dt);
      case EstadoDoChefe.derrotado:
        break;
    }
  }

  void _mudarPara(EstadoDoChefe novo) {
    estado = novo;
    _tempo = 0;
    if (novo == EstadoDoChefe.flutuando) {
      _choveuNesteVoo = false;
    }
  }

  void _flutuar(double dt) {
    final alvoX = _direcao > 0 ? arena.right - size.x - 24 : arena.left + 24;
    final passo = (45 + estagio * 12) * dt;
    if ((alvoX - position.x).abs() <= passo) {
      position.x = alvoX;
      _direcao = -_direcao;
    } else {
      position.x += (alvoX - position.x).sign * passo;
    }
    position.y = _alturaDeVoo + sin(_tempo * 2) * 8;
    _visual.scale.x = _direcao * _config.escala;

    _proximoOrbe -= dt;
    if (_proximoOrbe <= 0) {
      _proximoOrbe = _config.intervaloDosOrbes;
      _lancarOrbes();
    }
    if (!_choveuNesteVoo && _config.orbesNaChuva > 0 && _tempo > 2.5) {
      _choveuNesteVoo = true;
      _chuvaDeOrbes();
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

  int get _orbesVivos =>
      _fase.alvosExtras.whereType<Orbe>().where((o) => o.vivo).length;

  void _soltarOrbe(Vector2 origem, Vector2 direcao) {
    if (_orbesVivos >= _config.maximoDeOrbes) {
      return;
    }
    final orbe = Orbe(
      origem: origem,
      direcao: direcao,
      velocidade: _config.velocidadeDosOrbes,
    );
    _fase.alvosExtras.add(orbe);
    _fase.add(orbe);
  }

  void _lancarOrbes() {
    final alvo = _heroiMaisProximo();
    if (alvo == null) {
      return;
    }
    final saida = Vector2(center.x, position.y + size.y * 0.55);
    final base = (alvo.center - saida)..normalize();
    for (final angulo in _config.angulosDosOrbes) {
      _soltarOrbe(saida.clone(), base.clone()..rotate(angulo));
    }
    Sons.tocar('bolha', volume: 0.4);
  }

  void _chuvaDeOrbes() {
    final quantidade = _config.orbesNaChuva;
    final largura = arena.width - 40;
    for (var i = 0; i < quantidade; i++) {
      final x =
          arena.left +
          20 +
          largura * (i + 0.5) / quantidade +
          (_aleatorio.nextDouble() - 0.5) * 20;
      _soltarOrbe(Vector2(x, arena.top + 4), Vector2(0, 1));
    }
    Sons.tocar('raio', volume: 0.4);
  }

  void _chamarReforcos() {
    final vivos = _fase.inimigos.where((i) => i.vivo).length;
    if (vivos >= 3) {
      return;
    }
    final heroi = _heroiMaisProximo();
    final ladoOposto = heroi != null && heroi.center.x < arena.center.dx
        ? arena.right - 20 - tamanhoBloco
        : arena.left + 20;
    for (final tipo in _config.reforcos) {
      final voa = tipo == TipoDeInimigo.morcego;
      final inimigo = Inimigo(
        tipo: tipo,
        posicao: Vector2(
          voa ? arena.center.dx : ladoOposto,
          voa ? arena.top + 60 : arena.bottom - tamanhoBloco,
        ),
      );
      _fase.inimigos.add(inimigo);
      _fase.add(inimigo);
    }
    Sons.tocar('checkpoint', volume: 0.4);
  }

  @override
  void receberGolpe(Golpe golpe, {double? deX}) {
    if (!vivo ||
        estado == EstadoDoChefe.entrando ||
        estado == EstadoDoChefe.transformando ||
        _invencivel > 0) {
      return;
    }
    final dano = _danoPorGolpe[golpe] ?? 1;
    vida = max(0, vida - (estado == EstadoDoChefe.tonto ? dano * 2 : dano));
    _invencivel = 0.35;
    _publicarVida();
    Sons.tocar('acerto', volume: 0.6);
    if (!_soltouCoracao && vida <= vidaMaxima / 2) {
      _soltouCoracao = true;
      _soltarCoracao();
    }
    if (vida <= 0) {
      if (estagio < estagiosDoChefe.length - 1) {
        _comecarTransformacao();
      } else {
        _derrotar();
      }
    }
  }

  void _soltarCoracao() {
    final coracao = Coracao(
      posicao: Vector2(
        arena.center.dx - tamanhoBloco / 2,
        arena.bottom - tamanhoBloco,
      ),
    );
    _fase.coracoes.add(coracao);
    _fase.add(coracao);
  }

  void _limparArena() {
    for (final orbe in _fase.alvosExtras.whereType<Orbe>()) {
      orbe.estourar();
    }
    for (final inimigo in _fase.inimigos) {
      if (inimigo.vivo) {
        inimigo.receberGolpe(Golpe.espada);
        inimigo.receberGolpe(Golpe.espada);
      }
    }
  }

  void _comecarTransformacao() {
    _estrelas.removeFromParent();
    _visual.paint.colorFilter = null;
    _visual.position.x = size.x / 2;
    _limparArena();
    _mudarPara(EstadoDoChefe.transformando);
    Sons.tocar('dano', volume: 0.8);
  }

  void _transformando(double dt) {
    final destino = Vector2(arena.center.dx - size.x / 2, _alturaDeVoo + 10);
    position += (destino - position) * min(1, dt * 3);
    _visual.position.x = size.x / 2 + sin(_tempo * 70) * 2.5;
    final piscar = (_tempo * 12).floor().isOdd;
    _visual.paint.colorFilter = piscar
        ? const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop)
        : null;
    if (_tempo > 0.6 && (_tempo * 10).floor() % 3 == 0) {
      _soltarFaiscas(4);
    }
    if (_tempo >= _tempoDeTransformacao) {
      estagio++;
      vida = vidaMaxima;
      _ciclos = 0;
      _soltouCoracao = false;
      _proximoOrbe = 1.5;
      _visual
        ..sprite = Sprite(game.images.fromCache(_config.imagem))
        ..paint.colorFilter = null
        ..position.x = size.x / 2
        ..scale = Vector2.all(_config.escala);
      _publicarVida();
      _soltarFaiscas(30);
      _soltarCoracao();
      Sons.tocar('mola', volume: 0.8);
      _mudarPara(EstadoDoChefe.flutuando);
    }
  }

  void _soltarFaiscas(int quantidade) {
    _fase.add(
      ParticleSystemComponent(
        position: center,
        particle: Particle.generate(
          count: quantidade,
          lifespan: 0.8,
          generator: (_) => AcceleratedParticle(
            speed: Vector2(
              _aleatorio.nextDouble() * 220 - 110,
              _aleatorio.nextDouble() * -200 - 20,
            ),
            acceleration: Vector2(0, 220),
            child: CircleParticle(
              radius: 1.2 + _aleatorio.nextDouble() * 1.8,
              paint: Paint()
                ..color = _aleatorio.nextBool()
                    ? const Color(0xFFFF9A1F)
                    : const Color(0xFFFF4FD8),
            ),
          ),
        ),
      ),
    );
  }

  void _derrotar() {
    estado = EstadoDoChefe.derrotado;
    _estrelas.removeFromParent();
    _visual.paint.colorFilter = null;
    _aura.paint.color = const Color(0x00000000);
    _limparArena();
    Sons.tocar('pisao', volume: 0.8);
    _soltarFaiscas(40);
    _visual.add(RotateEffect.by(pi * 4, EffectController(duration: 1.2)));
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
    if (!vivo || estado == EstadoDoChefe.transformando) {
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
  Orbe({required Vector2 origem, required this.direcao, this.velocidade = 55})
    : super(position: origem, size: Vector2.all(12), anchor: Anchor.center);

  final Vector2 direcao;
  final double velocidade;
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
    position += direcao * velocidade * dt;
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
