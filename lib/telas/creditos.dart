import 'dart:async';

import 'package:flutter/material.dart';

import 'botao_grande.dart';

/// Créditos que sobem depois de vencer o chefe. Os botões só aparecem no fim
/// da rolagem e só respondem depois de uma carência, para um OK apertado sem
/// parar não recomeçar o jogo. O foco começa no botão que não perde nada.
class TelaCreditos extends StatefulWidget {
  const TelaCreditos({
    super.key,
    required this.jogadores,
    required this.aoJogarDesdeInicio,
    required this.aoEscolherHeroi,
    this.duracao = const Duration(seconds: 20),
  });

  final int jogadores;
  final VoidCallback aoJogarDesdeInicio;
  final VoidCallback aoEscolherHeroi;
  final Duration duracao;

  @override
  State<TelaCreditos> createState() => _TelaCreditosState();
}

class _TelaCreditosState extends State<TelaCreditos> {
  static const _carencia = Duration(milliseconds: 500);

  final _rolagem = ScrollController();
  bool _terminou = false;
  bool _aceitaToque = false;
  Timer? _timerDaCarencia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rolar());
  }

  Future<void> _rolar() async {
    if (mounted && _rolagem.hasClients) {
      await _rolagem.animateTo(
        _rolagem.position.maxScrollExtent,
        duration: widget.duracao,
        curve: Curves.linear,
      );
    }
    _mostrarBotoes();
  }

  void _mostrarBotoes() {
    if (!mounted || _terminou) {
      return;
    }
    setState(() => _terminou = true);
    _timerDaCarencia = Timer(_carencia, () => _aceitaToque = true);
  }

  void Function() _seLiberado(VoidCallback acao) => () {
    if (_aceitaToque) {
      acao();
    }
  };

  @override
  void dispose() {
    _timerDaCarencia?.cancel();
    _rolagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.jogadores > 1
        ? 'Vocês venceram o Feiticeiro!'
        : 'Você venceu o Feiticeiro!';
    return Container(
      color: const Color(0xE61A1530),
      child: _terminou ? _fim() : _rolando(titulo),
    );
  }

  Widget _rolando(String titulo) {
    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        controller: _rolagem,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: limites.maxHeight),
        child: SizedBox(
          width: limites.maxWidth,
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: Color(0xFFFFC93C),
                shadows: [
                  Shadow(offset: Offset(3, 3), color: Color(0xFF3B2B4F)),
                ],
              ),
              Text(titulo, style: estiloTitulo, textAlign: TextAlign.center),
              const SizedBox(height: 60),
              const _Secao('Feito por'),
              const _Pessoa('Mago do Código', 'programação'),
              const _Pessoa('Fada dos Sons', 'ideias de nome e sons'),
              const _Pessoa('Mestre das Histórias', 'criatividade e história'),
              const SizedBox(height: 60),
              const _Secao('Como foi feito'),
              const _Linha('Flutter + Flame'),
              const _Linha('Arte e alguns sons: Kenney (CC0)'),
              const _Linha(
                'Efeitos do herói e música dos créditos: gerados por script',
              ),
              const SizedBox(height: 40),
              const _Secao('Músicas e sons de fundo'),
              const _Linha('do OpenGameArt.org'),
              const _Linha('"Beautiful Forest" — nene (CC0)'),
              const _Linha(
                '"Ice Cave" — TAD (CC-BY 4.0)\n'
                'creativecommons.org/licenses/by/4.0',
              ),
              const _Linha('"Desert calmness" — Dizzy Crow (CC0)'),
              const _Linha(
                '"Crystal Cave" — Alex McCulloch / Pro Sensory (CC0)',
              ),
              const _Linha('"Fall of Nightmares" — nene (CC0)'),
              const _Linha(
                'Sons de fundo: TinyWorlds, Spring Spring, PagDev,\n'
                'JaggedStone e qubodup (CC0)',
              ),
              const SizedBox(height: 60),
              const _Linha(
                'Jogo feito só para a diversão em família,\n'
                'sem fins lucrativos.',
              ),
              const SizedBox(height: 60),
              const Text(
                'Obrigado por jogar!',
                style: estiloTitulo,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fim() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Obrigado por jogar!',
              style: estiloTitulo,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                BotaoGrande(
                  aoApertar: _seLiberado(widget.aoJogarDesdeInicio),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay_rounded,
                        size: 30,
                        color: Color(0xFF3B2B4F),
                      ),
                      SizedBox(width: 8),
                      Text('Jogar desde a fase 1', style: estiloBotao),
                    ],
                  ),
                ),
                BotaoGrande(
                  autofocus: true,
                  cor: Colors.white,
                  aoApertar: _seLiberado(widget.aoEscolherHeroi),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Color(0xFF3B2B4F),
                      ),
                      SizedBox(width: 8),
                      Text('Escolher outro herói', style: estiloBotao),
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

class _Secao extends StatelessWidget {
  const _Secao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFC93C),
        ),
      ),
    );
  }
}

class _Pessoa extends StatelessWidget {
  const _Pessoa(this.nome, this.papel);

  final String nome;
  final String papel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Text(
            nome,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            papel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB794F6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
