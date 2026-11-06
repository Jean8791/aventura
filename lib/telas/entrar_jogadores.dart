import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';

class EntrarJogadores extends StatelessWidget {
  const EntrarJogadores({super.key, required this.jogo});

  final AventuraJogo jogo;

  static const _cores = [Color(0xFFFF7A1A), Color(0xFF3FA9F5)];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC5BC0EB),
      alignment: Alignment.center,
      child: ValueListenableBuilder<List<String?>>(
        valueListenable: jogo.origensDosJogadores,
        builder: (_, origens, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Peguem os controles!', style: estiloTitulo),
              const SizedBox(height: 6),
              const Text(
                'Cada jogador aperta OK (ou A) no próprio controle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  for (var j = 0; j < 2; j++)
                    _cartao(j, origens[j] != null, origens.indexOf(null) == j),
                ],
              ),
              const SizedBox(height: 18),
              BotaoGrande(
                cor: const Color(0xFFE8F4FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                aoApertar: jogo.voltar,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 26,
                      color: Color(0xFF3B2B4F),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B2B4F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartao(int jogador, bool pronto, bool vez) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: vez ? _cores[jogador] : const Color(0xFF3B2B4F),
          width: vez ? 6 : 3,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _cores[jogador],
            child: Text(
              '${jogador + 1}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Jogador ${jogador + 1}', style: estiloBotao),
          const SizedBox(height: 6),
          Icon(
            pronto ? Icons.check_circle_rounded : Icons.sports_esports_rounded,
            size: 48,
            color: pronto ? const Color(0xFF3CB371) : const Color(0xFF6B5B7F),
          ),
          const SizedBox(height: 4),
          Text(
            pronto
                ? 'Pronto!'
                : (vez ? 'Aperte OK\nno seu controle' : 'Aguarde...'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B2B4F),
            ),
          ),
        ],
      ),
    );
  }
}
