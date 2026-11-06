import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'aventura_jogo.dart';
import 'heroi.dart';
import 'inimigo.dart';
import 'itens.dart';
import 'sons.dart';

const double tamanhoBloco = 18;

class ResultadoMovimento {
  bool noChao = false;
  bool bateuParede = false;
  bool bateuTeto = false;
}

class Fase extends World with HasGameReference<AventuraJogo> {
  Fase({required this.arquivo, required this.indiceHeroi});

  final String arquivo;
  final int indiceHeroi;

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
      arquivo,
      Vector2.all(tamanhoBloco),
      images: game.imagensDosBlocos,
    );
    add(mapa);

    final terreno = mapa.tileMap.getLayer<TileLayer>('terreno')!;
    colunas = terreno.width;
    linhas = terreno.height;
    final dados = terreno.tileData!;
    _solidos = [
      for (var r = 0; r < linhas; r++)
        [for (var c = 0; c < colunas; c++) dados[r][c].tile != 0],
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
        case 'inimigo':
          inimigos.add(Inimigo(posicao: pos));
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
      }
    }
    addAll([...moedas, ...inimigos, ...molas, ...checkpoints, chegada]);

    pontoDeRetorno = inicio ?? Vector2(tamanhoBloco * 2, tamanhoBloco * 8);
    heroi = Heroi(
      indiceSprite: indiceHeroi,
      posicao: _posicaoDoHeroi(pontoDeRetorno),
    );
    add(heroi);
    game.totalDeMoedas = moedas.length;
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
    return _solidos[linha][coluna];
  }

  ResultadoMovimento mover(
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
      if (!inimigo.vivo || !inimigo.toRect().deflate(2).overlaps(corpo)) {
        continue;
      }
      final pesAntes = corpo.bottom - heroi.velocidade.y * dt;
      if (heroi.velocidade.y > 0 && pesAntes <= inimigo.toRect().top + 6) {
        inimigo.esmagar();
        heroi.quicarNoInimigo();
        Sons.tocar('pisao');
      } else {
        inimigo.virarDeCostasPara(heroi.center.x);
        heroi.levarDano(origemX: inimigo.center.x);
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

  void voltarAoPontoDeRetorno() {
    heroi.reaparecer(_posicaoDoHeroi(pontoDeRetorno));
  }
}
