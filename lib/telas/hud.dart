import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import '../jogo/classes.dart';
import '../jogo/sons.dart';

const _corDoTexto = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w900,
  color: Colors.white,
);

const _coresDosJogadores = [Color(0xFFFF7A1A), Color(0xFF3FA9F5)];

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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x993B2B4F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var j = 0; j < jogo.jogadores; j++) ...[
                      _CoracoesDoJogador(jogo: jogo, jogador: j),
                      const SizedBox(width: 14),
                    ],
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
                    const SizedBox(width: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: jogo.moedas,
                      builder: (_, moedas, _) =>
                          Text('$moedas', style: _corDoTexto),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: jogo.diamantes,
                      builder: (_, diamantes, _) => jogo.totalDeDiamantes == 0
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(left: 14),
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
                                  Text('$diamantes', style: _corDoTexto),
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

class _CoracoesDoJogador extends StatelessWidget {
  const _CoracoesDoJogador({required this.jogo, required this.jogador});

  final AventuraJogo jogo;
  final int jogador;

  @override
  Widget build(BuildContext context) {
    final classe = classes[jogo.heroisEscolhidos[jogador]];
    final doisJogadores = jogo.jogadores > 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (doisJogadores) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                classe.caminhoDaImagem,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
              Positioned(
                right: -6,
                top: -6,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: _coresDosJogadores[jogador],
                  child: Text(
                    '${jogador + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
        ValueListenableBuilder<int>(
          valueListenable: jogo.coracoesDosJogadores[jogador],
          builder: (_, coracoes, _) => Row(
            children: [
              for (var i = 0; i < jogo.coracoesMaximos[jogador]; i++)
                Icon(
                  i < coracoes ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF4D6D),
                  size: doisJogadores ? 24 : 30,
                ),
            ],
          ),
        ),
      ],
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
