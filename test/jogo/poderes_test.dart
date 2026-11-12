import 'package:aventura/jogo/classes.dart';
import 'package:aventura/jogo/obstaculos.dart';
import 'package:aventura/jogo/poderes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('espada arremessada (golpe carregado do Guerreiro)', () {
    test('sem carga a espada tem o tamanho normal', () {
      final t = tamanhoDaEspada(1);
      expect(t.x, 18);
      expect(t.y, 18);
    });

    test('carregada cresce mais no comprimento do que na largura', () {
      final t = tamanhoDaEspada(2.5);
      expect(t.y, closeTo(50.4, 1e-4));
      expect(t.x, closeTo(23.4, 1e-4));
      expect(t.y, greaterThan(t.x * 2));
    });

    test('vai mais longe quanto maior a carga', () {
      expect(alcanceDoArremesso(1.5), 240);
      expect(alcanceDoArremesso(2.5), 400);
    });
  });

  group('broca de terra (golpe carregado da Maga da Terra)', () {
    test('vai mais longe quanto maior a carga', () {
      expect(alcanceDaBroca(1.5), 210);
      expect(alcanceDaBroca(2.5), 350);
    });

    test('rachadura quebra com terra (a broca perfura)', () {
      expect(TipoDeObstaculo.rachada.quebraCom(Golpe.terra), isTrue);
    });

    test('gelo continua só com fogo', () {
      expect(TipoDeObstaculo.gelo.quebraCom(Golpe.terra), isFalse);
      expect(TipoDeObstaculo.gelo.quebraCom(Golpe.fogo), isTrue);
    });
  });

  group('bola de fogo carregada', () {
    test('sem carga não explode em área', () {
      expect(raioDaExplosao(1), 0);
    });

    test('a explosão cresce com a carga', () {
      expect(raioDaExplosao(1.5), 21);
      expect(raioDaExplosao(2.5), 35);
    });
  });
}
