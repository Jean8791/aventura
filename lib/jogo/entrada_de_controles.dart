import 'dart:async';

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

  static String origemDe(int dispositivo, int codigo) =>
      _ladoEsquerdoDoTeclado.contains(codigo)
      ? '$dispositivo:wasd'
      : '$dispositivo';

  final _eventos = StreamController<EventoDeControle>.broadcast();
  StreamSubscription<dynamic>? _assinatura;

  Stream<EventoDeControle> get eventos => _eventos.stream;

  void iniciar() {
    _assinatura ??= _canal.receiveBroadcastStream().listen(
      _receber,
      onError: (_) {},
    );
  }

  void _receber(dynamic dados) {
    if (dados is! Map) {
      return;
    }
    final dispositivo = dados['dispositivo'] as int? ?? 0;
    if (dados['tipo'] == 'eixo') {
      _eventos.add(
        EventoDeControle.eixo(
          origem: '$dispositivo',
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
    _assinatura?.cancel();
    _assinatura = null;
  }
}
