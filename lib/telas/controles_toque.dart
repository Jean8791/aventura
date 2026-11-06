import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';

class ControlesToque extends StatelessWidget {
  const ControlesToque({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    final controle = jogo.controle;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => jogo.mostrarControlesDeToque.value = true,
      child: ValueListenableBuilder<bool>(
        valueListenable: jogo.mostrarControlesDeToque,
        builder: (_, visivel, _) => !visivel
            ? const SizedBox.expand()
            : SizedBox.expand(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Botao(
                            icone: Icons.arrow_back_rounded,
                            aoMudar: (apertado) =>
                                controle.toqueEsquerda = apertado,
                          ),
                          const SizedBox(width: 16),
                          _Botao(
                            icone: Icons.arrow_forward_rounded,
                            aoMudar: (apertado) =>
                                controle.toqueDireita = apertado,
                          ),
                          const Spacer(),
                          _Botao(
                            icone:
                                jogo.fase?.classe.icone ?? Icons.star_rounded,
                            cor: (jogo.fase?.classe.cor ?? Colors.white)
                                .withValues(alpha: 0.6),
                            aoMudar: controle.toqueAtaque,
                          ),
                          const SizedBox(width: 18),
                          _Botao(
                            icone: Icons.arrow_upward_rounded,
                            tamanho: 104,
                            cor: const Color(0x99FFC93C),
                            aoMudar: controle.toquePulo,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Botao extends StatefulWidget {
  const _Botao({
    required this.icone,
    required this.aoMudar,
    this.tamanho = 88,
    this.cor = const Color(0x77FFFFFF),
  });

  final IconData icone;
  final ValueChanged<bool> aoMudar;
  final double tamanho;
  final Color cor;

  @override
  State<_Botao> createState() => _BotaoState();
}

class _BotaoState extends State<_Botao> {
  final Set<int> _dedos = {};

  void _atualizar() {
    widget.aoMudar(_dedos.isNotEmpty);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final apertado = _dedos.isNotEmpty;
    return Listener(
      onPointerDown: (e) {
        _dedos.add(e.pointer);
        _atualizar();
      },
      onPointerUp: (e) {
        _dedos.remove(e.pointer);
        _atualizar();
      },
      onPointerCancel: (e) {
        _dedos.remove(e.pointer);
        _atualizar();
      },
      child: Container(
        width: widget.tamanho,
        height: widget.tamanho,
        decoration: BoxDecoration(
          color: apertado ? Colors.white.withValues(alpha: 0.8) : widget.cor,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xAA3B2B4F), width: 4),
        ),
        child: Icon(
          widget.icone,
          size: widget.tamanho * 0.55,
          color: const Color(0xFF3B2B4F),
        ),
      ),
    );
  }
}
