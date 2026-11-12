import 'package:aventura/telas/creditos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _duracao = Duration(seconds: 20);

Future<({List<String> chamadas})> _mostrar(
  WidgetTester tester, {
  int jogadores = 1,
}) async {
  final chamadas = <String>[];
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TelaCreditos(
          jogadores: jogadores,
          duracao: _duracao,
          aoJogarDesdeInicio: () => chamadas.add('inicio'),
          aoEscolherHeroi: () => chamadas.add('heroi'),
        ),
      ),
    ),
  );
  await tester.pump();
  return (chamadas: chamadas);
}

Future<void> _esperarRolagem(WidgetTester tester) async {
  await tester.pump(_duracao);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

Future<void> _esperarCarencia(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

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
  testWidgets('mostra créditos com os apelidos', (tester) async {
    await _mostrar(tester);

    expect(find.text('Mago do Código'), findsOneWidget);
    expect(find.text('Fada dos Sons'), findsOneWidget);
    expect(find.text('Mestre das Histórias'), findsOneWidget);
    expect(find.text('programação'), findsOneWidget);
    expect(find.text('ideias de nome e sons'), findsOneWidget);
    expect(find.text('criatividade e história'), findsOneWidget);
  });

  testWidgets('mostra como foi feito e o aviso', (tester) async {
    await _mostrar(tester);

    expect(find.textContaining('Flutter'), findsOneWidget);
    expect(find.textContaining('Flame'), findsOneWidget);
    expect(find.textContaining('Kenney'), findsOneWidget);
    expect(find.textContaining('CC0'), findsWidgets);
    expect(find.textContaining('gerados por script'), findsOneWidget);
    expect(find.textContaining('sem fins lucrativos'), findsOneWidget);
  });

  testWidgets('credita os autores das músicas (CC-BY exige)', (tester) async {
    await _mostrar(tester);

    expect(find.textContaining('Ice Cave'), findsOneWidget);
    expect(find.textContaining('TAD'), findsOneWidget);
    expect(find.textContaining('CC-BY 4.0'), findsOneWidget);
    expect(find.textContaining('OpenGameArt'), findsWidgets);
  });

  testWidgets('título no singular e no plural', (tester) async {
    await _mostrar(tester);
    expect(find.text('Você venceu o Feiticeiro!'), findsOneWidget);

    await _mostrar(tester, jogadores: 2);
    expect(find.text('Vocês venceram o Feiticeiro!'), findsOneWidget);
  });

  testWidgets('durante a rolagem não há botões e OK não faz nada', (
    tester,
  ) async {
    final r = await _mostrar(tester);
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Jogar desde a fase 1'), findsNothing);
    expect(find.text('Escolher outro herói'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(r.chamadas, isEmpty);
  });

  testWidgets('no fim da rolagem aparecem os botões com foco no seguro', (
    tester,
  ) async {
    await _mostrar(tester);
    await _esperarRolagem(tester);

    expect(find.text('Jogar desde a fase 1'), findsOneWidget);
    expect(find.text('Escolher outro herói'), findsOneWidget);
    expect(_focadoContem('Escolher outro herói'), isTrue);
  });

  testWidgets('OK logo que os botões aparecem não faz nada', (tester) async {
    final r = await _mostrar(tester);
    await _esperarRolagem(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.tap(find.text('Jogar desde a fase 1'));
    await tester.pump();
    expect(r.chamadas, isEmpty);
  });

  testWidgets('OK depois da carência escolhe outro herói', (tester) async {
    final r = await _mostrar(tester);
    await _esperarRolagem(tester);
    await _esperarCarencia(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(r.chamadas, ['heroi']);
  });

  testWidgets('tocar em "Jogar desde a fase 1" depois da carência', (
    tester,
  ) async {
    final r = await _mostrar(tester);
    await _esperarRolagem(tester);
    await _esperarCarencia(tester);

    await tester.tap(find.text('Jogar desde a fase 1'));
    await tester.pump();
    expect(r.chamadas, ['inicio']);
  });
}
