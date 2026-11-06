import 'package:flame_audio/flame_audio.dart';

class Sons {
  static const _arquivos = [
    'pulo.ogg',
    'moeda.ogg',
    'pisao.ogg',
    'dano.ogg',
    'mola.ogg',
    'checkpoint.ogg',
    'vitoria.ogg',
    'derrota.ogg',
  ];

  static Future<void> carregar() => FlameAudio.audioCache.loadAll(_arquivos);

  static void tocar(String nome, {double volume = 0.6}) {
    FlameAudio.play('$nome.ogg', volume: volume);
  }
}
