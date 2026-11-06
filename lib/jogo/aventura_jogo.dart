import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'classes.dart';
import 'controle.dart';
import 'fase.dart';
import 'fundo.dart';
import 'sons.dart';

class AventuraJogo extends FlameGame with KeyboardEvents {
  AventuraJogo() : super(camera: CameraComponent());

  static const double alturaVisivel = 15 * tamanhoBloco;

  static const overlayEscolha = 'escolha';
  static const overlayHud = 'hud';
  static const overlayControles = 'controles';
  static const overlayVitoria = 'vitoria';
  static const overlayDerrota = 'derrota';

  final Controle controle = Controle();
  final FocusNode foco = FocusNode(debugLabel: 'jogo');
  final Images imagensDosBlocos = Images(prefix: 'assets/tiles/');

  final ValueNotifier<int> moedas = ValueNotifier(0);
  final ValueNotifier<int> coracoes = ValueNotifier(3);
  int coracoesMaximos = 3;
  final ValueNotifier<bool> mostrarControlesDeToque = ValueNotifier(true);
  int totalDeMoedas = 0;
  int heroiEscolhido = 0;

  Fase? fase;

  @override
  Color backgroundColor() => const Color(0xFFDFF6F5);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'blocos.png',
      'fundo.png',
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
    _abrirMenu(overlayEscolha);
  }

  bool get _jogando =>
      fase != null &&
      !overlays.isActive(overlayEscolha) &&
      !overlays.isActive(overlayVitoria) &&
      !overlays.isActive(overlayDerrota);

  void _abrirMenu(String overlay) {
    controle.soltarTudo();
    foco.unfocus();
    overlays.add(overlay);
  }

  Future<void> comecar(int indiceHeroi) async {
    heroiEscolhido = indiceHeroi;
    overlays
      ..remove(overlayEscolha)
      ..remove(overlayVitoria)
      ..remove(overlayDerrota);
    moedas.value = 0;
    coracoesMaximos = classes[indiceHeroi].coracoes;
    coracoes.value = coracoesMaximos;
    controle.soltarTudo();

    final nova = Fase(arquivo: 'fase1.tmx', classe: classes[indiceHeroi]);
    fase = nova;
    world = nova;
    camera.world = nova;
    await nova.loaded;

    overlays
      ..add(overlayHud)
      ..add(overlayControles);
    Sons.iniciarMusica();
    _focarNoJogo();
  }

  void _focarNoJogo() {
    WidgetsBinding.instance.addPostFrameCallback((_) => foco.requestFocus());
  }

  void voltarParaEscolha() {
    Sons.pararMusica();
    overlays
      ..remove(overlayVitoria)
      ..remove(overlayDerrota)
      ..remove(overlayHud)
      ..remove(overlayControles);
    _abrirMenu(overlayEscolha);
  }

  void perderCoracao({bool caiu = false}) {
    coracoes.value = max(0, coracoes.value - 1);
    if (coracoes.value == 0) {
      fase?.heroi.congelar();
      Sons.pausarMusica();
      Sons.tocar('derrota');
      overlays.remove(overlayControles);
      _abrirMenu(overlayDerrota);
      return;
    }
    if (caiu) {
      fase?.voltarAoPontoDeRetorno();
    }
  }

  void tentarDeNovo() {
    overlays
      ..remove(overlayDerrota)
      ..add(overlayControles);
    coracoes.value = coracoesMaximos;
    controle.soltarTudo();
    fase?.voltarAoPontoDeRetorno();
    Sons.retomarMusica();
    _focarNoJogo();
  }

  void venceu() {
    fase?.heroi.congelar();
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
    final x = atual.largura <= meiaLargura * 2
        ? atual.largura / 2
        : atual.heroi.center.x.clamp(meiaLargura, atual.largura - meiaLargura);
    visor.position = Vector2(x, atual.altura / 2);
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
    if (!_jogando || !controle.ehTeclaDoJogo(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    controle.atualizarTeclado(event, keysPressed);
    if (event is KeyDownEvent) {
      mostrarControlesDeToque.value = false;
    }
    return KeyEventResult.handled;
  }
}
