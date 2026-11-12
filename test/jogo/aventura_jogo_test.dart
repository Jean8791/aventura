import 'package:aventura/jogo/aventura_jogo.dart';
import 'package:aventura/jogo/classes.dart';
import 'package:aventura/jogo/fase.dart';
import 'package:aventura/jogo/fases.dart';
import 'package:aventura/jogo/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AventuraJogo _jogoNaFase(int indice) => AventuraJogo()
  ..faseAtual = indice
  ..fase = Fase(dados: fases[indice], classes: [classes[0]], numero: indice);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progresso.carregar();
  });

  test('vencer a fase do chefe abre os créditos', () {
    final chefe = fases.indexWhere((f) => f.chefe);
    expect(_jogoNaFase(chefe).overlayDoFim, AventuraJogo.overlayCreditos);
  });

  test('vencer uma fase comum abre a tela de vitória', () {
    for (var i = 0; i < fases.length; i++) {
      if (!fases[i].chefe) {
        expect(_jogoNaFase(i).overlayDoFim, AventuraJogo.overlayVitoria);
      }
    }
  });
}
