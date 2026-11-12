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
import 'sons.dart';

final _aleatorio = Random();

abstract class Poder extends PositionComponent
    with HasGameReference<AventuraJogo> {
  Poder({super.position, super.size, super.anchor});

  final Set<Alvo> _atingidos = {};

  Fase get fase => game.fase!;

  int acertarInimigos(
    Rect area,
    Golpe golpe, {
    bool atravessa = true,
    int forca = 1,
  }) {
    var acertos = 0;
    for (final inimigo in fase.alvos) {
      if (!inimigo.vivo || _atingidos.contains(inimigo)) {
        continue;
      }
      if (inimigo.toRect().overlaps(area)) {
        _atingidos.add(inimigo);
        inimigo.receberGolpe(golpe, deX: area.center.dx, forca: forca);
        acertos++;
        if (!atravessa) {
          break;
        }
      }
    }
    return acertos;
  }

  bool bateuEmBloco(double x, double y) =>
      fase.solido((x / tamanhoBloco).floor(), (y / tamanhoBloco).floor());

  void soltarFaiscas(Vector2 ponto, Color cor, {int quantidade = 8}) {
    fase.add(
      ParticleSystemComponent(
        position: ponto.clone(),
        particle: Particle.generate(
          count: quantidade,
          lifespan: 0.35,
          generator: (_) => AcceleratedParticle(
            speed: Vector2(
              _aleatorio.nextDouble() * 140 - 70,
              _aleatorio.nextDouble() * 140 - 90,
            ),
            acceleration: Vector2(0, 250),
            child: CircleParticle(
              radius: 1 + _aleatorio.nextDouble(),
              paint: Paint()..color = cor,
            ),
          ),
        ),
      ),
    );
  }
}

class Espadada extends Poder {
  Espadada({required this.heroi})
    : super(size: Vector2(22, 22), anchor: Anchor.center);

  final Heroi heroi;
  double _tempo = 0;
  bool _golpeouBlocos = false;
  static const _duracao = 0.18;
  late final SpriteComponent _espada;

  @override
  Future<void> onLoad() async {
    Sons.tocar('espada', volume: 0.5);
    _espada = SpriteComponent(
      sprite: Sprite(game.images.fromCache('poderes/espada.png')),
      size: Vector2.all(18),
      anchor: const Anchor(0.5, 0.9),
      position: Vector2(size.x / 2 - heroi.direcao * 6, size.y / 2 + 6),
    );
    add(_espada);
    _posicionar();
  }

  void _posicionar() {
    position = Vector2(heroi.center.x + heroi.direcao * 13, heroi.center.y - 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    _posicionar();
    final progresso = (_tempo / _duracao).clamp(0.0, 1.0);
    _espada.angle = heroi.direcao * (-1.1 + progresso * 2.4);
    acertarInimigos(toRect(), Golpe.espada);
    if (!_golpeouBlocos && progresso > 0.3) {
      _golpeouBlocos = true;
      fase.golpearArea(toRect(), Golpe.espada);
    }
    if (_tempo >= _duracao) {
      removeFromParent();
    }
  }
}

/// Golpe carregado do Guerreiro: a espada é arremessada em linha reta,
/// com a ponta para a frente. Atravessa inimigos (com a força da carga),
/// quebra rachadas e para na parede.
class EspadaArremessada extends Poder {
  EspadaArremessada({
    required Vector2 origem,
    required this.direcao,
    required this.escala,
    required this.forca,
  }) : super(
         position: origem,
         size: Vector2(tamanhoDaEspada(escala).y, tamanhoDaEspada(escala).x),
         anchor: Anchor.center,
       );

  final double direcao;
  final double escala;
  final int forca;
  double _percorrido = 0;
  static const _velocidade = 340.0;
  late final double alcance = alcanceDoArremesso(escala);

  @override
  Future<void> onLoad() async {
    Sons.tocar('espada', volume: 0.7);
    final tamanho = tamanhoDaEspada(escala);
    add(
      SpriteComponent(
        sprite: Sprite(game.images.fromCache('poderes/espada.png')),
        size: tamanho,
        anchor: Anchor.center,
        position: size / 2,
        // O sprite aponta para cima; gira para a ponta ir à frente.
        angle: direcao * pi / 2,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final passo = _velocidade * dt;
    position.x += direcao * passo;
    _percorrido += passo;
    acertarInimigos(toRect(), Golpe.espada, forca: forca);
    // A ponta inteira (toda a altura da espada) quebra rachadas.
    final ponta = position.x + direcao * size.x / 2;
    final areaDaPonta = Rect.fromLTRB(
      min(ponta, ponta - direcao * 4),
      position.y - size.y / 2,
      max(ponta, ponta - direcao * 4),
      position.y + size.y / 2,
    );
    fase.golpearArea(areaDaPonta, Golpe.espada);
    final bateu = [
      areaDaPonta.top + 1,
      position.y,
      areaDaPonta.bottom - 1,
    ].any((y) => bateuEmBloco(ponta, y));
    if (_percorrido > alcance || bateu) {
      soltarFaiscas(Vector2(ponta, position.y), const Color(0xFFB8C4D6));
      removeFromParent();
    }
  }
}

/// Distância do arremesso: cresce com a carga (160 px por 1× de escala).
double alcanceDoArremesso(double escala) => 160 * escala;

/// A espada carregada cresce mais no comprimento do que na largura.
Vector2 tamanhoDaEspada(double escala) =>
    Vector2(18 * (1 + 0.2 * (escala - 1)), 18 * (1 + 1.2 * (escala - 1)));

/// O que aparece na mão do herói enquanto ele carrega: a espada erguida
/// (Guerreiro) ou uma bola de energia (Raio), crescendo com a carga.
class PreviaDaCarga extends PositionComponent
    with HasGameReference<AventuraJogo> {
  PreviaDaCarga({required this.golpe});

  final Golpe golpe;
  double escala = 1;
  double direcao = 1;
  double _tempo = 0;
  SpriteComponent? _espada;
  final Paint _aura = Paint()..color = const Color(0x66FFE066);
  final Paint _nucleo = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _faisca = Paint()
    ..color = const Color(0xFFFFE066)
    ..strokeWidth = 1;

  @override
  Future<void> onLoad() async {
    if (golpe == Golpe.espada) {
      _espada = SpriteComponent(
        sprite: Sprite(game.images.fromCache('poderes/espada.png')),
        anchor: const Anchor(0.5, 0.9),
      );
      add(_espada!);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    final espada = _espada;
    if (espada != null) {
      espada.size = tamanhoDaEspada(escala);
      // Erguida acima da cabeça, tremendo de leve quando está cheia.
      final tremor = escala >= 2.5 ? 0.05 * sin(_tempo * 40) : 0.0;
      espada.angle = direcao * (-1.7 + tremor);
    }
  }

  @override
  void render(Canvas canvas) {
    if (golpe != Golpe.raio) {
      return;
    }
    final raio = 2.5 * escala;
    canvas.drawCircle(Offset.zero, raio * 1.8, _aura);
    canvas.drawCircle(Offset.zero, raio, _nucleo);
    for (var i = 0; i < 3 + escala.floor(); i++) {
      final angulo = _aleatorio.nextDouble() * pi * 2;
      final ponta = Offset(cos(angulo), sin(angulo)) * raio * 2.2;
      canvas.drawLine(Offset.zero, ponta, _faisca);
    }
  }
}

class Raio extends Poder {
  /// [escala] > 1 é o raio carregado: mais grosso e vai mais longe
  /// (continua atravessando os inimigos).
  Raio({required Vector2 origem, required this.direcao, this.escala = 1})
    : super(
        position: origem,
        size: Vector2(16 * escala, 6 * escala),
        anchor: Anchor.center,
      );

  final double direcao;
  final double escala;
  double _percorrido = 0;
  static const _velocidade = 380.0;
  late final double _alcance = 190.0 * escala;
  late final Paint _brilho = Paint()
    ..color = const Color(0x88FFE066)
    ..strokeWidth = 4 * escala
    ..strokeCap = StrokeCap.round;
  late final Paint _nucleo = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 1.5 * escala;

  @override
  void update(double dt) {
    super.update(dt);
    final passo = _velocidade * dt;
    position.x += direcao * passo;
    _percorrido += passo;
    acertarInimigos(toRect(), Golpe.raio);
    final ponta = position.x + direcao * size.x / 2;
    if (_percorrido > _alcance ||
        fase.golpearPonto(ponta, position.y, Golpe.raio)) {
      soltarFaiscas(Vector2(ponta, position.y), const Color(0xFFFFE066));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final pontos = <Offset>[];
    for (var i = 0; i <= 5; i++) {
      final x = i * size.x / 5;
      final y =
          size.y / 2 +
          (i.isEven ? -2.0 : 2.0) * escala * (_aleatorio.nextDouble() + 0.5);
      pontos.add(Offset(x, y));
    }
    for (var i = 0; i < pontos.length - 1; i++) {
      canvas.drawLine(pontos[i], pontos[i + 1], _brilho);
    }
    for (var i = 0; i < pontos.length - 1; i++) {
      canvas.drawLine(pontos[i], pontos[i + 1], _nucleo);
    }
  }
}

class BolaDeFogo extends Poder {
  BolaDeFogo({required Vector2 origem, required this.direcao})
    : super(position: origem, size: Vector2.all(8), anchor: Anchor.center);

  final double direcao;
  final Vector2 _velocidade = Vector2.zero();
  double _vida = 1.8;
  double _rastro = 0;
  int _quiques = 0;
  final Paint _fora = Paint()..color = const Color(0xFFFF6B1A);
  final Paint _dentro = Paint()..color = const Color(0xFFFFE066);

  @override
  Future<void> onLoad() async {
    _velocidade.setValues(direcao * 170, -60);
    Sons.tocar('fogo', volume: 0.6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    dt = min(dt, 1 / 30);
    _vida -= dt;
    _velocidade.y += 700 * dt;
    position.x += _velocidade.x * dt;
    if (fase.golpearPonto(position.x + direcao * 4, position.y, Golpe.fogo)) {
      _explodir();
      return;
    }
    position.y += _velocidade.y * dt;
    if (_velocidade.y > 0 && bateuEmBloco(position.x, position.y + 4)) {
      position.y =
          (((position.y + 4) / tamanhoBloco).floor()) * tamanhoBloco - 4;
      _velocidade.y = -210;
      _quiques++;
    }
    if (acertarInimigos(toRect().inflate(2), Golpe.fogo, atravessa: false) >
            0 ||
        _vida <= 0 ||
        _quiques > 4 ||
        position.y > fase.altura) {
      _explodir();
      return;
    }
    _rastro -= dt;
    if (_rastro <= 0) {
      _rastro = 0.03;
      fase.add(
        ParticleSystemComponent(
          position: position.clone(),
          particle: CircleParticle(
            radius: 2.5,
            lifespan: 0.25,
            paint: Paint()..color = const Color(0x99FF8A3D),
          ),
        ),
      );
    }
  }

  void _explodir() {
    soltarFaiscas(position, const Color(0xFFFF8A3D), quantidade: 10);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final centro = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(centro, 4, _fora);
    canvas.drawCircle(centro, 2.2, _dentro);
  }
}

class Bolha extends Poder {
  Bolha({required Vector2 origem, required this.direcao})
    : super(position: origem, size: Vector2.all(12), anchor: Anchor.center);

  final double direcao;
  double _tempo = 0;
  late final double _baseY;
  final Paint _corpo = Paint()..color = const Color(0x6678C8FF);
  final Paint _borda = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xDDFFFFFF);
  final Paint _reflexo = Paint()..color = const Color(0xEEFFFFFF);

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
    Sons.tocar('bolha', volume: 0.6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tempo += dt;
    position.x += direcao * 150 * dt;
    position.y = _baseY - _tempo * 10 + sin(_tempo * 12) * 2;
    final area = toRect();
    for (final fogueira in fase.fogueiras) {
      if (fogueira.acesa && fogueira.toRect().overlaps(area)) {
        fogueira.apagar();
        removeFromParent();
        return;
      }
    }
    if (acertarInimigos(area, Golpe.agua, atravessa: false) > 0 ||
        _tempo > 1.4 ||
        bateuEmBloco(position.x + direcao * 6, position.y)) {
      soltarFaiscas(position, const Color(0xFFB8E4FF), quantidade: 6);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final centro = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(centro, 5.5, _corpo);
    canvas.drawCircle(centro, 5.5, _borda);
    canvas.drawCircle(centro + const Offset(1.8, -1.8), 1.2, _reflexo);
  }
}

class PedraMagica extends SpriteComponent with HasGameReference<AventuraJogo> {
  PedraMagica({required this.coluna, required this.linha})
    : super(
        position: Vector2(coluna * tamanhoBloco, linha * tamanhoBloco),
        size: Vector2.all(tamanhoBloco),
      );

  final int coluna;
  final int linha;
  double _vida = 7;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache('poderes/pedra.png'));
    Sons.tocar('terra', volume: 0.5);
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2(1, 0.2), EffectController(duration: 0)),
        ScaleEffect.to(Vector2(1, 1), EffectController(duration: 0.12)),
      ]),
    );
    anchor = Anchor.bottomLeft;
    position.y += tamanhoBloco;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _vida -= dt;
    if (_vida < 1.2) {
      opacity = (_vida * 8).floor().isEven ? 1 : 0.4;
    }
    if (_vida <= 0) {
      game.fase?.removerPedra(this);
    }
  }
}
