
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
  bool _salvando = false;

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
    try {
      final metasSalvas = await _storage.carregarMetas();

      if (!mounted) return;

      setState(() {
        _metas = metasSalvas;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mensagem('Erro ao carregar metas: $e');
    }
  }

  // =========================
  // SALVAR METAS
  // =========================

  Future<void> _salvarMetas() async {
    await _storage.salvarMetas(_metas);
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // =========================
  // FORMATAR E CONVERTER DINHEIRO
  // =========================

  double _converterValor(String texto) {
    String valor = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (valor.contains(',')) {
      valor = valor
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }

    return double.tryParse(valor) ?? 0;
  }

  String _formatarValor(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final centavos = partes[1];

    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      buffer.write(inteiro[i]);

      final restantes = inteiro.length - i - 1;

      if (restantes > 0 && restantes % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$centavos';
  }

  // =========================
  // SELECIONAR DATA
  // =========================

  Future<void> _selecionarData({
    required StateSetter atualizarModal,
  }) async {
    final DateTime? data = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Selecione o prazo',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (data != null && mounted) {
      setState(() {
        _dataSelecionada = data;
      });

      atualizarModal(() {});
    }
  }

  // =========================
  // ADICIONAR XP UMA ÚNICA VEZ
  // =========================

  Future<void> _concederXp(Meta meta) async {
    if (meta.xpRecebido) return;

    // Marca antes de salvar para impedir duplicidade.
    meta.xpRecebido = true;

    try {
      await _xpService.adicionarXp(XpService.xpMeta);
      await _salvarMetas();
    } catch (e) {
      // Reverte o controle caso a operação falhe.
      meta.xpRecebido = false;
      rethrow;
    }

    if (mounted) {
      _mensagem('Meta concluída! Você ganhou 50 XP!');
    }
  }

  // =========================
  // CONCLUIR META
  // =========================

  Future<void> _concluirMeta(Meta meta) async {
    if (meta.concluida) return;

    setState(() {
      meta.concluida = true;
    });

    try {
      await _concederXp(meta);
      await _salvarMetas();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        meta.concluida = false;
      });

      _mensagem('Não foi possível concluir a meta: $e');
    }
  }

  // =========================
  // REABRIR META
  // =========================

  Future<void> _reabrirMeta(Meta meta) async {
    setState(() {
      meta.concluida = false;
    });

    await _salvarMetas();

    if (mounted) {
      _mensagem('Meta reaberta. Você pode continuar!');
      setState(() {});
    }
  }

  // =========================
  // CONCLUSÃO AUTOMÁTICA
  // =========================

  Future<void> _verificarConclusaoAutomatica(
    Meta meta,
  ) async {
    if (meta.atingiuValor && !meta.concluida) {
      await _concluirMeta(meta);
    }
  }

  // =========================
  // SALVAR OU EDITAR META
  // =========================

  Future<void> _salvarMeta({Meta? meta}) async {
    if (_salvando) return;

    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      _mensagem('Digite o nome da meta.');
      return;
    }

    final valor = _metaFinanceira
        ? _converterValor(_valorController.text)
        : 0.0;

    if (_metaFinanceira && valor <= 0) {
      _mensagem('Informe um valor válido para a meta.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      if (meta == null) {
        final novaMeta = Meta(
          id: DateTime.now().millisecondsSinceEpoch,
          titulo: titulo,
          descricao: _descricaoController.text.trim(),
          prazo: _dataSelecionada,
          valorMeta: valor,
          valorAtual: 0,
        );

        _metas.add(novaMeta);

        await _salvarMetas();
      } else {
        meta.titulo = titulo;
        meta.descricao = _descricaoController.text.trim();
        meta.prazo = _dataSelecionada;
        meta.valorMeta = valor;

        // Mantém o valor atual da meta durante a edição.
        if (!_metaFinanceira) {
          meta.valorAtual = 0;
        }

        await _salvarMetas();

        await _verificarConclusaoAutomatica(meta);
      }

      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      Navigator.pop(context);
      _mensagem(
        meta == null
            ? 'Meta cadastrada com sucesso!'
            : 'Meta atualizada com sucesso!',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      _mensagem('Erro ao salvar meta: $e');
    }
  }

  // =========================
  // ABRIR FORMULÁRIO
  // =========================

  void _abrirFormulario({Meta? meta}) {
    _tituloController.text = meta?.titulo ?? '';
    _descricaoController.text = meta?.descricao ?? '';

    _valorController.text = meta != null && meta.valorMeta > 0
        ? meta.valorMeta.toStringAsFixed(2).replaceAll('.', ',')
        : '';

    _dataSelecionada = meta?.prazo;
    _metaFinanceira = meta != null && meta.valorMeta > 0;
    _salvando = false;

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta == null ? 'Nova Meta' : 'Editar Meta',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                        hintText: 'Ex: Comprar um celular',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Descreva sua meta...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        await _selecionarData(
                          atualizarModal: setModalState,
                        );
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Prazo',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
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
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Meta financeira?'),
                      value: _metaFinanceira,
                      onChanged: (valor) {
                        setModalState(() {
                          _metaFinanceira = valor;
                        });
                      },
                    ),

                    if (_metaFinanceira) ...[
                      const SizedBox(height: 10),

                      TextField(
                        controller: _valorController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor da meta',
                          hintText: '1.500,00',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _salvando
                            ? null
                            : () => _salvarMeta(meta: meta),
                        child: Text(
                          _salvando
                              ? 'SALVANDO...'
                              : meta == null
                                  ? 'SALVAR META'
                                  : 'ATUALIZAR META',
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
  // ADICIONAR VALOR
  // =========================

  Future<void> _adicionarValor(Meta meta) async {
    _valorAdicionarController.clear();

    final valor = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar valor'),
          content: TextField(
            controller: _valorAdicionarController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              hintText: '100,00',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = _converterValor(
                  _valorAdicionarController.text,
                );

                if (valor <= 0) return;

                Navigator.pop(dialogContext, valor);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (valor == null || valor <= 0) return;

    setState(() {
      meta.valorAtual += valor;

      if (meta.valorAtual > meta.valorMeta) {
        meta.valorAtual = meta.valorMeta;
      }
    });

    try {
      await _verificarConclusaoAutomatica(meta);
      await _salvarMetas();

      if (mounted && !meta.concluida) {
        _mensagem('Valor adicionado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _mensagem('Erro ao atualizar valor: $e');
      }
    }
  }

  // =========================
  // EXCLUIR META
  // =========================

  Future<void> _excluirMeta(Meta meta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir meta?'),
          content: Text(
            'Deseja realmente excluir "${meta.titulo}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      _metas.remove(meta);
    });

    await _salvarMetas();

    if (mounted) {
      _mensagem('Meta excluída. XP conquistado foi preservado.');
    }
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

    final dias = prazoSemHora.difference(hojeSemHora).inDays;

    if (dias < 0) return 'Prazo encerrado';
    if (dias == 0) return 'Termina hoje';
    if (dias == 1) return '1 dia restante';

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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),

      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _metas.isEmpty
              ? const Center(
                  child: Text('Nenhuma meta cadastrada.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _metas.length,
                  itemBuilder: (context, index) {
                    final meta = _metas[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meta.titulo,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  onSelected: (valor) {
                                    if (valor == 'editar') {
                                      _abrirFormulario(meta: meta);
                                    } else if (valor == 'excluir') {
                                      _excluirMeta(meta);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'excluir',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Excluir'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (meta.descricao.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                meta.descricao,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            LinearProgressIndicator(
                              value: meta.progresso,
                              minHeight: 8,
                            ),

                            const SizedBox(height: 8),

                            if (meta.valorMeta > 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${_formatarValor(meta.valorAtual)} / '
                                      '${_formatarValor(meta.valorMeta)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(meta.progresso * 100).toStringAsFixed(0)}%',
                                  ),
                                ],
                              ),

                            const SizedBox(height: 6),

                            Text(
                              _formatarPrazo(meta.prazo),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (meta.concluida) ...[
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Meta concluída!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              if (meta.xpRecebido)
                                const Text(
                                  '+50 XP já recebido',
                                  style: TextStyle(
                                    color: Colors.green,
                                  ),
                                ),

                              OutlinedButton.icon(
                                onPressed: () => _reabrirMeta(meta),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reabrir meta'),
                              ),
                            ] else ...[
                              if (meta.valorMeta > 0)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _adicionarValor(meta),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar valor'),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _concluirMeta(meta),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Concluir meta'),
                                ),
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
