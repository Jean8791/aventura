import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';

class Hud extends StatelessWidget {
  const Hud({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      for (var i = 0; i < AventuraJogo.coracoesIniciais; i++)
                        Icon(
                          i < coracoes ? Icons.favorite : Icons.favorite_border,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
