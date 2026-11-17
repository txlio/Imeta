
import 'package:shared_preferences/shared_preferences.dart';

import 'conquista_service.dart';

class XpService {
  static const String _chaveXp = 'xp_total';

  static const int xpHabito = 20;
  static const int xpTarefa = 10;
  static const int xpMeta = 50;

  final ConquistaService _conquistaService = ConquistaService();

  Future<int> carregarXp() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_chaveXp) ?? 0;
  }

  Future<int> adicionarXp(int quantidade) async {
    final prefs = await SharedPreferences.getInstance();

    final xpAtual = prefs.getInt(_chaveXp) ?? 0;
    final novoXp = xpAtual + quantidade;

    await prefs.setInt(_chaveXp, novoXp);

    // Verifica e registra as conquistas de XP e nível.
    await _verificarConquistas(novoXp);

    return novoXp;
  }

  Future<int> removerXp(int quantidade) async {
    final prefs = await SharedPreferences.getInstance();

    final xpAtual = prefs.getInt(_chaveXp) ?? 0;
    final novoXp = (xpAtual - quantidade).clamp(0, 999999);

    await prefs.setInt(_chaveXp, novoXp);

    // Não remove conquistas já desbloqueadas.
    return novoXp;
  }

  Future<void> _verificarConquistas(int xp) async {
    if (xp >= 100) {
      await _conquistaService.salvarDesbloqueada('centenario');
    }

    if (xp >= 500) {
      await _conquistaService.salvarDesbloqueada('evoluindo');
    }

    final nivel = calcularNivel(xp);

    if (nivel >= 10) {
      await _conquistaService.salvarDesbloqueada('mestre');
    }
  }

  int calcularNivel(int xp) {
    return (xp ~/ 100) + 1;
  }

  double calcularProgresso(int xp) {
    return (xp % 100) / 100;
  }

  int xpParaProximoNivel(int xp) {
    return 100 - (xp % 100);
  }
}
