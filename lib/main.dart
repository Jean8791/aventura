import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jogo/aventura_jogo.dart';
import 'jogo/progresso.dart';
import 'telas/controles_toque.dart';
import 'telas/creditos.dart';
import 'telas/entrar_jogadores.dart';
import 'telas/escolha_fase.dart';
import 'telas/escolha_modo.dart';
import 'telas/escolha_heroi.dart';
import 'telas/fim_de_fase.dart';
import 'telas/hud.dart';
import 'telas/pausa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progresso.carregar();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const AventuraApp());
}

class AventuraApp extends StatefulWidget {
  const AventuraApp({super.key});

  @override
  State<AventuraApp> createState() => _AventuraAppState();
}

class _AventuraAppState extends State<AventuraApp> {
  final AventuraJogo _jogo = AventuraJogo();

  static final _teclasDeNavegacao = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.gameButtonA,
  };

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_recuperarFoco);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_recuperarFoco);
    super.dispose();
  }

  bool _recuperarFoco(KeyEvent evento) {
    if (evento is! KeyDownEvent ||
        !_jogo.menuAberto ||
        !_teclasDeNavegacao.contains(evento.logicalKey)) {
      return false;
    }
    final ehSeta = {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    }.contains(evento.logicalKey);
    if (!ehSeta && _jogo.overlays.isActive(AventuraJogo.overlayEntrar)) {
      return false;
    }
    final focado = FocusManager.instance.primaryFocus;
    if (focado != null && focado is! FocusScopeNode && focado != _jogo.foco) {
      return false;
    }
    FocusManager.instance.rootScope.nextFocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aventura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (jaSaiu, _) {
          if (!jaSaiu) {
            _jogo.voltar();
          }
        },
        child: Scaffold(
          body: GameWidget<AventuraJogo>(
            game: _jogo,
            focusNode: _jogo.foco,
            autofocus: false,
            overlayBuilderMap: {
              AventuraJogo.overlayEscolha: (_, jogo) =>
                  EscolhaHeroi(jogo: jogo),
              AventuraJogo.overlayModo: (_, jogo) => EscolhaModo(jogo: jogo),
              AventuraJogo.overlayEntrar: (_, jogo) =>
                  EntrarJogadores(jogo: jogo),
              AventuraJogo.overlayFases: (_, jogo) => EscolhaFase(jogo: jogo),
              AventuraJogo.overlayPausa: (_, jogo) => TelaPausa(jogo: jogo),
              AventuraJogo.overlayHud: (_, jogo) => Hud(jogo: jogo),
              AventuraJogo.overlayControles: (_, jogo) =>
                  ControlesToque(jogo: jogo),
              AventuraJogo.overlayVitoria: (_, jogo) => TelaVitoria(jogo: jogo),
              AventuraJogo.overlayDerrota: (_, jogo) => TelaDerrota(jogo: jogo),
              AventuraJogo.overlayCreditos: (_, jogo) => TelaCreditos(
                jogadores: jogo.jogadores,
                aoJogarDesdeInicio: () => jogo.comecar(0),
                aoEscolherHeroi: jogo.voltarParaEscolha,
              ),
            },
          ),
        ),
      ),
    );
  }
}
