import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nomes passados a `Sons.tocar(...)` em todo o código do jogo.
Set<String> _sonsUsados() {
  final chamada = RegExp(r'Sons\.tocar\(([^;]*?)(?:,\s*volume|\);)');
  final texto = RegExp(r"'([a-z_]+)'");
  final nomes = <String>{};
  for (final arquivo in Directory('lib').listSync(recursive: true)) {
    if (arquivo is File && arquivo.path.endsWith('.dart')) {
      for (final c in chamada.allMatches(arquivo.readAsStringSync())) {
        nomes.addAll(texto.allMatches(c.group(1)!).map((m) => m.group(1)!));
      }
    }
  }
  return nomes;
}

void main() {
  final registro = File('lib/jogo/sons.dart').readAsStringSync();

  test('acha as chamadas de som', () {
    expect(_sonsUsados(), containsAll(['pulo', 'dano', 'espada', 'bolha']));
  });

  test('todo som tocado tem arquivo e está registrado em Sons', () {
    for (final nome in _sonsUsados()) {
      final arquivo = [
        '$nome.wav',
        '$nome.ogg',
      ].where((a) => File('assets/audio/$a').existsSync()).toList();
      expect(arquivo, hasLength(1), reason: 'arquivo de "$nome"');
      expect(
        registro.contains("'${arquivo.single}'"),
        isTrue,
        reason: '"${arquivo.single}" fora de Sons._efeitos',
      );
    }
  });
}
