import 'dart:async';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'classes.dart';
import 'controle.dart';
import 'entrada_de_controles.dart';
import 'fase.dart';
import 'fases.dart';
import 'fundo.dart';
import 'heroi.dart';
import 'progresso.dart';
import 'sons.dart';

class AventuraJogo extends FlameGame with KeyboardEvents {
  AventuraJogo() : super(camera: CameraComponent());

  static const double alturaVisivel = 15 * tamanhoBloco;
  static const double _tempoDesmaiado = 3;

  static const overlayModo = 'modo';
  static const overlayEntrar = 'entrar';
  static const overlayEscolha = 'escolha';
  static const overlayFases = 'fases';
  static const overlayHud = 'hud';
  static const overlayControles = 'controles';
  static const overlayVitoria = 'vitoria';
  static const overlayDerrota = 'derrota';
  static const overlayPausa = 'pausa';

  final List<Controle> controles = [Controle(), Controle()];
  final EntradaDeControles _entrada = EntradaDeControles();
  StreamSubscription<EventoDeControle>? _assinaturaDaEntrada;
  final ValueNotifier<List<String?>> origensDosJogadores = ValueNotifier([
    null,
    null,
  ]);

  final FocusNode foco = FocusNode(debugLabel: 'jogo');
  final Images imagensDosBlocos = Images(prefix: 'assets/tiles/');

  final ValueNotifier<int> moedas = ValueNotifier(0);
  final List<ValueNotifier<int>> coracoesDosJogadores = [
    ValueNotifier(3),
    ValueNotifier(3),
  ];
  final List<int> coracoesMaximos = [3, 3];
  final ValueNotifier<bool> mostrarControlesDeToque = ValueNotifier(true);
  int totalDeMoedas = 0;
  final ValueNotifier<int> diamantes = ValueNotifier(0);
  final ValueNotifier<double?> vidaDoChefe = ValueNotifier(null);
  final ValueNotifier<int> estagioDoChefe = ValueNotifier(0);
  int totalDeDiamantes = 0;

  int jogadores = Progresso.jogadores.clamp(1, 2);
  final List<int> heroisEscolhidos = [
    Progresso.ultimoHeroi.clamp(0, classes.length - 1),
    Progresso.heroiDoJogador2.clamp(0, classes.length - 1),
  ];
  int jogadorEscolhendo = 0;
  int faseAtual = Progresso.ultimaFase.clamp(0, fases.length - 1);

  Fase? fase;

  Controle get controle => controles[0];
  int get heroiEscolhido => heroisEscolhidos[jogadorEscolhendo];
  bool get temProximaFase => faseAtual + 1 < fases.length;

  @override
  Color backgroundColor() => fase?.dados.ceu ?? const Color(0xFFDFF6F5);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'blocos.png',
      'fundo.png',
      'fundo_deserto.png',
      'fundo_caverna.png',
      'inimigos/feiticeiro.png',
      'inimigos/feiticeiro_bravo.png',
      'inimigos/feiticeiro_furioso.png',
      'diamante.png',
      'obstaculos_gelo.png',
      'obstaculos_rachada.png',
      for (final classe in classes) classe.imagem,
      'inimigos/slime.png',
      'inimigos/slime_fogo.png',
      'inimigos/morcego.png',
      'inimigos/golem.png',
      'poderes/espada.png',
      'poderes/pedra.png',
    ]);
    await Sons.carregar();
    camera.backdrop.add(Fundo());
    camera.viewfinder.anchor = Anchor.center;
    _entrada.iniciar();
    _assinaturaDaEntrada = _entrada.eventos.listen(_receberControle);
    _abrirMenu(overlayModo);
  }

  @override
  void onRemove() {
    _assinaturaDaEntrada?.cancel();
    _entrada.encerrar();
    super.onRemove();
  }

  bool get _jogando =>
      fase != null &&
      !overlays.isActive(overlayModo) &&
      !overlays.isActive(overlayEntrar) &&
      !overlays.isActive(overlayEscolha) &&
      !overlays.isActive(overlayFases) &&
      !overlays.isActive(overlayVitoria) &&
      !overlays.isActive(overlayDerrota) &&
      !overlays.isActive(overlayPausa);

  void _abrirMenu(String overlay) {
    for (final c in controles) {
      c.soltarTudo();
    }
    foco.unfocus();
    overlays.add(overlay);
  }

  void _fecharTudo() {
    overlays.removeAll([
      overlayModo,
      overlayEntrar,
      overlayEscolha,
      overlayFases,
      overlayVitoria,
      overlayDerrota,
      overlayPausa,
      overlayHud,
      overlayControles,
    ]);
    resumeEngine();
  }

  void pausar() {
    if (!_jogando) {
      return;
    }
    pauseEngine();
    Sons.pausarMusica();
    overlays.remove(overlayControles);
    _abrirMenu(overlayPausa);
  }

  void continuar() {
    overlays.remove(overlayPausa);
    overlays.add(overlayControles);
    resumeEngine();
    Sons.retomarMusica();
    _focarNoJogo();
  }

  void voltar() {
    if (_jogando) {
      pausar();
    } else if (overlays.isActive(overlayPausa)) {
      continuar();
    } else if (overlays.isActive(overlayVitoria) ||
        overlays.isActive(overlayDerrota)) {
      abrirEscolhaDeFase();
    } else if (overlays.isActive(overlayFases)) {
      voltarParaEscolha();
    } else if (overlays.isActive(overlayEscolha)) {
      if (jogadorEscolhendo == 1) {
        _abrirEscolhaDeHeroi(0);
      } else {
        abrirEscolhaDeModo();
      }
    } else if (overlays.isActive(overlayEntrar)) {
      abrirEscolhaDeModo();
    } else {
      SystemNavigator.pop();
    }
  }

  void _receberControle(EventoDeControle evento) {
    if (jogadores < 2) {
      return;
    }
    if (overlays.isActive(overlayEntrar)) {
      _ligarControle(evento);
      return;
    }
    final jogador = origensDosJogadores.value.indexOf(evento.origem);
    if (jogador < 0 || !_jogando) {
      return;
    }
    controles[jogador].receberNativo(evento);
    if (!evento.eixo && evento.apertou) {
      mostrarControlesDeToque.value = false;
    }
  }

  void _ligarControle(EventoDeControle evento) {
    if (evento.eixo || !evento.apertou) {
      return;
    }
    final origens = [...origensDosJogadores.value];
    if (origens.contains(evento.origem)) {
      return;
    }
    final vaga = origens.indexOf(null);
    if (vaga < 0) {
      return;
    }
    origens[vaga] = evento.origem;
    origensDosJogadores.value = origens;
    Sons.tocar('moeda', volume: 0.5);
    if (!origens.contains(null)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (overlays.isActive(overlayEntrar)) {
          overlays.remove(overlayEntrar);
          _abrirEscolhaDeHeroi(0);
        }
      });
    }
  }

  void escolherModo(int quantidade) {
    jogadores = quantidade;
    Progresso.jogadores = quantidade;
    overlays.remove(overlayModo);
    if (quantidade == 2) {
      origensDosJogadores.value = [null, null];
      _abrirMenu(overlayEntrar);
    } else {
      _abrirEscolhaDeHeroi(0);
    }
  }

  void abrirEscolhaDeModo() {
    Sons.pararMusica();
    _fecharTudo();
    _abrirMenu(overlayModo);
  }

  void _abrirEscolhaDeHeroi(int jogador) {
    jogadorEscolhendo = jogador;
    overlays.remove(overlayEscolha);
    _abrirMenu(overlayEscolha);
  }

  void escolherHeroi(int indiceHeroi) {
    heroisEscolhidos[jogadorEscolhendo] = indiceHeroi;
    if (jogadorEscolhendo == 0) {
      Progresso.ultimoHeroi = indiceHeroi;
    } else {
      Progresso.heroiDoJogador2 = indiceHeroi;
    }
    if (jogadores == 2 && jogadorEscolhendo == 0) {
      _abrirEscolhaDeHeroi(1);
      return;
    }
    jogadorEscolhendo = 0;
    overlays.remove(overlayEscolha);
    _abrirMenu(overlayFases);
  }

  void abrirEscolhaDeFase() {
    Sons.pararMusica();
    _fecharTudo();
    _abrirMenu(overlayFases);
  }

  void voltarParaEscolha() {
    Sons.pararMusica();
    _fecharTudo();
    _abrirEscolhaDeHeroi(0);
  }

  Future<void> proximaFase() => comecar(temProximaFase ? faseAtual + 1 : 0);

  Future<void> comecar(int indiceFase) async {
    faseAtual = indiceFase;
    Progresso.ultimaFase = indiceFase;
    _fecharTudo();
    moedas.value = 0;
    diamantes.value = 0;
    vidaDoChefe.value = null;
    estagioDoChefe.value = 0;
    for (var j = 0; j < jogadores; j++) {
      coracoesMaximos[j] = classes[heroisEscolhidos[j]].coracoes;
      coracoesDosJogadores[j].value = coracoesMaximos[j];
    }
    for (final c in controles) {
      c.soltarTudo();
    }

    final nova = Fase(
      dados: fases[indiceFase],
      classes: [
        for (var j = 0; j < jogadores; j++) classes[heroisEscolhidos[j]],
      ],
      numero: indiceFase,
    );
    fase = nova;
    world = nova;
    camera.world = nova;
    await nova.loaded;

    overlays.addAll([overlayHud, overlayControles]);
    Sons.iniciarMusica(fases[indiceFase].musica);
    _focarNoJogo();
  }

  void _focarNoJogo() {
    WidgetsBinding.instance.addPostFrameCallback((_) => foco.requestFocus());
  }

  Heroi? _companheiroAtivo(Heroi heroi) {
    for (final outro in fase?.herois ?? const <Heroi>[]) {
      if (outro != heroi && outro.ativo) {
        return outro;
      }
    }
    return null;
  }

  void perderCoracao(Heroi heroi, {bool caiu = false}) {
    final atual = fase;
    if (atual == null) {
      return;
    }
    final coracoes = coracoesDosJogadores[heroi.jogador];
    coracoes.value = max(0, coracoes.value - 1);
    final companheiro = _companheiroAtivo(heroi);

    if (coracoes.value == 0) {
      if (companheiro == null) {
        _perderAFase();
      } else {
        heroi.desmaiar(_tempoDesmaiado, perto: _aoLadoDe(companheiro)..y -= 14);
      }
      return;
    }
    if (caiu) {
      if (companheiro != null) {
        heroi.reaparecer(_aoLadoDe(companheiro));
      } else {
        atual.voltarAoPontoDeRetorno(apenas: heroi);
      }
    }
  }

  Vector2 _aoLadoDe(Heroi companheiro) {
    final atras = companheiro.position.x - companheiro.direcao * 16;
    final fase = this.fase!;
    final x =
        fase.temChaoEm(
          atras + Heroi.largura / 2,
          companheiro.position.y + Heroi.altura + 2,
        )
        ? atras
        : companheiro.position.x;
    return Vector2(x, companheiro.position.y - 2);
  }

  void reviver(Heroi heroi) {
    coracoesDosJogadores[heroi.jogador].value = coracoesMaximos[heroi.jogador];
    final companheiro = _companheiroAtivo(heroi);
    if (companheiro != null) {
      heroi.reaparecer(_aoLadoDe(companheiro));
    } else {
      fase?.voltarAoPontoDeRetorno(apenas: heroi);
    }
  }

  void _perderAFase() {
    for (final heroi in fase?.herois ?? const <Heroi>[]) {
      heroi.congelar();
    }
    Sons.pausarMusica();
    Sons.tocar('derrota');
    overlays.remove(overlayControles);
    _abrirMenu(overlayDerrota);
  }

  void tentarDeNovo() {
    overlays.remove(overlayDerrota);
    overlays.add(overlayControles);
    for (var j = 0; j < jogadores; j++) {
      coracoesDosJogadores[j].value = coracoesMaximos[j];
    }
    for (final c in controles) {
      c.soltarTudo();
    }
    fase?.voltarAoPontoDeRetorno();
    Sons.retomarMusica();
    _focarNoJogo();
  }

  void venceu() {
    Progresso.marcarConcluida(faseAtual);
    for (final heroi in fase?.herois ?? const <Heroi>[]) {
      heroi.congelar();
    }
    Sons.pararMusica();
    Sons.tocar('vitoria');
    overlays.remove(overlayControles);
    _abrirMenu(overlayVitoria);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final atual = fase;
    if (atual == null || !atual.isLoaded) {
      return;
    }
    final visor = camera.viewfinder;
    final meiaLargura = size.x / visor.zoom / 2;
    final ativos = atual.herois.where((h) => h.ativo).toList();
    final seguidos = ativos.isEmpty ? atual.herois : ativos;
    final alvo =
        seguidos.map((h) => h.center.x).reduce((a, b) => a + b) /
        seguidos.length;
    final x = atual.largura <= meiaLargura * 2
        ? atual.largura / 2
        : alvo.clamp(meiaLargura, atual.largura - meiaLargura);
    visor.position = Vector2(x, atual.altura / 2);

    if (ativos.length > 1) {
      final esquerda = x - meiaLargura + 2;
      final direita = x + meiaLargura - 2;
      for (final heroi in ativos) {
        heroi.manterDentro(esquerda, direita);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.zoom = size.y / alturaVisivel;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent &&
        _jogando &&
        (event.logicalKey == LogicalKeyboardKey.gameButtonStart ||
            event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.keyP)) {
      pausar();
      return KeyEventResult.handled;
    }
    if (!_jogando || !controle.ehTeclaDoJogo(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    if (jogadores == 1) {
      controle.atualizarTeclado(event, keysPressed);
      if (event is KeyDownEvent) {
        mostrarControlesDeToque.value = false;
      }
    }
    return KeyEventResult.handled;
  }
}
