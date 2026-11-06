import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'progresso.dart';

class Sons {
  static const _efeitos = [
    'pulo.ogg',
    'moeda.ogg',
    'pisao.ogg',
    'dano.ogg',
    'mola.ogg',
    'checkpoint.ogg',
    'vitoria.ogg',
    'derrota.ogg',
  ];
  static const _musica = 'musica_fase1.wav';
  static const _volumeDaMusica = 0.35;

  static final ValueNotifier<bool> musicaLigada = ValueNotifier(
    Progresso.musicaLigada,
  );
  static bool _musicaTocando = false;

  static Future<void> carregar() async {
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([..._efeitos, _musica]);
  }

  static void tocar(String nome, {double volume = 0.6}) {
    FlameAudio.play('$nome.ogg', volume: volume);
  }

  static void iniciarMusica() {
    _musicaTocando = true;
    if (musicaLigada.value) {
      FlameAudio.bgm.play(_musica, volume: _volumeDaMusica);
    }
  }

  static void pausarMusica() {
    if (_musicaTocando && musicaLigada.value) {
      FlameAudio.bgm.pause();
    }
  }

  static void retomarMusica() {
    if (!_musicaTocando) {
      iniciarMusica();
    } else if (musicaLigada.value) {
      FlameAudio.bgm.resume();
    }
  }

  static void pararMusica() {
    _musicaTocando = false;
    FlameAudio.bgm.stop();
  }

  static void alternarMusica() {
    musicaLigada.value = !musicaLigada.value;
    Progresso.musicaLigada = musicaLigada.value;
    if (!_musicaTocando) {
      return;
    }
    if (musicaLigada.value) {
      FlameAudio.bgm.play(_musica, volume: _volumeDaMusica);
    } else {
      FlameAudio.bgm.stop();
    }
  }
}
