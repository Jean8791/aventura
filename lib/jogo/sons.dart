import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class Sons {
  static const _efeitos = {
    'pulo.wav': 3,
    'moeda.ogg': 4,
    'pisao.ogg': 3,
    'dano.wav': 2,
    'mola.ogg': 2,
    'checkpoint.ogg': 2,
    'vitoria.mp3': 1,
    'vitoria_final.ogg': 1,
    'chefe_derrotado.ogg': 1,
    'derrota.wav': 1,
    'espada.wav': 3,
    'raio.wav': 3,
    'fogo.wav': 3,
    'terra.wav': 3,
    'bolha.wav': 3,
    'acerto.ogg': 3,
  };
  static String? _musica;

  /// Música pedida por último (mesmo que esteja desligada ou parada).
  static String? get musicaAtual => _musica;
  static String? _ambiente;
  static String? _tocandoAgora;
  static const _volumeDaMusica = 0.35;

  static final Map<String, List<AudioPlayer>> _tocadores = {};
  static final Map<String, int> _proximo = {};

  /// Duas chaves independentes: a música dos menus (e créditos) e a das
  /// fases. Sempre começam ligadas; o botão vale só até fechar o jogo.
  static final ValueNotifier<bool> musicaDoMenuLigada = ValueNotifier(true);
  static final ValueNotifier<bool> musicaDaFaseLigada = ValueNotifier(true);
  static bool _trilhaDeMenu = false;

  static bool ligadaPara({required bool menu}) =>
      (menu ? musicaDoMenuLigada : musicaDaFaseLigada).value;
  static bool _musicaTocando = false;

  static Future<void> carregar() async {
    FlameAudio.bgm.initialize();
    // Músicas e sons de fundo carregam só quando tocam (são pesados).
    await FlameAudio.audioCache.loadAll(_efeitos.keys.toList());
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
    final arquivo = [
      '$nome.wav',
      '$nome.ogg',
      '$nome.mp3',
    ].firstWhere(_tocadores.containsKey, orElse: () => '');
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

  /// Interrompe um efeito que ainda está tocando (ex.: jingle de derrota).
  static void pararEfeito(String nome) {
    for (final lista in [
      _tocadores['$nome.wav'],
      _tocadores['$nome.ogg'],
      _tocadores['$nome.mp3'],
    ]) {
      for (final tocador in lista ?? const <AudioPlayer>[]) {
        tocador.stop().catchError((_) {});
      }
    }
  }

  /// Com a música ligada toca a música; desligada, o som de fundo (se houver).
  static String? faixaDeFundo(
    bool musicaLigada,
    String? musica,
    String? ambiente,
  ) => musicaLigada ? musica : ambiente;

  /// Copia a música e o som de fundo para o cache antes de a fase começar,
  /// para a troca no meio do jogo não ter de carregar arquivo grande.
  static Future<void> prepararFaixas(List<String> arquivos) async {
    try {
      await FlameAudio.audioCache.loadAll(arquivos);
    } catch (erro) {
      debugPrint('Sons: não carregou $arquivos: $erro');
    }
  }

  /// Começa a trilha de uma tela: [musica] e, opcionalmente, o som de fundo
  /// que a substitui quando a música está desligada. [menu] diz qual chave vale.
  static void iniciarMusica(
    String musica, {
    String? ambiente,
    bool menu = false,
  }) {
    _musica = musica;
    _ambiente = ambiente;
    _trilhaDeMenu = menu;
    _musicaTocando = true;
    _tocarFaixa();
  }

  // O Bgm.play são vários passos assíncronos no mesmo tocador. Duas chamadas
  // sobrepostas se atropelam (uma fica esperando para sempre e a música errada
  // volta). Por isso tudo do áudio de fundo passa por esta fila, um de cada vez.
  static Future<void> _fila = Future.value();

  static void _enfileirar(Future<void> Function() acao) {
    _fila = _fila.then((_) async {
      try {
        await acao().timeout(const Duration(seconds: 15));
      } catch (erro) {
        debugPrint('Sons: falha no áudio de fundo: $erro');
      }
    });
  }

  /// Aplica o estado atual (não o do momento do pedido): vale o último toque.
  static void _tocarFaixa() => _enfileirar(() async {
    final faixa = _musicaTocando
        ? faixaDeFundo(ligadaPara(menu: _trilhaDeMenu), _musica, _ambiente)
        : null;
    if (faixa == null) {
      _tocandoAgora = null;
      await FlameAudio.bgm.stop();
    } else if (faixa != _tocandoAgora) {
      _tocandoAgora = faixa;
      await FlameAudio.bgm.play(faixa, volume: _volumeDaMusica);
    } else if (!FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.resume();
    }
  });

  static void pausarMusica() => _enfileirar(() async {
    if (_tocandoAgora != null) {
      await FlameAudio.bgm.pause();
    }
  });

  static void retomarMusica() {
    _musicaTocando = true;
    _tocarFaixa();
  }

  static void pararMusica() {
    _musicaTocando = false;
    _tocarFaixa();
  }

  /// Liga/desliga a música dos menus ou a das fases. Só mexe no que está
  /// tocando se a trilha atual for daquele tipo.
  static void alternarMusica({required bool menu}) {
    final chave = menu ? musicaDoMenuLigada : musicaDaFaseLigada;
    chave.value = !chave.value;
    if (_musicaTocando && _trilhaDeMenu == menu) {
      _tocarFaixa();
    }
  }
}
