import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';

class TelaVitoria extends StatelessWidget {
  const TelaVitoria({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return _Painel(
      titulo: 'Você conseguiu!',
      icone: Icons.emoji_events_rounded,
      corIcone: const Color(0xFFFFC93C),
      texto: 'Moedas: ${jogo.moedas.value} de ${jogo.totalDeMoedas}',
      botoes: [
        BotaoGrande(
          autofocus: true,
          aoApertar: () => jogo.comecar(jogo.heroiEscolhido),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.replay_rounded, size: 30, color: Color(0xFF3B2B4F)),
              SizedBox(width: 8),
              Text('Jogar de novo', style: estiloBotao),
            ],
          ),
        ),
        BotaoGrande(
          cor: Colors.white,
          aoApertar: jogo.voltarParaEscolha,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face_rounded, size: 30, color: Color(0xFF3B2B4F)),
              SizedBox(width: 8),
              Text('Trocar herói', style: estiloBotao),
            ],
          ),
        ),
      ],
    );
  }
}

class TelaDerrota extends StatelessWidget {
  const TelaDerrota({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    return _Painel(
      titulo: 'Ops! Vamos de novo?',
      icone: Icons.favorite_rounded,
      corIcone: const Color(0xFFFF4D6D),
      texto: 'Você volta da última bandeira.',
      botoes: [
        BotaoGrande(
          autofocus: true,
          aoApertar: jogo.tentarDeNovo,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 34,
                color: Color(0xFF3B2B4F),
              ),
              SizedBox(width: 8),
              Text('Tentar de novo', style: estiloBotao),
            ],
          ),
        ),
      ],
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({
    required this.titulo,
    required this.icone,
    required this.corIcone,
    required this.texto,
    required this.botoes,
  });

  final String titulo;
  final IconData icone;
  final Color corIcone;
  final String texto;
  final List<Widget> botoes;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x995BC0EB),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 72,
              color: corIcone,
              shadows: const [
                Shadow(offset: Offset(3, 3), color: Color(0xFF3B2B4F)),
              ],
            ),
            Text(titulo, style: estiloTitulo, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: botoes,
            ),
          ],
        ),
      ),
    );
  }
}
