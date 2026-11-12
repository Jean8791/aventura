import 'dart:math';

/// Carga do poder: quanto mais tempo o ataque fica segurado, maior o poder
/// disparado ao soltar. O toque rápido (abaixo de 0,4 s) não dispara nada ao
/// soltar: o poder normal já saiu no aperto.
class Carga {
  static const nivelMaximo = 3;
  static const _segundosPorNivel = 0.4;

  /// Nível (0 a 3) para o tempo segurado: 0,4 s, 0,8 s e 1,2 s.
  static int nivelPara(double segundos) =>
      min(nivelMaximo, (segundos / _segundosPorNivel + 1e-9).floor());

  /// Tamanho do poder: 1,5×, 2× e 2,5× (limite).
  static double escalaDo(int nivel) => 1 + 0.5 * min(nivel, nivelMaximo);

  /// Tamanho da prévia na mão, crescendo suave com o tempo (até 2,5×).
  static double escalaContinua(double segundos) =>
      1 + 0.5 * min(nivelMaximo.toDouble(), segundos / _segundosPorNivel);

  /// Quantas vezes o golpe carregado vale: 1 normal, 2/3/4 carregado.
  static int forcaDo(int nivel) => 1 + min(nivel, nivelMaximo);

  double _tempo = 0;
  bool _segurando = false;

  /// Nível atual enquanto segura (0 quando solto).
  int get nivel => _segurando ? nivelPara(_tempo) : 0;

  /// Tempo segurando (0 quando solto).
  double get segundos => _segurando ? _tempo : 0;

  /// Chamar a cada quadro. Devolve o nível a disparar no quadro em que o
  /// ataque é solto (se chegou ao nível 1); senão, null.
  int? atualizar(double dt, {required bool segurando}) {
    if (segurando) {
      _tempo = _segurando ? _tempo + dt : 0;
      _segurando = true;
      return null;
    }
    if (!_segurando) {
      return null;
    }
    final disparo = nivelPara(_tempo);
    cancelar();
    return disparo > 0 ? disparo : null;
  }

  /// Zera sem disparar (pausa, menu, herói desmaiado).
  void cancelar() {
    _segurando = false;
    _tempo = 0;
  }
}
