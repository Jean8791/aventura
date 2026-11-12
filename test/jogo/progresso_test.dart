// Testes de caracterização: registram o comportamento atual do Progresso.
import 'package:aventura/jogo/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _carregarCom(Map<String, Object> valores) async {
  SharedPreferences.setMockInitialValues(valores);
  await Progresso.carregar();
}

void main() {
  group('sem nada salvo', () {
    setUp(() => _carregarCom({}));

    test('usa os valores padrão', () {
      expect(Progresso.ultimaFase, 0);
      expect(Progresso.ultimoHeroi, 0);
      expect(Progresso.heroiDoJogador2, 1);
      expect(Progresso.jogadores, 1);
    });

    test('nenhuma fase concluída e nenhum diamante', () {
      for (var fase = 0; fase < 5; fase++) {
        expect(Progresso.concluida(fase), isFalse);
        expect(Progresso.diamantes(fase), isEmpty);
      }
    });
  });

  group('gravar e ler', () {
    setUp(() => _carregarCom({}));

    test('marcarConcluida marca só aquela fase', () {
      Progresso.marcarConcluida(2);
      expect(Progresso.concluida(2), isTrue);
      expect(Progresso.concluida(1), isFalse);
      expect(Progresso.concluida(3), isFalse);
    });

    test('salvarDiamante guarda por fase e não duplica', () {
      Progresso.salvarDiamante(0, 1);
      Progresso.salvarDiamante(0, 1);
      Progresso.salvarDiamante(0, 2);
      Progresso.salvarDiamante(3, 0);
      expect(Progresso.diamantes(0), {1, 2});
      expect(Progresso.diamantes(3), {0});
      expect(Progresso.diamantes(1), isEmpty);
    });

    test('setters gravam o valor', () {
      Progresso.ultimaFase = 4;
      Progresso.ultimoHeroi = 3;
      Progresso.heroiDoJogador2 = 2;
      Progresso.jogadores = 2;
      expect(Progresso.ultimaFase, 4);
      expect(Progresso.ultimoHeroi, 3);
      expect(Progresso.heroiDoJogador2, 2);
      expect(Progresso.jogadores, 2);
    });

    test('sobrevive a recarregar (persistiu no SharedPreferences)', () async {
      Progresso.marcarConcluida(1);
      Progresso.salvarDiamante(1, 2);
      await Progresso.carregar();
      expect(Progresso.concluida(1), isTrue);
      expect(Progresso.diamantes(1), {2});
    });
  });

  group('limites e dados estranhos', () {
    test('ignora diamante salvo que não é número', () async {
      await _carregarCom({
        'diamantes_fase_0': ['0', 'x', '', '2'],
      });
      expect(Progresso.diamantes(0), {0, 2});
    });

    test('aceita fase fora da lista sem validar', () async {
      await _carregarCom({});
      Progresso.marcarConcluida(-1);
      Progresso.marcarConcluida(99);
      Progresso.salvarDiamante(99, 7);
      expect(Progresso.concluida(-1), isTrue);
      expect(Progresso.concluida(99), isTrue);
      expect(Progresso.diamantes(99), {7});
    });

    test('devolve valores salvos fora do intervalo sem limitar', () async {
      await _carregarCom({'ultima_fase': 42, 'jogadores': 7});
      expect(Progresso.ultimaFase, 42);
      expect(Progresso.jogadores, 7);
    });
  });
}
