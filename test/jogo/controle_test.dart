// Testes de caracterização: registram o comportamento ATUAL do Controle
// antes de ele ganhar "segurar o ataque" (poderes carregados).
import 'package:aventura/jogo/controle.dart';
import 'package:aventura/jogo/entrada_de_controles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _tempo = Duration.zero;

KeyDownEvent _desce(LogicalKeyboardKey tecla) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: tecla,
  timeStamp: _tempo,
);

KeyRepeatEvent _repete(LogicalKeyboardKey tecla) => KeyRepeatEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: tecla,
  timeStamp: _tempo,
);

KeyUpEvent _sobe(LogicalKeyboardKey tecla) => KeyUpEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: tecla,
  timeStamp: _tempo,
);

EventoDeControle _nativo(Acao acao, bool apertou) =>
    EventoDeControle.tecla(origem: 'c1', acao: acao, apertou: apertou);

EventoDeControle _eixo(double x, double y) =>
    EventoDeControle.eixo(origem: 'c1', x: x, y: y);

void main() {
  late Controle c;
  setUp(() => c = Controle());

  test('começa tudo solto e sem pedidos', () {
    expect(c.esquerda, isFalse);
    expect(c.direita, isFalse);
    expect(c.seguraPulo, isFalse);
    expect(c.consumirPedidoDePulo(), isFalse);
    expect(c.consumirPedidoDeAtaque(), isFalse);
  });

  group('teclado', () {
    test('setas e WASD movem enquanto apertadas', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.arrowLeft), {
        LogicalKeyboardKey.arrowLeft,
      });
      expect(c.esquerda, isTrue);
      c.atualizarTeclado(_sobe(LogicalKeyboardKey.arrowLeft), {});
      expect(c.esquerda, isFalse);

      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyD), {
        LogicalKeyboardKey.keyD,
      });
      expect(c.direita, isTrue);
    });

    test('ataque gera um pedido por aperto, consumido uma vez', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
        LogicalKeyboardKey.keyX,
      });
      expect(c.consumirPedidoDeAtaque(), isTrue);
      expect(c.consumirPedidoDeAtaque(), isFalse);
    });

    test('segurar o ataque (repetição) não gera novo pedido', () {
      final apertadas = {LogicalKeyboardKey.keyX};
      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), apertadas);
      c.consumirPedidoDeAtaque();
      c.atualizarTeclado(_repete(LogicalKeyboardKey.keyX), apertadas);
      expect(c.consumirPedidoDeAtaque(), isFalse);
    });

    test(
      'segunda tecla de ataque com a primeira segurada não pede de novo',
      () {
        c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
          LogicalKeyboardKey.keyX,
        });
        c.consumirPedidoDeAtaque();
        c.atualizarTeclado(_desce(LogicalKeyboardKey.keyJ), {
          LogicalKeyboardKey.keyX,
          LogicalKeyboardKey.keyJ,
        });
        expect(c.consumirPedidoDeAtaque(), isFalse);
      },
    );

    test('soltar e apertar de novo gera novo pedido', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
        LogicalKeyboardKey.keyX,
      });
      c.consumirPedidoDeAtaque();
      c.atualizarTeclado(_sobe(LogicalKeyboardKey.keyX), {});
      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
        LogicalKeyboardKey.keyX,
      });
      expect(c.consumirPedidoDeAtaque(), isTrue);
    });

    test('pulo: pedido no aperto e seguraPulo enquanto apertado', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.space), {
        LogicalKeyboardKey.space,
      });
      expect(c.seguraPulo, isTrue);
      expect(c.consumirPedidoDePulo(), isTrue);
      c.atualizarTeclado(_sobe(LogicalKeyboardKey.space), {});
      expect(c.seguraPulo, isFalse);
      expect(c.consumirPedidoDePulo(), isFalse);
    });

    test('seta para baixo é ataque e seta para cima é pulo', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.arrowDown), {
        LogicalKeyboardKey.arrowDown,
      });
      expect(c.consumirPedidoDeAtaque(), isTrue);
      c.atualizarTeclado(_desce(LogicalKeyboardKey.arrowUp), {
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
      });
      expect(c.consumirPedidoDePulo(), isTrue);
    });

    test('ehTeclaDoJogo reconhece as teclas e ignora as outras', () {
      for (final tecla in [
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.gameButtonB,
      ]) {
        expect(c.ehTeclaDoJogo(tecla), isTrue, reason: '$tecla');
      }
      expect(c.ehTeclaDoJogo(LogicalKeyboardKey.keyQ), isFalse);
    });
  });

  group('toque', () {
    test('ataque pede a cada toqueAtaque(true), mesmo sem soltar', () {
      c.toqueAtaque(true);
      expect(c.consumirPedidoDeAtaque(), isTrue);
      c.toqueAtaque(true);
      expect(c.consumirPedidoDeAtaque(), isTrue);
    });

    test('soltar o ataque de toque não faz nada', () {
      c.toqueAtaque(false);
      expect(c.consumirPedidoDeAtaque(), isFalse);
    });

    test('pulo de toque só pede na borda (apertou depois de solto)', () {
      c.toquePulo(true);
      expect(c.consumirPedidoDePulo(), isTrue);
      c.toquePulo(true);
      expect(c.consumirPedidoDePulo(), isFalse);
      expect(c.seguraPulo, isTrue);
      c.toquePulo(false);
      expect(c.seguraPulo, isFalse);
    });

    test('esquerda e direita de toque são campos públicos', () {
      c.toqueEsquerda = true;
      expect(c.esquerda, isTrue);
      c.toqueDireita = true;
      expect(c.direita, isTrue);
    });
  });

  group('controle nativo (modo dupla)', () {
    test('ataque pede só na borda', () {
      c.receberNativo(_nativo(Acao.ataque, true));
      expect(c.consumirPedidoDeAtaque(), isTrue);
      c.receberNativo(_nativo(Acao.ataque, true));
      expect(c.consumirPedidoDeAtaque(), isFalse);
      c.receberNativo(_nativo(Acao.ataque, false));
      c.receberNativo(_nativo(Acao.ataque, true));
      expect(c.consumirPedidoDeAtaque(), isTrue);
    });

    test('movimento e pulo seguem apertou/soltou', () {
      c.receberNativo(_nativo(Acao.esquerda, true));
      expect(c.esquerda, isTrue);
      c.receberNativo(_nativo(Acao.esquerda, false));
      expect(c.esquerda, isFalse);
      c.receberNativo(_nativo(Acao.pulo, true));
      expect(c.seguraPulo, isTrue);
      expect(c.consumirPedidoDePulo(), isTrue);
    });

    test('eixo: x move, y para cima pula e y para baixo ataca na borda', () {
      c.receberNativo(_eixo(-0.8, 0));
      expect(c.esquerda, isTrue);
      c.receberNativo(_eixo(0, 0.9));
      expect(c.consumirPedidoDeAtaque(), isTrue);
      c.receberNativo(_eixo(0, 0.95));
      expect(c.consumirPedidoDeAtaque(), isFalse);
      c.receberNativo(_eixo(0, -0.9));
      expect(c.consumirPedidoDePulo(), isTrue);
      expect(c.seguraPulo, isTrue);
    });

    test('eixo no limite exato de 0,5 não conta', () {
      c.receberNativo(_eixo(0.5, 0.5));
      expect(c.direita, isFalse);
      expect(c.consumirPedidoDeAtaque(), isFalse);
    });
  });

  test('soltarTudo zera movimento, pulo e pedidos', () {
    c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.arrowLeft,
    });
    c.toquePulo(true);
    c.toqueDireita = true;
    c.receberNativo(_eixo(0.9, 0));
    c.soltarTudo();
    expect(c.esquerda, isFalse);
    expect(c.direita, isFalse);
    expect(c.seguraPulo, isFalse);
    expect(c.consumirPedidoDeAtaque(), isFalse);
    expect(c.consumirPedidoDePulo(), isFalse);
  });

  test('depois do soltarTudo, a tecla ainda apertada não pede ataque de novo '
      'até soltar', () {
    final apertadas = {LogicalKeyboardKey.keyX};
    c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), apertadas);
    c.soltarTudo();
    c.atualizarTeclado(_repete(LogicalKeyboardKey.keyX), apertadas);
    expect(c.consumirPedidoDeAtaque(), isFalse);
  });

  group('segurar o ataque (poderes carregados)', () {
    test('teclado: segura enquanto a tecla está apertada', () {
      c.atualizarTeclado(_desce(LogicalKeyboardKey.keyX), {
        LogicalKeyboardKey.keyX,
      });
      expect(c.seguraAtaque, isTrue);
      c.atualizarTeclado(_sobe(LogicalKeyboardKey.keyX), {});
      expect(c.seguraAtaque, isFalse);
    });

    test('toque: segura entre apertar e soltar o botão', () {
      c.toqueAtaque(true);
      expect(c.seguraAtaque, isTrue);
      c.toqueAtaque(false);
      expect(c.seguraAtaque, isFalse);
    });

    test('controle nativo: segura entre apertou e soltou', () {
      c.receberNativo(_nativo(Acao.ataque, true));
      expect(c.seguraAtaque, isTrue);
      c.receberNativo(_nativo(Acao.ataque, false));
      expect(c.seguraAtaque, isFalse);
    });

    test('eixo para baixo segura', () {
      c.receberNativo(_eixo(0, 0.9));
      expect(c.seguraAtaque, isTrue);
      c.receberNativo(_eixo(0, 0));
      expect(c.seguraAtaque, isFalse);
    });

    test('soltarTudo solta o ataque e cancela a carga', () {
      c.toqueAtaque(true);
      for (var i = 0; i < 90; i++) {
        c.carga.atualizar(1 / 60, segurando: c.seguraAtaque);
      }
      c.soltarTudo();
      expect(c.seguraAtaque, isFalse);
      expect(c.carga.nivel, 0);
      expect(c.carga.atualizar(1 / 60, segurando: c.seguraAtaque), isNull);
    });

    test('dois controles carregam de forma independente', () {
      final outro = Controle();
      c.toqueAtaque(true);
      for (var i = 0; i < 90; i++) {
        c.carga.atualizar(1 / 60, segurando: c.seguraAtaque);
        outro.carga.atualizar(1 / 60, segurando: outro.seguraAtaque);
      }
      expect(c.carga.nivel, 3);
      expect(outro.carga.nivel, 0);
    });
  });
}
