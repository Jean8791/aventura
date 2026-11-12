import 'dart:io';

import 'package:aventura/jogo/fases.dart';
import 'package:aventura/jogo/sons.dart';
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
        '$nome.mp3',
      ].where((a) => File('assets/audio/$a').existsSync()).toList();
      expect(arquivo, hasLength(1), reason: 'arquivo de "$nome"');
      expect(
        registro.contains("'${arquivo.single}'"),
        isTrue,
        reason: '"${arquivo.single}" fora de Sons._efeitos',
      );
    }
  });

  test('toda fase tem música e som de fundo com arquivo', () {
    for (final fase in fases) {
      expect(
        File('assets/audio/${fase.musica}').existsSync(),
        isTrue,
        reason: 'música de ${fase.nome}',
      );
      expect(
        File('assets/audio/${fase.ambiente}').existsSync(),
        isTrue,
        reason: 'som de fundo de ${fase.nome}',
      );
    }
  });

  test('cada fase tem música própria', () {
    expect(fases.map((f) => f.musica).toSet(), hasLength(fases.length));
  });

  group('qual chave vale', () {
    setUp(() {
      Sons.musicaDoMenuLigada.value = true;
      Sons.musicaDaFaseLigada.value = true;
    });

    test('música de menu segue a chave dos menus', () {
      Sons.musicaDaFaseLigada.value = false;
      expect(Sons.ligadaPara(menu: true), isTrue);
      Sons.musicaDoMenuLigada.value = false;
      expect(Sons.ligadaPara(menu: true), isFalse);
    });

    test('música de fase segue a chave das fases', () {
      Sons.musicaDoMenuLigada.value = false;
      expect(Sons.ligadaPara(menu: false), isTrue);
      Sons.musicaDaFaseLigada.value = false;
      expect(Sons.ligadaPara(menu: false), isFalse);
    });
  });

  group('faixa de fundo', () {
    test('música ligada toca a música', () {
      expect(Sons.faixaDeFundo(true, 'm.ogg', 'a.ogg'), 'm.ogg');
    });

    test('música desligada toca o som de fundo', () {
      expect(Sons.faixaDeFundo(false, 'm.ogg', 'a.ogg'), 'a.ogg');
    });

    test('música desligada sem som de fundo fica em silêncio', () {
      expect(Sons.faixaDeFundo(false, 'm.ogg', null), isNull);
    });
  });
}
