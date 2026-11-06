import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import '../jogo/sons.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: ExcludeFocus(child: _BotaoDeSom()),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x993B2B4F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: jogo.coracoes,
                      builder: (_, coracoes, _) => Row(
                        children: [
                          for (var i = 0; i < jogo.coracoesMaximos; i++)
                            Icon(
                              i < coracoes
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: const Color(0xFFFF4D6D),
                              size: 30,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC93C),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFB8860B),
                          width: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: jogo.moedas,
                      builder: (_, moedas, _) => Text(
                        '$moedas',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: jogo.diamantes,
                      builder: (_, diamantes, _) => jogo.totalDeDiamantes == 0
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/diamante.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$diamantes',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoDeSom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ValueListenableBuilder<bool>(
        valueListenable: Sons.musicaLigada,
        builder: (_, ligada, _) => Material(
          color: const Color(0x993B2B4F),
          shape: const CircleBorder(),
          child: IconButton(
            iconSize: 30,
            color: Colors.white,
            onPressed: Sons.alternarMusica,
            icon: Icon(
              ligada ? Icons.music_note_rounded : Icons.music_off_rounded,
            ),
          ),
        ),
      ),
    );
  }
}
