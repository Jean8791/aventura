import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'aventura_jogo.dart';
import 'classes.dart';
import 'heroi.dart';
import 'inimigo.dart';
import 'fases.dart';
import 'itens.dart';
import 'obstaculos.dart';
import 'poderes.dart';
import 'progresso.dart';
import 'sons.dart';

const double tamanhoBloco = 18;

class ResultadoMovimento {
  bool noChao = false;
  bool bateuParede = false;
  bool bateuTeto = false;
}

class Fase extends World with HasGameReference<AventuraJogo> {
  Fase({required this.dados, required this.classe, required this.numero});

  final DadosDaFase dados;
  final int numero;
  final Map<(int, int), BlocoDeElemento> _blocosDeElemento = {};
  final List<Fogueira> fogueiras = [];
  final List<Diamante> diamantes = [];
  final ClasseDeHeroi classe;
  final Set<(int, int)> _pedras = {};
  final List<PedraMagica> _pedrasAtivas = [];
  static const _maximoDePedras = 3;

  late final TiledComponent mapa;
  late final List<List<bool>> _solidos;
  late final int colunas;
  late final int linhas;

  final List<Moeda> moedas = [];
  final List<Inimigo> inimigos = [];
  final List<Mola> molas = [];
  final List<Bandeira> checkpoints = [];
  late final Bandeira chegada;

  late final Heroi heroi;
  late Vector2 pontoDeRetorno;
  bool terminou = false;

  double get largura => colunas * tamanhoBloco;
  double get altura => linhas * tamanhoBloco;

  @override
  Future<void> onLoad() async {
    mapa = await TiledComponent.load(
      dados.arquivo,
      Vector2.all(tamanhoBloco),
      images: game.imagensDosBlocos,
    );
    add(mapa);

    final terreno = mapa.tileMap.getLayer<TileLayer>('terreno')!;
    colunas = terreno.width;
    linhas = terreno.height;
    final celulas = terreno.tileData!;
    _solidos = [
      for (var r = 0; r < linhas; r++)
        [for (var c = 0; c < colunas; c++) celulas[r][c].tile != 0],
    ];

    Vector2? inicio;
    final objetos = mapa.tileMap.getLayer<ObjectGroup>('objetos')!;
    for (final o in objetos.objects) {
      final pos = Vector2(o.x, o.y);
      switch (o.name) {
        case 'inicio':
          inicio = pos;
        case 'moeda':
          moedas.add(Moeda(posicao: pos));
        case 'mola':
          molas.add(Mola(posicao: pos));
        case 'checkpoint':
          checkpoints.add(
            Bandeira(
              posicao: pos,
              alturaEmBlocos: (o.height / tamanhoBloco).round(),
            ),
          );
        case 'chegada':
          chegada = Bandeira(
            posicao: pos,
            alturaEmBlocos: (o.height / tamanhoBloco).round(),
            chegada: true,
          );
        case 'gelo' || 'rachada':
          final bloco = BlocoDeElemento(
            tipo: o.name == 'gelo'
                ? TipoDeObstaculo.gelo
                : TipoDeObstaculo.rachada,
            coluna: (o.x / tamanhoBloco).round(),
            linha: (o.y / tamanhoBloco).round(),
          );
          _blocosDeElemento[(bloco.coluna, bloco.linha)] = bloco;
        case 'fogueira':
          fogueiras.add(Fogueira(posicao: pos));
        case 'diamante':
          final indice = diamantes.length;
          diamantes.add(
            Diamante(
              posicao: pos,
              indice: indice,
              jaEncontrado: Progresso.diamantes(numero).contains(indice),
            ),
          );
        default:
          final tipo = TipoDeInimigo.peloNome(o.name);
          if (tipo != null) {
            inimigos.add(Inimigo(tipo: tipo, posicao: pos));
          }
      }
    }
    addAll([
      ..._blocosDeElemento.values,
      ...fogueiras,
      ...moedas,
      ...diamantes,
      ...inimigos,
      ...molas,
      ...checkpoints,
      chegada,
    ]);

    pontoDeRetorno = inicio ?? Vector2(tamanhoBloco * 2, tamanhoBloco * 8);
    heroi = Heroi(classe: classe, posicao: _posicaoDoHeroi(pontoDeRetorno));
    add(heroi);
    game.totalDeMoedas = moedas.length;
    game.totalDeDiamantes = diamantes.length;
  }

  Vector2 _posicaoDoHeroi(Vector2 ponto) => Vector2(
    ponto.x + (tamanhoBloco - Heroi.largura) / 2,
    ponto.y + tamanhoBloco * 2 - Heroi.altura,
  );

  bool solido(int coluna, int linha) {
    if (coluna < 0 || coluna >= colunas) {
      return true;
    }
    if (linha < 0 || linha >= linhas) {
      return false;
    }
    return _solidos[linha][coluna] ||
        _pedras.contains((coluna, linha)) ||
        _blocosDeElemento.containsKey((coluna, linha));
  }

  ResultadoMovimento mover(
    Vector2 posicao,
    Vector2 tamanho,
    Vector2 velocidade,
    double dt,
  ) {
    final resultado = ResultadoMovimento();
    const passoMaximo = 6.0;
    final distancia = max(velocidade.x.abs(), velocidade.y.abs()) * dt;
    final passos = max(1, (distancia / passoMaximo).ceil());
    final dtDoPasso = dt / passos;
    for (var i = 0; i < passos; i++) {
      final parcial = _moverUmPasso(posicao, tamanho, velocidade, dtDoPasso);
      resultado.noChao |= parcial.noChao;
      resultado.bateuParede |= parcial.bateuParede;
      resultado.bateuTeto |= parcial.bateuTeto;
    }
    return resultado;
  }

  ResultadoMovimento _moverUmPasso(
    Vector2 posicao,
    Vector2 tamanho,
    Vector2 velocidade,
    double dt,
  ) {
    final resultado = ResultadoMovimento();
    const folga = 0.001;

    posicao.x += velocidade.x * dt;
    if (velocidade.x != 0) {
      final topo = (posicao.y / tamanhoBloco).floor();
      final base = ((posicao.y + tamanho.y - folga) / tamanhoBloco).floor();
      final coluna = velocidade.x > 0
          ? ((posicao.x + tamanho.x - folga) / tamanhoBloco).floor()
          : (posicao.x / tamanhoBloco).floor();
      for (var linha = topo; linha <= base; linha++) {
        if (solido(coluna, linha)) {
          posicao.x = velocidade.x > 0
              ? coluna * tamanhoBloco - tamanho.x
              : (coluna + 1) * tamanhoBloco;
          velocidade.x = 0;
          resultado.bateuParede = true;
          break;
        }
      }
    }

    posicao.y += velocidade.y * dt;
    if (velocidade.y != 0) {
      final esquerda = (posicao.x / tamanhoBloco).floor();
      final direita = ((posicao.x + tamanho.x - folga) / tamanhoBloco).floor();
      final linha = velocidade.y > 0
          ? ((posicao.y + tamanho.y - folga) / tamanhoBloco).floor()
          : (posicao.y / tamanhoBloco).floor();
      for (var coluna = esquerda; coluna <= direita; coluna++) {
        if (solido(coluna, linha)) {
          if (velocidade.y > 0) {
            posicao.y = linha * tamanhoBloco - tamanho.y;
            resultado.noChao = true;
          } else {
            posicao.y = (linha + 1) * tamanhoBloco;
            resultado.bateuTeto = true;
          }
          velocidade.y = 0;
          break;
        }
      }
    }
    return resultado;
  }

  bool temChaoEm(double x, double yDosPes) =>
      solido((x / tamanhoBloco).floor(), (yDosPes / tamanhoBloco).floor());

  @override
  void update(double dt) {
    super.update(dt);
    if (terminou) {
      return;
    }
    final corpo = heroi.toRect();

    for (final moeda in moedas) {
      if (!moeda.coletada && moeda.toRect().deflate(3).overlaps(corpo)) {
        moeda.coletar();
        game.moedas.value++;
        Sons.tocar('moeda', volume: 0.4);
      }
    }

    for (final mola in molas) {
      if (heroi.velocidade.y >= 0 && mola.areaDeImpulso.overlaps(corpo)) {
        mola.impulsionar();
        heroi.impulsionarPelaMola();
      }
    }

    for (final inimigo in inimigos) {
      if (!inimigo.vivo ||
          inimigo.preso ||
          !inimigo.toRect().deflate(2).overlaps(corpo)) {
        continue;
      }
      final pesAntes = corpo.bottom - heroi.velocidade.y * dt;
      if (heroi.velocidade.y > 0 && pesAntes <= inimigo.toRect().top + 6) {
        inimigo.esmagar();
        heroi.quicarNoInimigo();
      } else {
        inimigo.virarDeCostasPara(heroi.center.x);
        heroi.levarDano(origemX: inimigo.center.x);
      }
    }

    for (final diamante in diamantes) {
      if (!diamante.coletado && diamante.toRect().deflate(3).overlaps(corpo)) {
        diamante.coletar();
        game.diamantes.value++;
        Progresso.salvarDiamante(numero, diamante.indice);
      }
    }

    if (classe.poder != Golpe.fogo) {
      for (final fogueira in fogueiras) {
        if (fogueira.acesa && fogueira.areaQueQueima.overlaps(corpo)) {
          heroi.levarDano(origemX: fogueira.center.x);
        }
      }
    }

    for (final bandeira in checkpoints) {
      if (!bandeira.ativa && bandeira.toRect().overlaps(corpo)) {
        bandeira.ativar();
        pontoDeRetorno = bandeira.position.clone();
        Sons.tocar('checkpoint');
      }
    }

    if (chegada.toRect().overlaps(corpo)) {
      terminou = true;
      chegada.ativar();
      game.venceu();
    }

    if (heroi.position.y > altura + 40) {
      heroi.caiuNoBuraco();
    }
  }

  void criarPedraNaFrente(Heroi heroi) {
    final coluna = heroi.direcao > 0
        ? ((heroi.position.x + heroi.size.x) / tamanhoBloco).ceil()
        : (heroi.position.x / tamanhoBloco).floor() - 1;
    final linhaDosPes = ((heroi.position.y + heroi.size.y - 1) / tamanhoBloco)
        .floor();
    for (final linha in [linhaDosPes, linhaDosPes - 1]) {
      if (solido(coluna, linha)) {
        continue;
      }
      final area = Rect.fromLTWH(
        coluna * tamanhoBloco,
        linha * tamanhoBloco,
        tamanhoBloco,
        tamanhoBloco,
      );
      if (area.overlaps(heroi.toRect())) {
        return;
      }
      var acertou = false;
      for (final inimigo in inimigos) {
        if (inimigo.vivo && inimigo.toRect().overlaps(area)) {
          inimigo.receberGolpe(Golpe.terra, deX: heroi.center.x);
          acertou = true;
        }
      }
      if (acertou) {
        Sons.tocar('terra', volume: 0.5);
        return;
      }
      if (_pedrasAtivas.length >= _maximoDePedras) {
        removerPedra(_pedrasAtivas.first);
      }
      final pedra = PedraMagica(coluna: coluna, linha: linha);
      _pedras.add((coluna, linha));
      _pedrasAtivas.add(pedra);
      add(pedra);
      return;
    }
  }

  bool golpearCelula(int coluna, int linha, Golpe golpe) {
    final bloco = _blocosDeElemento[(coluna, linha)];
    if (bloco == null) {
      return solido(coluna, linha);
    }
    if (bloco.tipo.quebraCom(golpe)) {
      _quebrarEmCadeia(coluna, linha);
    } else {
      bloco.tremer();
    }
    return true;
  }

  void _quebrarEmCadeia(int coluna, int linha) {
    final bloco = _blocosDeElemento.remove((coluna, linha));
    if (bloco == null) {
      return;
    }
    bloco.quebrar();
    for (final (dc, dl) in const [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final vizinho = _blocosDeElemento[(coluna + dc, linha + dl)];
      if (vizinho != null && vizinho.tipo == bloco.tipo) {
        add(
          TimerComponent(
            period: 0.09,
            removeOnFinish: true,
            onTick: () => _quebrarEmCadeia(coluna + dc, linha + dl),
          ),
        );
      }
    }
  }

  bool golpearPonto(double x, double y, Golpe golpe) => golpearCelula(
    (x / tamanhoBloco).floor(),
    (y / tamanhoBloco).floor(),
    golpe,
  );

  void golpearArea(Rect area, Golpe golpe) {
    final c0 = (area.left / tamanhoBloco).floor();
    final c1 = ((area.right - 0.01) / tamanhoBloco).floor();
    final l0 = (area.top / tamanhoBloco).floor();
    final l1 = ((area.bottom - 0.01) / tamanhoBloco).floor();
    for (var c = c0; c <= c1; c++) {
      for (var l = l0; l <= l1; l++) {
        if (_blocosDeElemento.containsKey((c, l))) {
          golpearCelula(c, l, golpe);
        }
      }
    }
  }

  void removerPedra(PedraMagica pedra) {
    _pedras.remove((pedra.coluna, pedra.linha));
    _pedrasAtivas.remove(pedra);
    pedra.removeFromParent();
  }

  void voltarAoPontoDeRetorno() {
    heroi.reaparecer(_posicaoDoHeroi(pontoDeRetorno));
  }
}
