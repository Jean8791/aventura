import 'package:shared_preferences/shared_preferences.dart';

class Progresso {
  static late SharedPreferences _prefs;

  static Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _chaveDiamantes(int fase) => 'diamantes_fase_$fase';
  static String _chaveConcluida(int fase) => 'concluida_fase_$fase';

  static Set<int> diamantes(int fase) =>
      (_prefs.getStringList(_chaveDiamantes(fase)) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  static void salvarDiamante(int fase, int indice) {
    final atuais = diamantes(fase);
    if (atuais.add(indice)) {
      _prefs.setStringList(_chaveDiamantes(fase), [
        for (final i in atuais) '$i',
      ]);
    }
  }

  static bool concluida(int fase) =>
      _prefs.getBool(_chaveConcluida(fase)) ?? false;

  static void marcarConcluida(int fase) =>
      _prefs.setBool(_chaveConcluida(fase), true);

  static int get ultimoHeroi => _prefs.getInt('ultimo_heroi') ?? 0;
  static set ultimoHeroi(int valor) => _prefs.setInt('ultimo_heroi', valor);

  static int get ultimaFase => _prefs.getInt('ultima_fase') ?? 0;
  static set ultimaFase(int valor) => _prefs.setInt('ultima_fase', valor);

  static bool get musicaLigada => _prefs.getBool('musica_ligada') ?? true;
  static set musicaLigada(bool valor) => _prefs.setBool('musica_ligada', valor);
}
