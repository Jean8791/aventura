import 'package:aventura/jogo/carga.dart';
import 'package:flutter_test/flutter_test.dart';

/// Segura por [segundos] em passos de 1/60 s e solta; devolve o que disparou.
int? _segurarESoltar(Carga carga, double segundos) {
  const passo = 1 / 60;
  for (var t = 0.0; t < segundos; t += passo) {
    expect(carga.atualizar(passo, segurando: true), isNull);
  }
  return carga.atualizar(passo, segurando: false);
}

void main() {
  group('nível pelo tempo segurado', () {
    test('abaixo de 0,4 s é toque rápido (nível 0)', () {
      expect(Carga.nivelPara(0), 0);
      expect(Carga.nivelPara(0.39), 0);
    });

    test('0,4 s, 0,8 s e 1,2 s viram níveis 1, 2 e 3', () {
      expect(Carga.nivelPara(0.4), 1);
      expect(Carga.nivelPara(0.79), 1);
      expect(Carga.nivelPara(0.8), 2);
      expect(Carga.nivelPara(1.2), 3);
    });

    test('nunca passa do nível 3', () {
      expect(Carga.nivelPara(5), 3);
    });
  });

  group('escala do poder', () {
    test('1, 1,5, 2 e 2,5 vezes', () {
      expect(Carga.escalaDo(0), 1);
      expect(Carga.escalaDo(1), 1.5);
      expect(Carga.escalaDo(2), 2);
      expect(Carga.escalaDo(3), 2.5);
    });

    test('limite de 2,5 vezes', () {
      expect(Carga.escalaDo(9), 2.5);
    });
  });

  group('segurar e soltar', () {
    test('toque rápido não dispara nada ao soltar', () {
      expect(_segurarESoltar(Carga(), 0.2), isNull);
    });

    test('soltar depois de 0,5 s dispara nível 1', () {
      expect(_segurarESoltar(Carga(), 0.5), 1);
    });

    test('soltar depois de 1 s dispara nível 2', () {
      expect(_segurarESoltar(Carga(), 1.0), 2);
    });

    test('segurar 5 s dispara nível 3', () {
      expect(_segurarESoltar(Carga(), 5), 3);
    });

    test('nível atual sobe enquanto segura e zera ao soltar', () {
      final carga = Carga();
      expect(carga.nivel, 0);
      _segurarESoltar(carga, 0.0);
      for (var i = 0; i < 60; i++) {
        carga.atualizar(1 / 60, segurando: true);
      }
      expect(carga.nivel, 2);
      carga.atualizar(1 / 60, segurando: false);
      expect(carga.nivel, 0);
    });

    test('solto sem ter segurado não dispara', () {
      expect(Carga().atualizar(1 / 60, segurando: false), isNull);
    });

    test('cancelar (pausa/menu) zera e não dispara ao soltar', () {
      final carga = Carga();
      for (var i = 0; i < 90; i++) {
        carga.atualizar(1 / 60, segurando: true);
      }
      carga.cancelar();
      expect(carga.nivel, 0);
      expect(carga.atualizar(1 / 60, segurando: false), isNull);
    });

    test('dá para carregar de novo depois de disparar', () {
      final carga = Carga();
      expect(_segurarESoltar(carga, 0.5), 1);
      expect(_segurarESoltar(carga, 1.3), 3);
    });
  });

  group('crescimento contínuo (prévia na mão)', () {
    test('escala cresce suave com o tempo até 2,5', () {
      expect(Carga.escalaContinua(0), 1);
      expect(Carga.escalaContinua(0.2), closeTo(1.25, 1e-9));
      expect(Carga.escalaContinua(0.6), closeTo(1.75, 1e-9));
      expect(Carga.escalaContinua(1.2), 2.5);
      expect(Carga.escalaContinua(9), 2.5);
    });

    test('segundos conta enquanto segura e zera ao soltar', () {
      final carga = Carga();
      expect(carga.segundos, 0);
      for (var i = 0; i < 31; i++) {
        carga.atualizar(1 / 60, segurando: true);
      }
      expect(carga.segundos, closeTo(0.5, 1e-9));
      carga.atualizar(1 / 60, segurando: false);
      expect(carga.segundos, 0);
    });
  });

  group('força do golpe carregado', () {
    test('nível 0 tem força 1 e cada nível soma 1', () {
      expect(Carga.forcaDo(0), 1);
      expect(Carga.forcaDo(1), 2);
      expect(Carga.forcaDo(3), 4);
    });
  });
}
