import 'package:flutter/services.dart';

class Controle {
  bool _teclaEsquerda = false;
  bool _teclaDireita = false;
  bool _teclaPulo = false;

  bool toqueEsquerda = false;
  bool toqueDireita = false;
  bool _toquePulo = false;

  bool _pediuPulo = false;

  static final _esquerda = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.keyA,
  };
  static final _direita = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final _pulo = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
    LogicalKeyboardKey.gameButtonB,
  };

  bool get esquerda => _teclaEsquerda || toqueEsquerda;
  bool get direita => _teclaDireita || toqueDireita;
  bool get seguraPulo => _teclaPulo || _toquePulo;

  bool consumirPedidoDePulo() {
    final pediu = _pediuPulo;
    _pediuPulo = false;
    return pediu;
  }

  bool ehTeclaDoJogo(LogicalKeyboardKey tecla) =>
      _esquerda.contains(tecla) ||
      _direita.contains(tecla) ||
      _pulo.contains(tecla);

  void atualizarTeclado(KeyEvent evento, Set<LogicalKeyboardKey> apertadas) {
    _teclaEsquerda = apertadas.any(_esquerda.contains);
    _teclaDireita = apertadas.any(_direita.contains);
    final puloAntes = _teclaPulo;
    _teclaPulo = apertadas.any(_pulo.contains);
    if (evento is KeyDownEvent &&
        _pulo.contains(evento.logicalKey) &&
        !puloAntes) {
      _pediuPulo = true;
    }
  }

  void toquePulo(bool apertado) {
    if (apertado && !_toquePulo) {
      _pediuPulo = true;
    }
    _toquePulo = apertado;
  }

  void soltarTudo() {
    _teclaEsquerda = false;
    _teclaDireita = false;
    _teclaPulo = false;
    toqueEsquerda = false;
    toqueDireita = false;
    _toquePulo = false;
    _pediuPulo = false;
  }
}
