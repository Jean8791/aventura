import 'package:aventura/jogo/progresso.dart';
import 'package:aventura/jogo/sons.dart';
import 'package:aventura/telas/botao_musica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progresso.carregar();
    Sons.musicaDoMenuLigada.value = true;
    Sons.musicaDaFaseLigada.value = true;
  });

  Future<void> mostrar(WidgetTester tester, Widget botao) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: botao)),
    ),
  );

  testWidgets('menu mostra o conteúdo e o botão por cima', (tester) async {
    await mostrar(tester, const ComBotaoDeMusica(child: Text('menu')));
    expect(find.text('menu'), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });

  testWidgets('botão do menu desliga só a música dos menus', (tester) async {
    await mostrar(tester, const ComBotaoDeMusica(child: Text('menu')));

    await tester.tap(find.byIcon(Icons.music_note_rounded));
    await tester.pump();
    expect(Sons.musicaDoMenuLigada.value, isFalse);
    expect(Sons.musicaDaFaseLigada.value, isTrue);
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.music_off_rounded));
    await tester.pump();
    expect(Sons.musicaDoMenuLigada.value, isTrue);
  });

  testWidgets('botão da fase desliga só a música das fases', (tester) async {
    await mostrar(tester, const BotaoDeMusica.daFase());

    await tester.tap(find.byIcon(Icons.music_note_rounded));
    await tester.pump();
    expect(Sons.musicaDaFaseLigada.value, isFalse);
    expect(Sons.musicaDoMenuLigada.value, isTrue);
  });

  testWidgets('a escolha não fica salva', (tester) async {
    await mostrar(tester, const BotaoDeMusica.daFase());
    await tester.tap(find.byIcon(Icons.music_note_rounded));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
