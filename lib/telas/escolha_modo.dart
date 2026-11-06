import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';

class EscolhaModo extends StatelessWidget {
  const EscolhaModo({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC5BC0EB),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aventura', style: estiloTitulo),
            const SizedBox(height: 4),
            const Text(
              'Quantos jogadores?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _botao(1, Icons.person_rounded, '1 jogador'),
                _botao(2, Icons.people_alt_rounded, '2 jogadores'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botao(int quantidade, IconData icone, String texto) {
    return BotaoGrande(
      autofocus: jogo.jogadores == quantidade,
      cor: Colors.white,
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 14),
      aoApertar: () => jogo.escolherModo(quantidade),
      child: SizedBox(
        width: 150,
        child: Column(
          children: [
            Icon(icone, size: 76, color: const Color(0xFF3B2B4F)),
            const SizedBox(height: 4),
            Text(texto, style: estiloBotao),
            if (quantidade == 2)
              const Text(
                'um controle para cada',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B5B7F),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
