import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jogo/aventura_jogo.dart';
import 'jogo/progresso.dart';
import 'telas/controles_toque.dart';
import 'telas/escolha_fase.dart';
import 'telas/escolha_heroi.dart';
import 'telas/fim_de_fase.dart';
import 'telas/hud.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aventura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: Scaffold(
        body: GameWidget<AventuraJogo>(
          game: _jogo,
          focusNode: _jogo.foco,
          autofocus: false,
          overlayBuilderMap: {
            AventuraJogo.overlayEscolha: (_, jogo) => EscolhaHeroi(jogo: jogo),
            AventuraJogo.overlayFases: (_, jogo) => EscolhaFase(jogo: jogo),
            AventuraJogo.overlayHud: (_, jogo) => Hud(jogo: jogo),
            AventuraJogo.overlayControles: (_, jogo) =>
                ControlesToque(jogo: jogo),
            AventuraJogo.overlayVitoria: (_, jogo) => TelaVitoria(jogo: jogo),
            AventuraJogo.overlayDerrota: (_, jogo) => TelaDerrota(jogo: jogo),
          },
        ),
      ),
    );
  }
}
