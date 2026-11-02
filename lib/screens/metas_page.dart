import 'package:flutter/material.dart';

import '../models/meta.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();

  List<Meta> _metas = [];

  final TextEditingController _tituloController =
      TextEditingController();

  final TextEditingController _descricaoController =
      TextEditingController();

  final TextEditingController _valorController =
      TextEditingController();

  final TextEditingController _valorAdicionarController =
      TextEditingController();

  DateTime? _dataSelecionada;

  bool _metaFinanceira = false;

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    _valorAdicionarController.dispose();

    super.dispose();
  }

  // =========================
  // CARREGAR METAS
  // =========================

  Future<void> _carregarMetas() async {
    final metasSalvas = await _storage.carregarMetas();

    if (!mounted) return;

    setState(() {
      _metas = metasSalvas;
      _carregando = false;
    });
  }

  // =========================
  // SALVAR METAS
  // =========================

  Future<void> _salvarMetas() async {
    await _storage.salvarMetas(_metas);
  }

  // =========================
  // SELECIONAR DATA
  // =========================

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  // =========================
  // SALVAR NOVA META
  // =========================

  Future<void> _salvarMeta() async {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite o nome da meta.',
          ),
        ),
      );

      return;
    }

    double valor = 0;

    if (_metaFinanceira &&
        _valorController.text.isNotEmpty) {
      valor = double.tryParse(
            _valorController.text.replaceAll(',', '.'),
          ) ??
          0;
    }

    final novaMeta = Meta(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: titulo,
      descricao: _descricaoController.text.trim(),
      prazo: _dataSelecionada,
      valorMeta: valor,
      valorAtual: 0,
    );

    setState(() {
      _metas.add(novaMeta);
    });

    await _salvarMetas();

    _tituloController.clear();
    _descricaoController.clear();
    _valorController.clear();

    _dataSelecionada = null;
    _metaFinanceira = false;

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // =========================
  // ADICIONAR VALOR
  // =========================

  Future<void> _adicionarValor(Meta meta) async {
    _valorAdicionarController.clear();

    final valor = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Adicionar valor',
          ),
          content: TextField(
            controller: _valorAdicionarController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = double.tryParse(
                  _valorAdicionarController.text
                      .replaceAll(',', '.'),
                );

                if (valor == null || valor <= 0) {
                  return;
                }

                Navigator.pop(context, valor);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (valor == null || valor <= 0) {
      return;
    }

    // Guarda o estado antes da alteração.
    final estavaConcluida = meta.concluida;

    setState(() {
      meta.valorAtual += valor;

      if (meta.valorAtual > meta.valorMeta &&
          meta.valorMeta > 0) {
        meta.valorAtual = meta.valorMeta;
      }
    });

    await _salvarMetas();

    // =========================
    // META FOI CONCLUÍDA
    // =========================

    if (!estavaConcluida && meta.concluida) {
      await _xpService.adicionarXp(
        XpService.xpMeta,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎯 Meta concluída! +50 XP',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // =========================
  // EXCLUIR META
  // =========================

  Future<void> _excluirMeta(Meta meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir meta?',
          ),
          content: Text(
            'Deseja realmente excluir "${meta.titulo}"?',
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

    final estavaConcluida = meta.concluida;

    setState(() {
      _metas.remove(meta);
    });

    await _salvarMetas();

    // Se a meta concluída foi excluída,
    // remove os 50 XP que ela concedeu.
    if (estavaConcluida) {
      await _xpService.removerXp(
        XpService.xpMeta,
      );
    }
  }

  // =========================
  // ABRIR FORMULÁRIO
  // =========================

  void _abrirFormulario() {
    _tituloController.clear();
    _descricaoController.clear();
    _valorController.clear();

    _dataSelecionada = null;
    _metaFinanceira = false;

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
                    MediaQuery.of(context).viewInsets.bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Meta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _tituloController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Nome da meta',
                        hintText:
                            'Ex: Comprar um celular',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText: 'Descrição',
                        hintText:
                            'Descreva sua meta...',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        await _selecionarData();
                        setModalState(() {});
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Prazo',
                          border:
                              OutlineInputBorder(),
                        ),
                        child: Text(
                          _dataSelecionada == null
                              ? 'Selecionar data'
                              : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/'
                                  '${_dataSelecionada!.month.toString().padLeft(2, '0')}/'
                                  '${_dataSelecionada!.year}',
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Meta financeira?',
                      ),
                      value: _metaFinanceira,
                      onChanged: (valor) {
                        setModalState(() {
                          _metaFinanceira =
                              valor;
                        });
                      },
                    ),

                    if (_metaFinanceira) ...[
                      const SizedBox(height: 10),

                      TextField(
                        controller:
                            _valorController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Valor da meta',
                          hintText: '4000',
                          prefixText: 'R\$ ',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _salvarMeta,
                        child: const Text(
                          'SALVAR META',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
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
  // FORMATAR VALOR
  // =========================

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // =========================
  // FORMATAR PRAZO
  // =========================

  String _formatarPrazo(DateTime? prazo) {
    if (prazo == null) {
      return 'Sem prazo definido';
    }

    final hoje = DateTime.now();

    final hojeSemHora = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    final prazoSemHora = DateTime(
      prazo.year,
      prazo.month,
      prazo.day,
    );

    final dias = prazoSemHora
        .difference(hojeSemHora)
        .inDays;

    if (dias < 0) {
      return 'Prazo encerrado';
    }

    if (dias == 0) {
      return 'Termina hoje';
    }

    if (dias == 1) {
      return '1 dia restante';
    }

    return '$dias dias restantes';
  }

  // =========================
  // INTERFACE
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Metas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add),
      ),

      body: _carregando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _metas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma meta cadastrada.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount: _metas.length,
                  itemBuilder:
                      (context, index) {
                    final meta =
                        _metas[index];

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 15,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meta.titulo,
                                    style:
                                        const TextStyle(
                                      fontSize: 19,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),

                                PopupMenuButton<
                                    String>(
                                  onSelected:
                                      (valor) {
                                    if (valor ==
                                        'excluir') {
                                      _excluirMeta(
                                        meta,
                                      );
                                    }
                                  },
                                  itemBuilder:
                                      (context) =>
                                          [
                                    const PopupMenuItem(
                                      value:
                                          'excluir',
                                      child:
                                          Text(
                                        'Excluir',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (meta
                                .descricao
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                meta.descricao,
                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],

                            const SizedBox(
                              height: 12,
                            ),

                            LinearProgressIndicator(
                              value:
                                  meta.progresso,
                              minHeight: 8,
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            if (meta.valorMeta >
                                0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Text(
                                    '${_formatarValor(meta.valorAtual)} / '
                                    '${_formatarValor(meta.valorMeta)}',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  Text(
                                    '${(meta.progresso * 100).toStringAsFixed(0)}%',
                                  ),
                                ],
                              ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              _formatarPrazo(
                                meta.prazo,
                              ),
                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),

                            if (meta.valorMeta >
                                    0 &&
                                !meta.concluida) ...[
                              const SizedBox(
                                height: 12,
                              ),

                              SizedBox(
                                width:
                                    double.infinity,
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed: () {
                                    _adicionarValor(
                                      meta,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.add,
                                  ),
                                  label:
                                      const Text(
                                    'Adicionar valor',
                                  ),
                                ),
                              ),
                            ],

                            if (meta.concluida) ...[
                              const SizedBox(
                                height: 12,
                              ),

                              const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle,
                                    color:
                                        Colors.green,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Meta concluída! 🎉',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}