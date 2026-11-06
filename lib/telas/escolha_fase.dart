import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import '../jogo/classes.dart';
import '../jogo/fases.dart';
import 'botao_grande.dart';

class EscolhaFase extends StatelessWidget {
  const EscolhaFase({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    final heroi = classes[jogo.heroiEscolhido];
    return Container(
      color: const Color(0xCC5BC0EB),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  heroi.caminhoDaImagem,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 12),
                const Text('Escolha a fase!', style: estiloTitulo),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < fases.length; i++)
                  BotaoGrande(
                    autofocus: i == jogo.faseAtual,
                    cor: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    aoApertar: () => jogo.comecar(i),
                    child: _CartaoDeFase(
                      numero: i + 1,
                      dados: fases[i],
                      diamantes: jogo.melhoresDiamantes[i] ?? 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            BotaoGrande(
              cor: const Color(0xFFE8F4FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              aoApertar: jogo.voltarParaEscolha,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face_rounded, size: 26, color: Color(0xFF3B2B4F)),
                  SizedBox(width: 8),
                  Text(
                    'Trocar herói',
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

class _CartaoDeFase extends StatelessWidget {
  const _CartaoDeFase({
    required this.numero,
    required this.dados,
    required this.diamantes,
  });

  final int numero;
  final DadosDaFase dados;
  final int diamantes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: dados.cor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B2B4F), width: 3),
            ),
            child: Icon(dados.icone, size: 42, color: const Color(0xFF3B2B4F)),
          ),
          const SizedBox(height: 6),
          Text(
            'Fase $numero',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B5B7F),
            ),
          ),
          Text(
            dados.nome,
            textAlign: TextAlign.center,
            style: estiloBotao.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 4),
          LinhaDeDiamantes(quantidade: diamantes, tamanho: 22),
        ],
      ),
    );
  }
}

class LinhaDeDiamantes extends StatelessWidget {
  const LinhaDeDiamantes({
    super.key,
    required this.quantidade,
    this.total = 3,
    this.tamanho = 24,
  });

  final int quantidade;
  final int total;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Opacity(
            opacity: i < quantidade ? 1 : 0.25,
            child: Image.asset(
              'assets/images/diamante.png',
              width: tamanho,
              height: tamanho,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
      ],
    );
  }
}
