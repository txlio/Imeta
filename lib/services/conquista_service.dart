import 'package:shared_preferences/shared_preferences.dart';

import '../models/conquista.dart';

class ConquistaService {
  static const String _chaveConquistas = 'conquistas_desbloqueadas';
  static const String _chaveTotalTarefas = 'conquistas_total_tarefas';
  static const String _chaveIdsTarefas = 'conquistas_ids_tarefas_contabilizadas';
  static const String _chaveIdsHabitos = 'conquistas_ids_habitos_contabilizados';
  static const String _chaveMelhorSequenciaHabitos =
      'conquistas_melhor_sequencia_habitos';

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

  /// Migração única das tarefas que já estavam concluídas.
  Future<void> inicializarHistoricoTarefas(
    List<int> tarefasConcluidasIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_chaveTotalTarefas)) return;

    final ids = tarefasConcluidasIds.map((id) => id.toString()).toSet();
    await prefs.setStringList(_chaveIdsTarefas, ids.toList());
    await prefs.setInt(_chaveTotalTarefas, ids.length);

    if (ids.isNotEmpty) await salvarDesbloqueada('primeiro_passo');
    if (ids.length >= 10) await salvarDesbloqueada('dez_tarefas');
    if (ids.length >= 50) await salvarDesbloqueada('cinquenta_tarefas');
  }

  /// Conta cada tarefa apenas uma vez pelo seu ID.
  Future<int> registrarTarefaConcluida(int tarefaId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_chaveIdsTarefas) ?? <String>[];
    final id = tarefaId.toString();

    if (ids.contains(id)) return prefs.getInt(_chaveTotalTarefas) ?? 0;

    ids.add(id);
    await prefs.setStringList(_chaveIdsTarefas, ids);
    final total = (prefs.getInt(_chaveTotalTarefas) ?? 0) + 1;
    await prefs.setInt(_chaveTotalTarefas, total);

    if (total >= 1) await salvarDesbloqueada('primeiro_passo');
    if (total >= 10) await salvarDesbloqueada('dez_tarefas');
    if (total >= 50) await salvarDesbloqueada('cinquenta_tarefas');
    return total;
  }

  /// Registra o primeiro hábito concluído e a melhor sequência já atingida.
  /// A conquista permanece salva mesmo se o hábito for desmarcado ou excluído.
  Future<void> registrarHabitoConcluido(
    int habitoId,
    int diasSequencia,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_chaveIdsHabitos) ?? <String>[];
    final id = habitoId.toString();

    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList(_chaveIdsHabitos, ids);
    }

    if (ids.isNotEmpty) {
      await salvarDesbloqueada('primeiro_habito');
    }

    final melhorSequencia =
        prefs.getInt(_chaveMelhorSequenciaHabitos) ?? 0;
    if (diasSequencia > melhorSequencia) {
      await prefs.setInt(_chaveMelhorSequenciaHabitos, diasSequencia);
    }

    if (diasSequencia >= 7 ||
        (prefs.getInt(_chaveMelhorSequenciaHabitos) ?? 0) >= 7) {
      await salvarDesbloqueada('fogo_aceso');
    }
  }

  Future<List<Conquista>> carregarConquistas({
    required int tarefasConcluidas,
    required int diasSequencia,
    required int metasConcluidas,
    required int xp,
    required int nivel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final desbloqueadas = await carregarDesbloqueadas();
    final totalTarefas =
        prefs.getInt(_chaveTotalTarefas) ?? tarefasConcluidas;
    final melhorSequencia = prefs.getInt(_chaveMelhorSequenciaHabitos) ?? 0;
    final progressoSequencia =
        diasSequencia > melhorSequencia ? diasSequencia : melhorSequencia;

    final definicoes = <Conquista>[
      Conquista(
        id: 'primeiro_passo', titulo: 'Primeiro passo',
        descricao: 'Conclua sua primeira tarefa.', emoji: '🏅',
        objetivo: 1, progresso: totalTarefas,
        desbloqueada: totalTarefas >= 1 || desbloqueadas.contains('primeiro_passo'),
      ),
      Conquista(
        id: 'dez_tarefas', titulo: 'Produtividade',
        descricao: 'Conclua 10 tarefas diferentes.', emoji: '⚡',
        objetivo: 10, progresso: totalTarefas,
        desbloqueada: totalTarefas >= 10 || desbloqueadas.contains('dez_tarefas'),
      ),
      Conquista(
        id: 'cinquenta_tarefas', titulo: 'Máquina de tarefas',
        descricao: 'Conclua 50 tarefas diferentes.', emoji: '🏆',
        objetivo: 50, progresso: totalTarefas,
        desbloqueada: totalTarefas >= 50 || desbloqueadas.contains('cinquenta_tarefas'),
      ),
      Conquista(
        id: 'primeiro_habito', titulo: 'Novo compromisso',
        descricao: 'Conclua seu primeiro hábito.', emoji: '🌱',
        objetivo: 1,
        progresso: desbloqueadas.contains('primeiro_habito') ? 1 : 0,
        desbloqueada: desbloqueadas.contains('primeiro_habito'),
      ),
      Conquista(
        id: 'fogo_aceso', titulo: 'Fogo aceso',
        descricao: 'Mantenha uma sequência de 7 dias em um hábito.', emoji: '🔥',
        objetivo: 7, progresso: progressoSequencia,
        desbloqueada: progressoSequencia >= 7 || desbloqueadas.contains('fogo_aceso'),
      ),
      Conquista(
        id: 'meta_alcancada', titulo: 'Meta alcançada',
        descricao: 'Conclua sua primeira meta.', emoji: '🎯',
        objetivo: 1, progresso: metasConcluidas,
        desbloqueada: metasConcluidas >= 1 || desbloqueadas.contains('meta_alcancada'),
      ),
      Conquista(
        id: 'centenario', titulo: 'Centenário',
        descricao: 'Acumule 100 XP.', emoji: '⚡',
        objetivo: 100, progresso: xp,
        desbloqueada: xp >= 100 || desbloqueadas.contains('centenario'),
      ),
      Conquista(
        id: 'evoluindo', titulo: 'Evoluindo',
        descricao: 'Acumule 500 XP.', emoji: '🚀',
        objetivo: 500, progresso: xp,
        desbloqueada: xp >= 500 || desbloqueadas.contains('evoluindo'),
      ),
      Conquista(
        id: 'mestre', titulo: 'Mestre',
        descricao: 'Alcance o nível 10.', emoji: '👑',
        objetivo: 10, progresso: nivel,
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
