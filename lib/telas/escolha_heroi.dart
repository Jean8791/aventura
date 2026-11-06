import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import '../jogo/classes.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (jogo.jogadores == 1)
              const Text('Escolha seu herói!', style: estiloTitulo)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: jogo.jogadorEscolhendo == 0
                        ? const Color(0xFFFF7A1A)
                        : const Color(0xFF3FA9F5),
                    child: Text(
                      '${jogo.jogadorEscolhendo + 1}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Jogador ${jogo.jogadorEscolhendo + 1}, escolha!',
                    style: estiloTitulo,
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < classes.length; i++)
                  BotaoGrande(
                    autofocus: i == jogo.heroiEscolhido,
                    cor: Colors.white,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    aoApertar: () => jogo.escolherHeroi(i),
                    child: _CartaoDeHeroi(classe: classes[i]),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            BotaoGrande(
              cor: const Color(0xFFE8F4FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }
}

class _CartaoDeHeroi extends StatelessWidget {
  const _CartaoDeHeroi({required this.classe});

  final ClasseDeHeroi classe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                classe.caminhoDaImagem,
                width: 88,
                height: 88,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
              Positioned(
                right: -10,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: classe.cor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3B2B4F),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    classe.icone,
                    size: 22,
                    color: const Color(0xFF3B2B4F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            classe.nome,
            textAlign: TextAlign.center,
            style: estiloBotao.copyWith(fontSize: 18),
          ),
          Text(
            classe.nomeDoPoder,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B5B7F),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < classe.coracoes; i++)
                const Icon(Icons.favorite, size: 16, color: Color(0xFFFF4D6D)),
            ],
          ),
        ],
      ),
    );
  }
}
