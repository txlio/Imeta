import 'package:flutter/material.dart';

import '../models/tarefa.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();

  List<Tarefa> _tarefas = [];

  final TextEditingController _tituloController =
      TextEditingController();

  final TextEditingController _descricaoController =
      TextEditingController();

  String _prioridadeSelecionada = 'Média';

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    final tarefasSalvas = await _storage.carregarTarefas();

    if (!mounted) return;

    setState(() {
      _tarefas = tarefasSalvas;
      _carregando = false;
    });
  }

  Future<void> _salvarTarefas() async {
    await _storage.salvarTarefas(_tarefas);
  }

  Future<void> _salvarTarefa() async {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome da tarefa.'),
        ),
      );

      return;
    }

    final novaTarefa = Tarefa(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: titulo,
      descricao: _descricaoController.text.trim(),
      prioridade: _prioridadeSelecionada,
    );

    setState(() {
      _tarefas.add(novaTarefa);
    });

    await _salvarTarefas();

    _limparFormulario();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _limparFormulario() {
    _tituloController.clear();
    _descricaoController.clear();
    _prioridadeSelecionada = 'Média';
  }

  Future<void> _alternarTarefa(Tarefa tarefa) async {
    // Guarda o estado anterior para saber se estamos
    // concluindo ou desfazendo a conclusão.
    final estavaConcluida = tarefa.concluida;

    setState(() {
      tarefa.concluida = !tarefa.concluida;
    });

    await _salvarTarefas();

    // Tarefa pendente -> concluída
    if (!estavaConcluida) {
      await _xpService.adicionarXp(
        XpService.xpTarefa,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tarefa concluída! +10 XP'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Tarefa concluída -> pendente
    else {
      await _xpService.removerXp(
        XpService.xpTarefa,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('↩️ Tarefa reaberta! -10 XP'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _excluirTarefa(Tarefa tarefa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir tarefa?'),
          content: Text(
            'Deseja realmente excluir "${tarefa.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _tarefas.remove(tarefa);
    });

    await _salvarTarefas();

    // Se a tarefa excluída estava concluída,
    // retiramos os 10 XP que ela havia concedido.
    if (tarefa.concluida) {
      await _xpService.removerXp(
        XpService.xpTarefa,
      );
    }
  }

  void _abrirFormulario() {
    _limparFormulario();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Tarefa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da tarefa',
                        hintText: 'Ex: Estudar Flutter',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Descreva a tarefa...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: _prioridadeSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Baixa',
                          child: Text('Baixa'),
                        ),
                        DropdownMenuItem(
                          value: 'Média',
                          child: Text('Média'),
                        ),
                        DropdownMenuItem(
                          value: 'Alta',
                          child: Text('Alta'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setModalState(() {
                          _prioridadeSelecionada = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _salvarTarefa,
                        child: const Text(
                          'SALVAR TAREFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _corPrioridade(String prioridade) {
    switch (prioridade) {
      case 'Alta':
        return Colors.red;

      case 'Baixa':
        return Colors.green;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarefasPendentes =
        _tarefas.where((tarefa) => !tarefa.concluida).length;

    final tarefasConcluidas =
        _tarefas.where((tarefa) => tarefa.concluida).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tarefas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add),
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _tarefas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma tarefa cadastrada.',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Clique no + para criar sua primeira tarefa.',
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '$tarefasPendentes',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Pendentes'),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '$tarefasConcluidas',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Concluídas'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ..._tarefas.map(
                      (tarefa) {
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: tarefa.concluida,
                              onChanged: (_) {
                                _alternarTarefa(tarefa);
                              },
                            ),

                            title: Text(
                              tarefa.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: tarefa.concluida
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (tarefa.descricao.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                    ),
                                    child: Text(
                                      tarefa.descricao,
                                    ),
                                  ),

                                const SizedBox(height: 6),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _corPrioridade(
                                      tarefa.prioridade,
                                    ).withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tarefa.prioridade,
                                    style: TextStyle(
                                      color: _corPrioridade(
                                        tarefa.prioridade,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            trailing: PopupMenuButton<String>(
                              onSelected: (valor) {
                                if (valor == 'excluir') {
                                  _excluirTarefa(tarefa);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'excluir',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}