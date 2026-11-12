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
}
