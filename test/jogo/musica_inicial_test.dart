import 'package:aventura/jogo/progresso.dart';
import 'package:aventura/jogo/sons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('o jogo sempre abre com as duas músicas ligadas', () async {
    // Escolha antiga de versões anteriores que salvavam "desligada".
    SharedPreferences.setMockInitialValues({'musica_ligada': false});
    await Progresso.carregar();
    expect(Sons.musicaDoMenuLigada.value, isTrue);
    expect(Sons.musicaDaFaseLigada.value, isTrue);
  });
}
