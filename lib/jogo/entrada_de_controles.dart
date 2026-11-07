import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Acao { esquerda, direita, pulo, ataque }

class EventoDeControle {
  const EventoDeControle.tecla({
    required this.origem,
    required this.acao,
    required this.apertou,
    this.confirma = false,
  }) : x = 0,
       y = 0,
       eixo = false;

  const EventoDeControle.eixo({
    required this.origem,
    required this.x,
    required this.y,
  }) : acao = null,
       confirma = false,
       apertou = false,
       eixo = true;

  final String origem;
  final Acao? acao;
  final bool apertou;
  final bool confirma;
  final bool eixo;
  final double x;
  final double y;
}

class EntradaDeControles {
  static const _canal = EventChannel('aventura/controles');

  static const _teclaVoltar = 4;
  static const _ladoEsquerdoDoTeclado = {29, 32, 51, 47};
  static const _teclasDeConfirmar = {23, 66, 62, 160, 96, 99, 108, 51};

  static Acao? acaoDoCodigo(int codigo) => switch (codigo) {
    21 || 29 => Acao.esquerda,
    22 || 32 => Acao.direita,
    19 || 23 || 66 || 62 || 96 || 51 || 160 => Acao.pulo,
    20 || 47 || 52 || 38 || 97 || 99 || 100 => Acao.ataque,
    _ => null,
  };

  static const _estado = MethodChannel('aventura/estado');

  static String origemDe(String dispositivo, int codigo) =>
      _ladoEsquerdoDoTeclado.contains(codigo)
      ? '$dispositivo:wasd'
      : dispositivo;

  bool? _jogandoEmDupla;

  void avisarJogandoEmDupla(bool emDupla) {
    if (kIsWeb || _jogandoEmDupla == emDupla) {
      return;
    }
    _jogandoEmDupla = emDupla;
    _estado.invokeMethod<void>('jogandoEmDupla', emDupla).catchError((_) {});
  }

  final _eventos = StreamController<EventoDeControle>.broadcast();
  StreamSubscription<dynamic>? _assinatura;

  Stream<EventoDeControle> get eventos => _eventos.stream;

  static final _codigosDoTeclado = {
    LogicalKeyboardKey.arrowLeft: 21,
    LogicalKeyboardKey.arrowRight: 22,
    LogicalKeyboardKey.arrowUp: 19,
    LogicalKeyboardKey.arrowDown: 20,
    LogicalKeyboardKey.enter: 66,
    LogicalKeyboardKey.numpadEnter: 160,
    LogicalKeyboardKey.space: 62,
    LogicalKeyboardKey.keyW: 51,
    LogicalKeyboardKey.keyA: 29,
    LogicalKeyboardKey.keyS: 47,
    LogicalKeyboardKey.keyD: 32,
    LogicalKeyboardKey.keyX: 52,
    LogicalKeyboardKey.keyJ: 38,
  };

  bool _receberTecladoDaWeb(KeyEvent evento) {
    final codigo = _codigosDoTeclado[evento.logicalKey];
    if (codigo != null && evento is! KeyRepeatEvent) {
      _receber({
        'tipo': 'tecla',
        'origem': 'teclado',
        'codigo': codigo,
        'apertou': evento is KeyDownEvent,
      });
    }
    return false;
  }

  void iniciar() {
    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_receberTecladoDaWeb);
      return;
    }
    _assinatura ??= _canal.receiveBroadcastStream().listen(
      _receber,
      onError: (_) {},
    );
  }

  void _receber(dynamic dados) {
    if (dados is! Map) {
      return;
    }
    final dispositivo =
        dados['origem'] as String? ?? '${dados['dispositivo'] as int? ?? 0}';
    if (dados['tipo'] == 'eixo') {
      _eventos.add(
        EventoDeControle.eixo(
          origem: dispositivo,
          x: (dados['x'] as num?)?.toDouble() ?? 0,
          y: (dados['y'] as num?)?.toDouble() ?? 0,
        ),
      );
      return;
    }
    final codigo = dados['codigo'] as int? ?? 0;
    if (codigo == _teclaVoltar) {
      return;
    }
    _eventos.add(
      EventoDeControle.tecla(
        origem: origemDe(dispositivo, codigo),
        acao: acaoDoCodigo(codigo),
        apertou: dados['apertou'] == true,
        confirma: _teclasDeConfirmar.contains(codigo),
      ),
    );
  }

  void encerrar() {
    if (kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_receberTecladoDaWeb);
    }
    _assinatura?.cancel();
    _assinatura = null;
  }
}
