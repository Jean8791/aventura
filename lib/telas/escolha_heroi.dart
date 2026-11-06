import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';

class EscolhaHeroi extends StatelessWidget {
  const EscolhaHeroi({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC5BC0EB),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha seu herói!', style: estiloTitulo),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < herois.length; i++)
                  BotaoGrande(
                    autofocus: i == jogo.heroiEscolhido,
                    cor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    aoApertar: () => jogo.comecar(i),
                    child: Column(
                      children: [
                        Image.asset(
                          herois[i].imagem,
                          width: 96,
                          height: 96,
                          filterQuality: FilterQuality.none,
                        ),
                        const SizedBox(height: 6),
                        Text(herois[i].nome, style: estiloBotao),
                      ],
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
