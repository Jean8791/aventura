import 'package:flutter/material.dart';

import '../jogo/aventura_jogo.dart';
import 'botao_grande.dart';
import 'escolha_fase.dart';

class TelaVitoria extends StatelessWidget {
  const TelaVitoria({super.key, required this.jogo});

  final AventuraJogo jogo;

  @override
  Widget build(BuildContext context) {
    final ultima = !jogo.temProximaFase;
    final faltam = jogo.totalDeDiamantes - jogo.diamantes.value;
    return _Painel(
      titulo: ultima ? 'Você terminou a aventura!' : 'Você conseguiu!',
      icone: Icons.emoji_events_rounded,
      corIcone: const Color(0xFFFFC93C),
      texto: 'Moedas: ${jogo.moedas.value} de ${jogo.totalDeMoedas}',
      extra: Column(
        children: [
          const SizedBox(height: 6),
          LinhaDeDiamantes(
            quantidade: jogo.diamantes.value,
            total: jogo.totalDeDiamantes,
            tamanho: 34,
          ),
          if (faltam > 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Ainda tem diamantes escondidos nesta fase!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      botoes: [
        if (!ultima)
          BotaoGrande(
            autofocus: true,
            aoApertar: jogo.proximaFase,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                  color: Color(0xFF3B2B4F),
                ),
                SizedBox(width: 8),
                Text('Próxima fase', style: estiloBotao),
              ],
            ),
          ),
        BotaoGrande(
          autofocus: ultima,
          cor: ultima ? const Color(0xFFFFC93C) : Colors.white,
          aoApertar: () => jogo.comecar(jogo.faseAtual),
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
          aoApertar: jogo.abrirEscolhaDeFase,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded, size: 30, color: Color(0xFF3B2B4F)),
              SizedBox(width: 8),
              Text('Fases', style: estiloBotao),
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
    this.extra,
  });

  final String titulo;
  final IconData icone;
  final Color corIcone;
  final String texto;
  final List<Widget> botoes;
  final Widget? extra;

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
            ?extra,
            const SizedBox(height: 20),
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
