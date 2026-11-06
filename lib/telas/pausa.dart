import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';

class TelaPausa extends StatelessWidget {
  const TelaPausa({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xB33B2B4F),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              size: 72,
              color: Colors.white,
            ),
            const Text('Pausa', style: estiloTitulo),
            const SizedBox(height: 22),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                BotaoGrande(
                  autofocus: true,
                  aoApertar: jogo.continuar,
                  child: const _Rotulo(
                    icone: Icons.play_arrow_rounded,
                    texto: 'Continuar',
                  ),
                ),
                BotaoGrande(
                  cor: Colors.white,
                  aoApertar: jogo.voltarParaEscolha,
                  child: const _Rotulo(
                    icone: Icons.face_rounded,
                    texto: 'Trocar herói',
                  ),
                ),
                BotaoGrande(
                  cor: Colors.white,
                  aoApertar: jogo.abrirEscolhaDeFase,
                  child: const _Rotulo(
                    icone: Icons.map_rounded,
                    texto: 'Escolher fase',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 30, color: const Color(0xFF3B2B4F)),
        const SizedBox(width: 8),
        Text(texto, style: estiloBotao),
      ],
    );
  }
}
