import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controle.dart';
import 'fase.dart';
import 'fundo.dart';
import 'sons.dart';

class OpcaoDeHeroi {
  const OpcaoDeHeroi(this.nome, this.indiceSprite, this.imagem);
  final String nome;
  final int indiceSprite;
  final String imagem;
}

const herois = [
  OpcaoDeHeroi('Verde', 0, 'assets/images/herois/verde.png'),
  OpcaoDeHeroi('Azul', 2, 'assets/images/herois/azul.png'),
  OpcaoDeHeroi('Rosa', 4, 'assets/images/herois/rosa.png'),
  OpcaoDeHeroi('Amarelo', 6, 'assets/images/herois/amarelo.png'),
  OpcaoDeHeroi('Bege', 9, 'assets/images/herois/bege.png'),
];

class AventuraJogo extends FlameGame with KeyboardEvents {
  AventuraJogo() : super(camera: CameraComponent());

  static const double alturaVisivel = 15 * tamanhoBloco;
  static const int coracoesIniciais = 3;

  static const overlayEscolha = 'escolha';
  static const overlayHud = 'hud';
  static const overlayControles = 'controles';
  static const overlayVitoria = 'vitoria';
  static const overlayDerrota = 'derrota';

  final Controle controle = Controle();
  final FocusNode foco = FocusNode(debugLabel: 'jogo');
  final Images imagensDosBlocos = Images(prefix: 'assets/tiles/');

  final ValueNotifier<int> moedas = ValueNotifier(0);
  final ValueNotifier<int> coracoes = ValueNotifier(coracoesIniciais);
  final ValueNotifier<bool> mostrarControlesDeToque = ValueNotifier(true);
  int totalDeMoedas = 0;
  int heroiEscolhido = 0;

  Fase? fase;

  @override
  Color backgroundColor() => const Color(0xFFDFF6F5);

  @override
  Future<void> onLoad() async {
    await images.loadAll(['personagens.png', 'blocos.png', 'fundo.png']);
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
    coracoes.value = coracoesIniciais;
    controle.soltarTudo();

    final nova = Fase(
      arquivo: 'fase1.tmx',
      indiceHeroi: herois[indiceHeroi].indiceSprite,
    );
    fase = nova;
    world = nova;
    camera.world = nova;
    await nova.loaded;

    overlays
      ..add(overlayHud)
      ..add(overlayControles);
    _focarNoJogo();
  }

  void _focarNoJogo() {
    WidgetsBinding.instance.addPostFrameCallback((_) => foco.requestFocus());
  }

  void voltarParaEscolha() {
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
    coracoes.value = coracoesIniciais;
    controle.soltarTudo();
    fase?.voltarAoPontoDeRetorno();
    _focarNoJogo();
  }

  void venceu() {
    fase?.heroi.congelar();
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
