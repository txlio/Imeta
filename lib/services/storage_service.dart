import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meta.dart';
import '../models/tarefa.dart';
import '../models/habito.dart';

class StorageService {
  static const String _chaveMetas = 'metas';
  static const String _chaveTarefas = 'tarefas';
  static const String _chaveHabitos = 'habitos';

  // =========================
  // METAS
  // =========================

  Future<void> salvarMetas(List<Meta> metas) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = metas.map((meta) {
      return {
        'id': meta.id,
        'titulo': meta.titulo,
        'descricao': meta.descricao,
        'prazo': meta.prazo?.toIso8601String(),
        'valorMeta': meta.valorMeta,
        'valorAtual': meta.valorAtual,
      };
    }).toList();

    await prefs.setString(
      _chaveMetas,
      jsonEncode(lista),
    );
  }

  Future<List<Meta>> carregarMetas() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString(_chaveMetas);

    if (dados == null) {
      return [];
    }

    final List<dynamic> lista = jsonDecode(dados);

    return lista.map((item) {
      return Meta(
        id: item['id'],
        titulo: item['titulo'],
        descricao: item['descricao'] ?? '',
        prazo: item['prazo'] != null
            ? DateTime.parse(item['prazo'])
            : null,
        valorMeta: (item['valorMeta'] as num).toDouble(),
        valorAtual: (item['valorAtual'] as num).toDouble(),
      );
    }).toList();
  }

  // =========================
  // TAREFAS
  // =========================

  Future<void> salvarTarefas(List<Tarefa> tarefas) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = tarefas.map((tarefa) {
      return {
        'id': tarefa.id,
        'titulo': tarefa.titulo,
        'descricao': tarefa.descricao,
        'concluida': tarefa.concluida,
        'prioridade': tarefa.prioridade,
      };
    }).toList();

    await prefs.setString(
      _chaveTarefas,
      jsonEncode(lista),
    );
  }

  Future<List<Tarefa>> carregarTarefas() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString(_chaveTarefas);

    if (dados == null) {
      return [];
    }

    final List<dynamic> lista = jsonDecode(dados);

    return lista.map((item) {
      return Tarefa(
        id: item['id'],
        titulo: item['titulo'],
        descricao: item['descricao'] ?? '',
        concluida: item['concluida'] ?? false,
        prioridade: item['prioridade'] ?? 'Média',
      );
    }).toList();
  }

  // =========================
  // HÁBITOS
  // =========================

  Future<void> salvarHabitos(List<Habito> habitos) async {
    final prefs = await SharedPreferences.getInstance();

    final lista = habitos.map((habito) {
      return {
        'id': habito.id,
        'titulo': habito.titulo,
        'diasConcluidos': habito.diasConcluidos,
      };
    }).toList();

    await prefs.setString(
      _chaveHabitos,
      jsonEncode(lista),
    );
  }

  Future<List<Habito>> carregarHabitos() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString(_chaveHabitos);

    if (dados == null) {
      return [];
    }

    final List<dynamic> lista = jsonDecode(dados);

    return lista.map((item) {
      return Habito(
        id: item['id'],
        titulo: item['titulo'],
        diasConcluidos: List<String>.from(
          item['diasConcluidos'] ?? [],
        ),
      );
    }).toList();
  }
}