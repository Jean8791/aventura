import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import '../jogo/chefe.dart';
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
            alignment: Alignment.topCenter,
            child: ValueListenableBuilder<double?>(
              valueListenable: jogo.vidaDoChefe,
              builder: (_, vida, _) => vida == null
                  ? const SizedBox.shrink()
                  : ValueListenableBuilder<int>(
                      valueListenable: jogo.estagioDoChefe,
                      builder: (_, estagio, _) =>
                          _BarraDoChefe(vida: vida, estagio: estagio),
                    ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ExcludeFocus(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BotaoRedondo(
                    icone: Icons.pause_rounded,
                    aoApertar: jogo.pausar,
                  ),
                  _BotaoDeSom(),
                ],
              ),
            ),
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

class _BarraDoChefe extends StatelessWidget {
  const _BarraDoChefe({required this.vida, required this.estagio});

  final double vida;
  final int estagio;

  static const _cores = [
    Color(0xFFFF4FD8),
    Color(0xFFFF8A1F),
    Color(0xFFFF2A2A),
  ];
  static const _titulos = ['', ' · Bravo', ' · Furioso'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 66),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${Chefe.nome}${_titulos[estagio.clamp(0, 2)]}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(offset: Offset(2, 2), color: Color(0xFF3B2B4F)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < estagiosDoChefe.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    Icons.circle,
                    size: 12,
                    color: i < estagiosDoChefe.length - estagio
                        ? _cores[estagio.clamp(0, 2)]
                        : const Color(0x553B2B4F),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 280,
            height: 18,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF3B2B4F),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 250),
                widthFactor: vida.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cores[estagio.clamp(0, 2)],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoRedondo extends StatelessWidget {
  const _BotaoRedondo({required this.icone, required this.aoApertar});

  final IconData icone;
  final VoidCallback aoApertar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Material(
        color: const Color(0x993B2B4F),
        shape: const CircleBorder(),
        child: IconButton(
          iconSize: 30,
          color: Colors.white,
          onPressed: aoApertar,
          icon: Icon(icone),
        ),
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
