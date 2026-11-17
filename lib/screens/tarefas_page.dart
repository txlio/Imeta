
import 'package:flutter/material.dart';

import '../models/tarefa.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../services/conquista_service.dart';

class TarefasPage extends StatefulWidget {
  const TarefasPage({super.key});

  @override
  State<TarefasPage> createState() => _TarefasPageState();
}

class _TarefasPageState extends State<TarefasPage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();
  final ConquistaService _conquistaService = ConquistaService();

  List<Tarefa> _tarefas = [];

  final TextEditingController _tituloController =
      TextEditingController();

  final TextEditingController _descricaoController =
      TextEditingController();

  final TextEditingController _pesquisaController =
      TextEditingController();

  static const List<String> _categorias = [
    'Trabalho',
    'Estudos',
    'Pessoal',
    'Saúde',
    'Outros',
  ];

  String _prioridadeSelecionada = 'Média';
  String _categoriaSelecionada = 'Pessoal';

  String _filtroStatus = 'Todas';
  String _filtroPrioridade = 'Todas';
  String _filtroCategoria = 'Todas';

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
    _pesquisaController.dispose();
    super.dispose();
  }

  // =========================
  // CARREGAMENTO E SALVAMENTO
  // =========================

  Future<void> _carregarTarefas() async {
    final tarefasSalvas = await _storage.carregarTarefas();

    await _conquistaService.inicializarHistoricoTarefas(
      tarefasSalvas
          .where((tarefa) => tarefa.concluida)
          .map((tarefa) => tarefa.id)
          .toList(),
    );

    if (!mounted) return;

    setState(() {
      _tarefas = tarefasSalvas;
      _carregando = false;
    });
  }

  Future<void> _salvarTarefas() async {
    await _storage.salvarTarefas(_tarefas);
  }

  // =========================
  // CADASTRAR E EDITAR TAREFAS
  // =========================

  void _limparFormulario() {
    _tituloController.clear();
    _descricaoController.clear();

    _prioridadeSelecionada = 'Média';
    _categoriaSelecionada = 'Pessoal';
  }

  Future<void> _salvarTarefa({Tarefa? tarefaExistente}) async {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome da tarefa.'),
        ),
      );
      return;
    }

    if (tarefaExistente != null) {
      // Atualiza os dados sem perder o lembrete,
      // o status de conclusão ou os pontos de XP.
      tarefaExistente.titulo = titulo;
      tarefaExistente.descricao =
          _descricaoController.text.trim();
      tarefaExistente.prioridade = _prioridadeSelecionada;
      tarefaExistente.categoria = _categoriaSelecionada;

      setState(() {});
    } else {
      final novaTarefa = Tarefa(
        id: DateTime.now().millisecondsSinceEpoch,
        titulo: titulo,
        descricao: _descricaoController.text.trim(),
        prioridade: _prioridadeSelecionada,
        categoria: _categoriaSelecionada,
      );

      setState(() {
        _tarefas.add(novaTarefa);
      });
    }

    await _salvarTarefas();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tarefaExistente != null
              ? 'Tarefa atualizada com sucesso!'
              : 'Tarefa cadastrada com sucesso!',
        ),
      ),
    );
  }

  void _abrirFormulario({Tarefa? tarefa}) {
    _limparFormulario();

    if (tarefa != null) {
      _tituloController.text = tarefa.titulo;
      _descricaoController.text = tarefa.descricao;
      _prioridadeSelecionada = tarefa.prioridade;

      _categoriaSelecionada =
          _categorias.contains(tarefa.categoria)
              ? tarefa.categoria
              : 'Outros';
    }

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
                    Text(
                      tarefa != null
                          ? 'Editar Tarefa'
                          : 'Nova Tarefa',
                      style: const TextStyle(
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
                        prefixIcon: Icon(Icons.task_alt),
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
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: _prioridadeSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
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

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: _categoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setModalState(() {
                          _categoriaSelecionada = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _salvarTarefa(
                            tarefaExistente: tarefa,
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: Text(
                          tarefa != null
                              ? 'SALVAR ALTERAÇÕES'
                              : 'SALVAR TAREFA',
                          style: const TextStyle(
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

  // =========================
  // CONCLUIR E REABRIR TAREFAS
  // =========================

  Future<void> _alternarTarefa(Tarefa tarefa) async {
    final estavaConcluida = tarefa.concluida;

    setState(() {
      tarefa.concluida = !tarefa.concluida;
    });

    await _salvarTarefas();

    if (!estavaConcluida) {
      await _xpService.adicionarXp(
        XpService.xpTarefa,
      );

      // Conta esta tarefa apenas uma vez no histórico de conquistas.
      // Reabrir e concluir novamente não duplica a contagem.
      await _conquistaService.registrarTarefaConcluida(tarefa.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Tarefa concluída! +10 XP'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
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

  // =========================
  // EXCLUIR TAREFAS
  // =========================

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

    if (confirmar != true) return;

    setState(() {
      _tarefas.remove(tarefa);
    });

    await _salvarTarefas();

    if (tarefa.concluida) {
      await _xpService.removerXp(
        XpService.xpTarefa,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarefa excluída.'),
        ),
      );
    }
  }

  // =========================
  // FILTROS
  // =========================

  List<Tarefa> get _tarefasFiltradas {
    return _tarefas.where((tarefa) {
      final pesquisa = _pesquisaController.text
          .trim()
          .toLowerCase();

      final correspondePesquisa =
          tarefa.titulo.toLowerCase().contains(pesquisa) ||
          tarefa.descricao.toLowerCase().contains(pesquisa);

      final correspondeStatus =
          _filtroStatus == 'Todas' ||
          (_filtroStatus == 'Pendentes' && !tarefa.concluida) ||
          (_filtroStatus == 'Concluídas' && tarefa.concluida);

      final correspondePrioridade =
          _filtroPrioridade == 'Todas' ||
          tarefa.prioridade == _filtroPrioridade;

      final correspondeCategoria =
          _filtroCategoria == 'Todas' ||
          tarefa.categoria == _filtroCategoria;

      return correspondePesquisa &&
          correspondeStatus &&
          correspondePrioridade &&
          correspondeCategoria;
    }).toList();
  }

  void _limparFiltros() {
    setState(() {
      _pesquisaController.clear();
      _filtroStatus = 'Todas';
      _filtroPrioridade = 'Todas';
      _filtroCategoria = 'Todas';
    });
  }

  // =========================
  // CORES
  // =========================

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

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'Trabalho':
        return Colors.blue;

      case 'Estudos':
        return Colors.purple;

      case 'Saúde':
        return Colors.green;

      case 'Pessoal':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // =========================
  // TELA
  // =========================

  @override
  Widget build(BuildContext context) {
    final tarefasPendentes =
        _tarefas.where((tarefa) => !tarefa.concluida).length;

    final tarefasConcluidas =
        _tarefas.where((tarefa) => tarefa.concluida).length;

    final tarefasVisiveis = _tarefasFiltradas;

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
        onPressed: () => _abrirFormulario(),
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
                    // CONTADORES
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

                    const SizedBox(height: 20),

                    // PESQUISA
                    TextField(
                      controller: _pesquisaController,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Pesquisar tarefa...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _pesquisaController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _pesquisaController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // FILTRO DE STATUS
                    DropdownButtonFormField<String>(
                      initialValue: _filtroStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.filter_list),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Todas',
                          child: Text('Todas as tarefas'),
                        ),
                        DropdownMenuItem(
                          value: 'Pendentes',
                          child: Text('Pendentes'),
                        ),
                        DropdownMenuItem(
                          value: 'Concluídas',
                          child: Text('Concluídas'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setState(() {
                          _filtroStatus = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // FILTROS DE PRIORIDADE E CATEGORIA
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroPrioridade,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Prioridade',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Todas',
                                child: Text('Todas'),
                              ),
                              DropdownMenuItem(
                                value: 'Alta',
                                child: Text('Alta'),
                              ),
                              DropdownMenuItem(
                                value: 'Média',
                                child: Text('Média'),
                              ),
                              DropdownMenuItem(
                                value: 'Baixa',
                                child: Text('Baixa'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor == null) return;

                              setState(() {
                                _filtroPrioridade = valor;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroCategoria,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'Todas',
                                child: Text('Todas'),
                              ),
                              ..._categorias.map((categoria) {
                                return DropdownMenuItem(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }),
                            ],
                            onChanged: (valor) {
                              if (valor == null) return;

                              setState(() {
                                _filtroCategoria = valor;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _limparFiltros,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Limpar filtros'),
                      ),
                    ),

                    const Divider(height: 25),

                    // RESULTADO DOS FILTROS
                    Text(
                      '${tarefasVisiveis.length} tarefa(s) encontrada(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (tarefasVisiveis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'Nenhuma tarefa encontrada com esses filtros.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // LISTA DE TAREFAS
                    ...tarefasVisiveis.map((tarefa) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tarefa.descricao.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(tarefa.descricao),
                                ),

                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // PRIORIDADE
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _corPrioridade(
                                        tarefa.prioridade,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
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

                                  // CATEGORIA
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _corCategoria(
                                        tarefa.categoria,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tarefa.categoria,
                                      style: TextStyle(
                                        color: _corCategoria(
                                          tarefa.categoria,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // LEMBRETE JÁ CADASTRADO
                                  if (tarefa.dataLembrete != null)
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.notifications_active_outlined,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Lembrete',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),

                          trailing: PopupMenuButton<String>(
                            onSelected: (valor) {
                              if (valor == 'editar') {
                                _abrirFormulario(tarefa: tarefa);
                              }

                              if (valor == 'excluir') {
                                _excluirTarefa(tarefa);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
