import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'progresso.dart';

class Sons {
  static const _efeitos = {
    'pulo.ogg': 3,
    'moeda.ogg': 4,
    'pisao.ogg': 3,
    'dano.ogg': 2,
    'mola.ogg': 2,
    'checkpoint.ogg': 2,
    'vitoria.ogg': 1,
    'derrota.ogg': 1,
    'espada.ogg': 3,
    'raio.ogg': 3,
    'fogo.ogg': 3,
    'terra.ogg': 3,
    'bolha.ogg': 3,
    'acerto.ogg': 3,
  };
  static const _musica = 'musica_fase1.wav';
  static const _volumeDaMusica = 0.35;

  static final Map<String, List<AudioPlayer>> _tocadores = {};
  static final Map<String, int> _proximo = {};

  static final ValueNotifier<bool> musicaLigada = ValueNotifier(
    Progresso.musicaLigada,
  );
  static bool _musicaTocando = false;

  static Future<void> carregar() async {
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([..._efeitos.keys, _musica]);
    final contexto = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    for (final MapEntry(key: arquivo, value: copias) in _efeitos.entries) {
      final lista = <AudioPlayer>[];
      for (var i = 0; i < copias; i++) {
        final tocador = AudioPlayer()..audioCache = FlameAudio.audioCache;
        try {
          await tocador.setAudioContext(contexto);
          await tocador.setPlayerMode(PlayerMode.lowLatency);
          await tocador.setReleaseMode(ReleaseMode.stop);
          await tocador.setSource(AssetSource(arquivo));
          lista.add(tocador);
        } catch (_) {
          await tocador.dispose();
        }
      }
      _tocadores[arquivo] = lista;
    }
  }

  static void tocar(String nome, {double volume = 0.6}) {
    final arquivo = '$nome.ogg';
    final lista = _tocadores[arquivo];
    if (lista == null || lista.isEmpty) {
      return;
    }
    final indice = (_proximo[arquivo] ?? 0) % lista.length;
    _proximo[arquivo] = indice + 1;
    final tocador = lista[indice];
    tocador
        .stop()
        .then((_) => tocador.setVolume(volume))
        .then((_) => tocador.resume())
        .catchError((_) {});
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
