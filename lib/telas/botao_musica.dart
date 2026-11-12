import 'package:flutter/material.dart';

import '../jogo/sons.dart';

/// Botão redondo que liga e desliga a música. O dos menus e o das fases são
/// chaves separadas: dá para desligar uma e manter a outra.
class BotaoDeMusica extends StatelessWidget {
  const BotaoDeMusica.doMenu({super.key}) : menu = true;
  const BotaoDeMusica.daFase({super.key}) : menu = false;

  final bool menu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ValueListenableBuilder<bool>(
        valueListenable: menu
            ? Sons.musicaDoMenuLigada
            : Sons.musicaDaFaseLigada,
        builder: (_, ligada, _) => Material(
          color: const Color(0x993B2B4F),
          shape: const CircleBorder(),
          child: IconButton(
            iconSize: 30,
            color: Colors.white,
            tooltip: ligada ? 'Desligar música' : 'Ligar música',
            onPressed: () => Sons.alternarMusica(menu: menu),
            icon: Icon(
              ligada ? Icons.music_note_rounded : Icons.music_off_rounded,
            ),
          ),
        ),
      ),
    );
  }
}

/// Coloca o [BotaoDeMusica] no canto superior direito de um menu.
class ComBotaoDeMusica extends StatelessWidget {
  const ComBotaoDeMusica({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(
          top: 0,
          right: 0,
          child: SafeArea(child: BotaoDeMusica.doMenu()),
        ),
      ],
    );
  }
}
