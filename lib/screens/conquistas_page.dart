
import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../services/conquista_service.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class ConquistasPage extends StatefulWidget {
  const ConquistasPage({super.key});

  @override
  State<ConquistasPage> createState() => _ConquistasPageState();
}

class _ConquistasPageState extends State<ConquistasPage> {
  final ConquistaService _conquistaService = ConquistaService();
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();

  List<Conquista> _conquistas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarConquistas();
  }

  Future<void> _carregarConquistas() async {
    try {
      final tarefas = await _storage.carregarTarefas();
      final metas = await _storage.carregarMetas();
      final habitos = await _storage.carregarHabitos();
      final xp = await _xpService.carregarXp();

      final tarefasConcluidas =
          tarefas.where((tarefa) => tarefa.concluida).length;

      final metasConcluidas =
          metas.where((meta) => meta.concluida).length;

      int maiorSequencia = 0;

      for (final habito in habitos) {
        if (habito.sequencia > maiorSequencia) {
          maiorSequencia = habito.sequencia;
        }
      }

      final nivel = _xpService.calcularNivel(xp);

      final conquistas =
          await _conquistaService.carregarConquistas(
        tarefasConcluidas: tarefasConcluidas,
        diasSequencia: maiorSequencia,
        metasConcluidas: metasConcluidas,
        xp: xp,
        nivel: nivel,
      );

      if (!mounted) return;

      setState(() {
        _conquistas = conquistas;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar conquistas: $e'),
        ),
      );
    }
  }

  Widget _construirCard(Conquista conquista) {
    final desbloqueada = conquista.desbloqueada;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: desbloqueada
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    conquista.emoji,
                    style: TextStyle(
                      fontSize: 30,
                      color: desbloqueada ? null : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conquista.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conquista.descricao,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  desbloqueada
                      ? Icons.verified
                      : Icons.lock_outline,
                  color: desbloqueada
                      ? Colors.amber.shade800
                      : Colors.grey,
                  size: 27,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  desbloqueada ? 'Desbloqueada' : 'Progresso',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: desbloqueada
                        ? Colors.green
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${conquista.progresso}/${conquista.objetivo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: conquista.percentual,
                minHeight: 9,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  desbloqueada ? Colors.green : Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desbloqueadas =
        _conquistas.where((c) => c.desbloqueada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conquistas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _carregarConquistas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar conquistas',
          ),
        ],
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _carregarConquistas,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            size: 48,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sua coleção de medalhas',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$desbloqueadas de ${_conquistas.length} conquistas desbloqueadas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: _conquistas.isEmpty
                                ? 0
                                : desbloqueadas / _conquistas.length,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Todas as conquistas',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ..._conquistas.map(_construirCard),
                ],
              ),
            ),
    );
  }
}
