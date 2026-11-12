// TelaVitoria: aparece ao vencer uma fase comum (a do chefe abre os créditos).
import 'package:aventura/jogo/aventura_jogo.dart';
import 'package:aventura/jogo/classes.dart';
import 'package:aventura/jogo/fase.dart';
import 'package:aventura/jogo/fases.dart';
import 'package:aventura/jogo/progresso.dart';
import 'package:aventura/telas/fim_de_fase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AventuraJogo _jogoNaFase(int indice, {int moedas = 0, int totalDeMoedas = 0}) {
  final jogo = AventuraJogo()
    ..faseAtual = indice
    ..totalDeMoedas = totalDeMoedas
    ..totalDeDiamantes = 3;
  jogo.moedas.value = moedas;
  jogo.fase = Fase(dados: fases[indice], classes: [classes[0]], numero: indice);
  return jogo;
}

Future<void> _mostrar(WidgetTester tester, AventuraJogo jogo) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TelaVitoria(jogo: jogo)),
    ),
  );
  await tester.pump();
}

/// Texto do botão que está com o foco agora.
bool _focadoContem(String texto) {
  final contexto = FocusManager.instance.primaryFocus?.context;
  if (contexto == null) {
    return false;
  }
  return find
      .descendant(
        of: find.byElementPredicate((e) => e == contexto),
        matching: find.text(texto),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progresso.carregar();
  });

  group('fase intermediária', () {
    testWidgets('mostra título, moedas e os três botões', (tester) async {
      await _mostrar(tester, _jogoNaFase(0, moedas: 7, totalDeMoedas: 20));

      expect(find.text('Você conseguiu!'), findsOneWidget);
      expect(find.text('Moedas: 7 de 20'), findsOneWidget);
      expect(find.text('Próxima fase'), findsOneWidget);
      expect(find.text('Jogar de novo'), findsOneWidget);
      expect(find.text('Fases'), findsOneWidget);
    });

    testWidgets('começa com foco em "Próxima fase"', (tester) async {
      await _mostrar(tester, _jogoNaFase(1));
      expect(_focadoContem('Próxima fase'), isTrue);
    });

    testWidgets('avisa quando faltam diamantes', (tester) async {
      Progresso.salvarDiamante(0, 0);
      await _mostrar(tester, _jogoNaFase(0));
      expect(
        find.text('Ainda tem diamantes escondidos nesta fase!'),
        findsOneWidget,
      );
    });

    testWidgets('não avisa quando achou todos os diamantes', (tester) async {
      for (var i = 0; i < 3; i++) {
        Progresso.salvarDiamante(0, i);
      }
      await _mostrar(tester, _jogoNaFase(0));
      expect(
        find.text('Ainda tem diamantes escondidos nesta fase!'),
        findsNothing,
      );
    });
  });
}
