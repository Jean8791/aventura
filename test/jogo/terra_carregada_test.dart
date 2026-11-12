import 'package:aventura/jogo/aventura_jogo.dart';
import 'package:aventura/jogo/classes.dart';
import 'package:aventura/jogo/fase.dart';
import 'package:aventura/jogo/fases.dart';
import 'package:aventura/jogo/poderes.dart';
import 'package:aventura/jogo/progresso.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _JogoDeTeste extends AventuraJogo {
  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'blocos.png',
      'diamante.png',
      'obstaculos_gelo.png',
      'obstaculos_rachada.png',
      for (final classe in classes) classe.imagem,
      'inimigos/slime.png',
      'inimigos/slime_fogo.png',
      'inimigos/morcego.png',
      'inimigos/golem.png',
      'poderes/pedra.png',
    ]);
    fase = Fase(
      dados: fases.first,
      classes: [classes.firstWhere((c) => c.poder == Golpe.terra)],
      numero: 0,
    );
    world = fase!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _JogoDeTeste jogo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progresso.carregar();
    jogo = _JogoDeTeste()..onGameResize(Vector2(800, 600));
  });

  Future<void> preparar(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(GameWidget(game: jogo));
      await jogo.toBeLoaded();
    });
    await tester.pump();
    await tester.runAsync(jogo.ready);
  }

  for (final direcao in [-1.0, 1.0]) {
    testWidgets('a broca substitui o bloco na direção $direcao', (
      tester,
    ) async {
      await preparar(tester);
      final fase = jogo.fase!;
      final heroi = fase.heroi
        ..position = Vector2(180, 80)
        ..direcao = direcao;
      heroi.controle.toqueAtaque(true);
      heroi.update(0);
      await tester.runAsync(jogo.ready);
      final pedra = fase.children.whereType<PedraMagica>().single;
      final origem = pedra.center.clone();
      expect(fase.solido(pedra.coluna, pedra.linha), isTrue);
      heroi.controle.carga.atualizar(0.8, segurando: true);
      heroi.controle.toqueAtaque(false);
      heroi.update(0);
      await tester.runAsync(jogo.ready);
      final broca = fase.children.whereType<BrocaDeTerra>().single;
      expect(broca.position, origem);
      expect(broca.direcao, direcao);
      expect(fase.children.whereType<PedraMagica>(), isEmpty);
      expect(fase.solido(pedra.coluna, pedra.linha), isFalse);
    });
  }
  testWidgets('toque rápido mantém o bloco e não lança broca', (tester) async {
    await preparar(tester);
    final fase = jogo.fase!;
    final heroi = fase.heroi..position = Vector2(180, 80);
    heroi.controle.toqueAtaque(true);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    heroi.controle.toqueAtaque(false);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    expect(fase.children.whereType<PedraMagica>(), hasLength(1));
    expect(fase.children.whereType<BrocaDeTerra>(), isEmpty);
  });

  testWidgets('bloco removido durante a carga faz a broca sair da mão', (
    tester,
  ) async {
    await preparar(tester);
    final fase = jogo.fase!;
    final heroi = fase.heroi..position = Vector2(180, 80);
    heroi.controle.toqueAtaque(true);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    fase.removerPedra(fase.children.whereType<PedraMagica>().single);
    heroi.controle.carga.atualizar(0.8, segurando: true);
    heroi.controle.toqueAtaque(false);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    expect(
      fase.children.whereType<BrocaDeTerra>().single.position,
      Vector2(heroi.center.x + 8, heroi.position.y + 7),
    );
  });

  testWidgets('a prévia acompanha o bloco e cancelar mantém a pedra', (
    tester,
  ) async {
    await preparar(tester);
    final fase = jogo.fase!;
    final heroi = fase.heroi..position = Vector2(180, 80);
    heroi.controle.toqueAtaque(true);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    final pedra = fase.children.whereType<PedraMagica>().single;
    heroi.controle.carga.atualizar(0.8, segurando: true);
    heroi.position.x -= 20;
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    final previa = heroi.children.whereType<PreviaDaCarga>().single;
    expect(previa.position + heroi.position, pedra.center - Vector2(4.5, 0));
    heroi.congelar();
    heroi.controle.toqueAtaque(false);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    expect(fase.children.whereType<PedraMagica>(), contains(pedra));
    expect(fase.children.whereType<BrocaDeTerra>(), isEmpty);
    expect(heroi.children.whereType<PreviaDaCarga>(), isEmpty);
  });
  testWidgets('broca máxima avança sobre o chão sem desaparecer', (
    tester,
  ) async {
    await preparar(tester);
    final fase = jogo.fase!;
    final coluna = 10;
    final linhaDoChao = List.generate(fase.linhas, (i) => i).firstWhere(
      (linha) => fase.solido(coluna, linha) && fase.solido(coluna + 1, linha),
    );
    final heroi = fase.heroi
      ..position = Vector2(
        coluna * tamanhoBloco,
        linhaDoChao * tamanhoBloco - 16,
      );
    heroi.controle.toqueAtaque(true);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    heroi.controle.carga.atualizar(1.2, segurando: true);
    heroi.controle.toqueAtaque(false);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    final broca = fase.children.whereType<BrocaDeTerra>().single;
    expect(broca.escala, 2.5);
    final inicio = broca.position.x;
    for (var i = 0; i < 6; i++) {
      broca.update(1 / 60);
    }
    expect(broca.isRemoving, isFalse);
    expect(broca.position.x, greaterThan(inicio + 20));
  });
  testWidgets('carga com pedra anterior consome apenas a pedra nova', (
    tester,
  ) async {
    await preparar(tester);
    final fase = jogo.fase!;
    final heroi = fase.heroi..position = Vector2(180, 80);
    fase.criarPedraNaFrente(heroi);
    await tester.runAsync(jogo.ready);
    final anterior = fase.children.whereType<PedraMagica>().single;
    heroi.controle.toqueAtaque(true);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    expect(fase.children.whereType<PedraMagica>(), hasLength(2));
    heroi.controle.carga.atualizar(1.2, segurando: true);
    heroi.controle.toqueAtaque(false);
    heroi.update(0);
    await tester.runAsync(jogo.ready);
    expect(fase.children.whereType<PedraMagica>().single, same(anterior));
    expect(fase.children.whereType<BrocaDeTerra>(), hasLength(1));
  });

  group('bloco de terra no ar', () {
    (int, int) chaoLivre(Fase fase) {
      for (var coluna = 6; coluna < fase.colunas - 2; coluna++) {
        for (var linha = 4; linha < fase.linhas; linha++) {
          final livreAcima = List.generate(
            4,
            (i) => !fase.solido(coluna, linha - 1 - i),
          ).every((livre) => livre);
          if (fase.solido(coluna, linha) && livreAcima) {
            return (coluna, linha);
          }
        }
      }
      throw StateError('sem chão livre na fase de teste');
    }

    testWidgets('no ar, o bloco aparece embaixo dos pés', (tester) async {
      await preparar(tester);
      final fase = jogo.fase!;
      final (coluna, chao) = chaoLivre(fase);
      final heroi = fase.heroi
        ..noChao = false
        ..position = Vector2(
          coluna * tamanhoBloco + 3,
          (chao - 3) * tamanhoBloco - 16 - 4,
        );
      final pedra = fase.criarPedraNaFrente(heroi)!;
      expect(pedra.coluna, coluna);
      expect(
        pedra.linha * tamanhoBloco,
        greaterThanOrEqualTo(heroi.toRect().bottom),
      );
      expect(pedra.linha, lessThan(chao));
    });

    testWidgets('no chão, o bloco continua aparecendo na frente', (
      tester,
    ) async {
      await preparar(tester);
      final fase = jogo.fase!;
      final (coluna, chao) = chaoLivre(fase);
      final heroi = fase.heroi
        ..noChao = true
        ..direcao = 1
        ..position = Vector2(
          coluna * tamanhoBloco + 3,
          chao * tamanhoBloco - 16,
        );
      final pedra = fase.criarPedraNaFrente(heroi)!;
      expect(pedra.coluna, greaterThan(coluna));
      expect(pedra.linha, chao - 1);
    });

    testWidgets('no ar logo acima do chão, cria na frente', (tester) async {
      await preparar(tester);
      final fase = jogo.fase!;
      final (coluna, chao) = chaoLivre(fase);
      final heroi = fase.heroi
        ..noChao = false
        ..direcao = 1
        ..position = Vector2(
          coluna * tamanhoBloco + 3,
          chao * tamanhoBloco - 16 - 1,
        );
      final pedra = fase.criarPedraNaFrente(heroi)!;
      expect(pedra.coluna, greaterThan(coluna));
    });
  });
}
