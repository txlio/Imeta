import 'package:shared_preferences/shared_preferences.dart';

import '../models/conquista.dart';

class ConquistaService {
  static const String _chaveConquistas = 'conquistas_desbloqueadas';

  Future<Set<String>> carregarDesbloqueadas() async {
    final prefs = await SharedPreferences.getInstance();

    return (prefs.getStringList(_chaveConquistas) ?? []).toSet();
  }

  Future<void> salvarDesbloqueada(String id) async {
    final prefs = await SharedPreferences.getInstance();

    final desbloqueadas = prefs.getStringList(_chaveConquistas) ?? [];

    if (!desbloqueadas.contains(id)) {
      desbloqueadas.add(id);

      await prefs.setStringList(_chaveConquistas, desbloqueadas);
    }
  }

  Future<bool> estaDesbloqueada(String id) async {
    final desbloqueadas = await carregarDesbloqueadas();

    return desbloqueadas.contains(id);
  }

  Future<List<Conquista>> carregarConquistas({
    required int tarefasConcluidas,
    required int diasSequencia,
    required int metasConcluidas,
    required int xp,
    required int nivel,
  }) async {
    final desbloqueadas = await carregarDesbloqueadas();

    final definicoes = <Conquista>[
      Conquista(
        id: 'primeiro_passo',
        titulo: 'Primeiro passo',
        descricao: 'Conclua sua primeira tarefa.',
        emoji: '🏅',
        objetivo: 1,
        progresso: tarefasConcluidas,
        desbloqueada:
            tarefasConcluidas >= 1 || desbloqueadas.contains('primeiro_passo'),
      ),
      Conquista(
        id: 'fogo_aceso',
        titulo: 'Fogo aceso',
        descricao: 'Mantenha uma sequência de 7 dias em um hábito.',
        emoji: '🔥',
        objetivo: 7,
        progresso: diasSequencia,
        desbloqueada:
            diasSequencia >= 7 || desbloqueadas.contains('fogo_aceso'),
      ),
      Conquista(
        id: 'meta_alcancada',
        titulo: 'Meta alcançada',
        descricao: 'Conclua sua primeira meta.',
        emoji: '🎯',
        objetivo: 1,
        progresso: metasConcluidas,
        desbloqueada:
            metasConcluidas >= 1 || desbloqueadas.contains('meta_alcancada'),
      ),
      Conquista(
        id: 'centenario',
        titulo: 'Centenário',
        descricao: 'Acumule 100 XP.',
        emoji: '⚡',
        objetivo: 100,
        progresso: xp,
        desbloqueada: xp >= 100 || desbloqueadas.contains('centenario'),
      ),
      Conquista(
        id: 'evoluindo',
        titulo: 'Evoluindo',
        descricao: 'Acumule 500 XP.',
        emoji: '🚀',
        objetivo: 500,
        progresso: xp,
        desbloqueada: xp >= 500 || desbloqueadas.contains('evoluindo'),
      ),
      Conquista(
        id: 'mestre',
        titulo: 'Mestre',
        descricao: 'Alcance o nível 10.',
        emoji: '👑',
        objetivo: 10,
        progresso: nivel,
        desbloqueada: nivel >= 10 || desbloqueadas.contains('mestre'),
      ),
    ];

    for (final conquista in definicoes) {
      if (conquista.desbloqueada) {
        await salvarDesbloqueada(conquista.id);
      }
    }

    return definicoes;
  }
}
