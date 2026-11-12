import 'dart:math';
import 'dart:ui';

/// Tempo dentro da bolha da Maga da Água: quem está preso (inimigo ou o
/// colega) flutua para cima devagar, até um limite, e a bolha estoura
/// sozinha quando o tempo acaba.
class Aprisionamento {
  Aprisionamento({required this.duracao});

  static const subidaMaxima = 48.0; // ~3 blocos
  static const _velocidade = 22.0;

  final double duracao;
  double _tempo = 0;
  double _subido = 0;
  bool _estourou = false;

  bool get estourou => _estourou;
  double get restante => max(0, duracao - _tempo);

  /// Avança o tempo e devolve quanto subir neste quadro.
  double atualizar(double dt, {required bool tetoAcima}) {
    if (_estourou) {
      return 0;
    }
    _tempo += dt;
    if (_tempo >= duracao) {
      _estourou = true;
      return 0;
    }
    if (tetoAcima || _subido >= subidaMaxima) {
      return 0;
    }
    final passo = min(_velocidade * dt, subidaMaxima - _subido);
    _subido += passo;
    return passo;
  }

  void estourar() => _estourou = true;
}

enum ToqueNaBolha { nada, pisou, encostou }

/// Pular em cima (caindo, com os pés vindo de cima) é "pisou": estoura e o
/// herói quica. Qualquer outro contato é "encostou": só estoura.
ToqueNaBolha toqueNaBolha({
  required Rect corpo,
  required Rect bolha,
  required double velocidadeY,
  required double dt,
}) {
  if (!corpo.overlaps(bolha)) {
    return ToqueNaBolha.nada;
  }
  final pesAntes = corpo.bottom - velocidadeY * dt;
  if (velocidadeY > 0 && pesAntes <= bolha.top + 6) {
    return ToqueNaBolha.pisou;
  }
  return ToqueNaBolha.encostou;
}

/// Poderes de jogadores diferentes que se encostam se anulam (os dois somem).
bool deveAnular({
  required int donoA,
  required Rect areaA,
  required int donoB,
  required Rect areaB,
}) => donoA != donoB && areaA.overlaps(areaB);
