import 'dart:ui';

import 'package:aventura/jogo/bolha_presa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aprisionamento (inimigo ou colega dentro da bolha)', () {
    test('flutua para cima enquanto dura', () {
      final a = Aprisionamento(duracao: 3);
      final subida = a.atualizar(0.5, tetoAcima: false);
      expect(subida, greaterThan(0));
      expect(a.estourou, isFalse);
    });

    test('estoura sozinho quando o tempo acaba', () {
      final a = Aprisionamento(duracao: 3);
      for (var i = 0; i < 31; i++) {
        a.atualizar(0.1, tetoAcima: false);
      }
      expect(a.estourou, isTrue);
      expect(a.atualizar(0.1, tetoAcima: false), 0);
    });

    test('não sobe mais que o limite (~3 blocos)', () {
      final a = Aprisionamento(duracao: 30);
      var total = 0.0;
      for (var i = 0; i < 200; i++) {
        total += a.atualizar(0.1, tetoAcima: false);
      }
      expect(total, closeTo(Aprisionamento.subidaMaxima, 1e-9));
    });

    test('não sobe com teto logo acima', () {
      final a = Aprisionamento(duracao: 3);
      expect(a.atualizar(0.5, tetoAcima: true), 0);
    });

    test('estourar() termina na hora', () {
      final a = Aprisionamento(duracao: 3)..estourar();
      expect(a.estourou, isTrue);
    });
  });

  group('toque do herói na bolha', () {
    const bolha = Rect.fromLTWH(100, 100, 20, 20);

    test('caindo de cima: pisou', () {
      const corpo = Rect.fromLTWH(102, 85, 12, 16);
      expect(
        toqueNaBolha(corpo: corpo, bolha: bolha, velocidadeY: 120, dt: 1 / 60),
        ToqueNaBolha.pisou,
      );
    });

    test('de lado: encostou', () {
      const corpo = Rect.fromLTWH(92, 104, 12, 16);
      expect(
        toqueNaBolha(corpo: corpo, bolha: bolha, velocidadeY: 0, dt: 1 / 60),
        ToqueNaBolha.encostou,
      );
    });

    test('subindo por baixo: encostou', () {
      const corpo = Rect.fromLTWH(104, 115, 12, 16);
      expect(
        toqueNaBolha(corpo: corpo, bolha: bolha, velocidadeY: -200, dt: 1 / 60),
        ToqueNaBolha.encostou,
      );
    });

    test('longe: nada', () {
      const corpo = Rect.fromLTWH(10, 10, 12, 16);
      expect(
        toqueNaBolha(corpo: corpo, bolha: bolha, velocidadeY: 0, dt: 1 / 60),
        ToqueNaBolha.nada,
      );
    });
  });

  group('poderes de jogadores diferentes se anulam', () {
    const a = Rect.fromLTWH(0, 0, 10, 10);
    const perto = Rect.fromLTWH(5, 5, 10, 10);
    const longe = Rect.fromLTWH(50, 50, 10, 10);

    test('jogadores diferentes encostando: anulam', () {
      expect(deveAnular(donoA: 0, areaA: a, donoB: 1, areaB: perto), isTrue);
    });

    test('mesmo jogador: nunca anulam', () {
      expect(deveAnular(donoA: 0, areaA: a, donoB: 0, areaB: perto), isFalse);
    });

    test('longe um do outro: não anulam', () {
      expect(deveAnular(donoA: 0, areaA: a, donoB: 1, areaB: longe), isFalse);
    });
  });
}
