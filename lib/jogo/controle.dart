import 'package:flutter/services.dart';

import 'carga.dart';
import 'entrada_de_controles.dart';

class Controle {
  bool _teclaEsquerda = false;
  bool _teclaDireita = false;
  bool _teclaPulo = false;
  bool _teclaAtaque = false;

  bool toqueEsquerda = false;
  bool toqueDireita = false;
  bool _toquePulo = false;
  bool _toqueAtaque = false;

  /// Carga do poder deste jogador (cada controle tem a sua).
  final Carga carga = Carga();

  bool _pediuPulo = false;
  bool _pediuAtaque = false;

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
  };
  static final _ataque = {
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyJ,
    LogicalKeyboardKey.gameButtonB,
    LogicalKeyboardKey.gameButtonX,
    LogicalKeyboardKey.gameButtonY,
  };

  bool _nativoEsquerda = false;
  bool _nativoDireita = false;
  bool _nativoPulo = false;
  bool _nativoAtaque = false;
  double _eixoX = 0;
  double _eixoY = 0;

  bool get esquerda =>
      _teclaEsquerda || toqueEsquerda || _nativoEsquerda || _eixoX < -0.5;
  bool get direita =>
      _teclaDireita || toqueDireita || _nativoDireita || _eixoX > 0.5;
  bool get seguraPulo =>
      _teclaPulo || _toquePulo || _nativoPulo || _eixoY < -0.5;
  bool get seguraAtaque =>
      _teclaAtaque || _toqueAtaque || _nativoAtaque || _eixoY > 0.5;

  bool consumirPedidoDePulo() {
    final pediu = _pediuPulo;
    _pediuPulo = false;
    return pediu;
  }

  bool consumirPedidoDeAtaque() {
    final pediu = _pediuAtaque;
    _pediuAtaque = false;
    return pediu;
  }

  bool ehTeclaDoJogo(LogicalKeyboardKey tecla) =>
      _esquerda.contains(tecla) ||
      _direita.contains(tecla) ||
      _pulo.contains(tecla) ||
      _ataque.contains(tecla);

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
    final ataqueAntes = _teclaAtaque;
    _teclaAtaque = apertadas.any(_ataque.contains);
    if (evento is KeyDownEvent &&
        _ataque.contains(evento.logicalKey) &&
        !ataqueAntes) {
      _pediuAtaque = true;
    }
  }

  void toquePulo(bool apertado) {
    if (apertado && !_toquePulo) {
      _pediuPulo = true;
    }
    _toquePulo = apertado;
  }

  void toqueAtaque(bool apertado) {
    if (apertado) {
      _pediuAtaque = true;
    }
    _toqueAtaque = apertado;
  }

  void receberNativo(EventoDeControle evento) {
    if (evento.eixo) {
      if (evento.y < -0.5 && _eixoY >= -0.5) {
        _pediuPulo = true;
      }
      if (evento.y > 0.5 && _eixoY <= 0.5) {
        _pediuAtaque = true;
      }
      _eixoX = evento.x;
      _eixoY = evento.y;
      return;
    }
    final apertou = evento.apertou;
    switch (evento.acao) {
      case Acao.esquerda:
        _nativoEsquerda = apertou;
      case Acao.direita:
        _nativoDireita = apertou;
      case Acao.pulo:
        if (apertou && !_nativoPulo) {
          _pediuPulo = true;
        }
        _nativoPulo = apertou;
      case Acao.ataque:
        if (apertou && !_nativoAtaque) {
          _pediuAtaque = true;
        }
        _nativoAtaque = apertou;
      case null:
        break;
    }
  }

  void soltarTudo() {
    _nativoEsquerda = false;
    _nativoDireita = false;
    _nativoPulo = false;
    _nativoAtaque = false;
    _eixoX = 0;
    _eixoY = 0;
    _teclaAtaque = false;
    _pediuAtaque = false;
    _teclaEsquerda = false;
    _teclaDireita = false;
    _teclaPulo = false;
    toqueEsquerda = false;
    toqueDireita = false;
    _toquePulo = false;
    _toqueAtaque = false;
    _pediuPulo = false;
    carga.cancelar();
  }
}
