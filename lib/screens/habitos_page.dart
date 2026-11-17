
import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../services/storage_service.dart';
import '../services/conquista_service.dart';
import '../services/xp_service.dart';
import 'historico_habito_page.dart';

class HabitosPage extends StatefulWidget {
  const HabitosPage({super.key});

  @override
  State<HabitosPage> createState() => _HabitosPageState();
}

class _HabitosPageState extends State<HabitosPage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();
  final ConquistaService _conquistaService = ConquistaService();

  List<Habito> _habitos = [];

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarHabitos();
  }

  // =========================
  // DATA DE HOJE
  // =========================

  String _dataHoje() {
    final hoje = DateTime.now();

    return '${hoje.year}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';
  }

  // =========================
  // FORMATAR DATA
  // =========================

  String _dataFormatada(DateTime data) {
    return '${data.year}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  // =========================
  // CARREGAR HÁBITOS
  // =========================

  Future<void> _carregarHabitos() async {
    final habitosSalvos = await _storage.carregarHabitos();

    // Recupera conquistas de hábitos que já tinham histórico salvo.
    for (final habito in habitosSalvos) {
      if (habito.diasConcluidos.isNotEmpty) {
        await _conquistaService.registrarHabitoConcluido(
          habito.id,
          habito.sequencia,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _habitos = habitosSalvos;
      _carregando = false;
    });
  }

  // =========================
  // SALVAR HÁBITOS
  // =========================

  Future<void> _salvarHabitos() async {
    await _storage.salvarHabitos(_habitos);
  }

  // =========================
  // ADICIONAR HÁBITO
  // =========================

  Future<void> _adicionarHabito() async {
    final controller = TextEditingController();

    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo hábito'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome do hábito',
              hintText: 'Ex: Estudar Flutter',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (valor) {
              Navigator.pop(context, valor.trim());
            },
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
                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (nome == null || nome.isEmpty) {
      return;
    }

    final novoHabito = Habito(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: nome,
    );

    setState(() {
      _habitos.add(novoHabito);
    });

    await _salvarHabitos();
  }

  // =========================
  // ALTERNAR HÁBITO
  // =========================

  Future<void> _alternarHabito(Habito habito) async {
    final hoje = _dataHoje();

    final jaConcluido = habito.diasConcluidos.contains(hoje);

    setState(() {
      if (jaConcluido) {
        habito.diasConcluidos.remove(hoje);
      } else {
        habito.diasConcluidos.add(hoje);
      }
    });

    await _salvarHabitos();

    // Registra a conquista somente quando o hábito é concluído,
    // nunca quando o usuário apenas desmarca o dia.
    if (!jaConcluido) {
      await _conquistaService.registrarHabitoConcluido(
        habito.id,
        habito.sequencia,
      );
    }

    // =========================
    // GANHAR XP
    // =========================

    if (!jaConcluido) {
      await _xpService.adicionarXp(
        XpService.xpHabito,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔥 Hábito concluído! +20 XP',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // =========================
    // REMOVER XP
    // =========================

    else {
      await _xpService.removerXp(
        XpService.xpHabito,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '↩️ Hábito desmarcado! -20 XP',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // =========================
  // EXCLUIR HÁBITO
  // =========================

  Future<void> _excluirHabito(Habito habito) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir hábito?'),
          content: Text(
            'Deseja realmente excluir "${habito.titulo}"?',
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

    // Conta quantos dias concluídos esse hábito possui.
    final quantidadeConcluida =
        habito.diasConcluidos.length;

    setState(() {
      _habitos.remove(habito);
    });

    await _salvarHabitos();

    // Remove o XP referente aos dias já concluídos.
    for (int i = 0; i < quantidadeConcluida; i++) {
      await _xpService.removerXp(
        XpService.xpHabito,
      );
    }
  }

  // =========================
  // ACOMPANHAMENTO SEMANAL
  // =========================

  Widget _buildAcompanhamentoSemanal(Habito habito) {
    final hoje = DateTime.now();

    // Encontra a segunda-feira da semana atual.
    final segunda = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).subtract(Duration(days: hoje.weekday - 1));

    const diasSemana = [
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SÁB',
      'DOM',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esta semana',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: List.generate(7, (index) {
            final data = segunda.add(Duration(days: index));

            final concluido = habito.diasConcluidos.contains(
              _dataFormatada(data),
            );

            final ehHoje = data.year == hoje.year &&
                data.month == hoje.month &&
                data.day == hoje.day;

            return Expanded(
              child: Column(
                children: [
                  Text(
                    diasSemana[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: concluido
                          ? Colors.deepPurple
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: ehHoje
                          ? Border.all(
                              color: Colors.deepPurple,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: concluido
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '${data.day}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // =========================
  // CARD DO HÁBITO
  // =========================

  Widget _buildHabitoCard(Habito habito) {
    final concluidoHoje = habito.foiConcluidoHoje();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Botão independente para concluir/desmarcar o hábito.
            IconButton(
              tooltip: concluidoHoje
                  ? 'Desmarcar hábito'
                  : 'Concluir hábito',
              onPressed: () => _alternarHabito(habito),
              icon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: concluidoHoje
                      ? Colors.deepPurple
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: concluidoHoje
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                  ),
                ),
                child: concluidoHoje
                    ? const Icon(Icons.check, color: Colors.white)
                    : Icon(
                        Icons.local_fire_department_outlined,
                        color: Colors.grey.shade600,
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // O título abre o histórico.
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HistoricoHabitoPage(habito: habito),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habito.titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: concluidoHoje
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 17,
                            color: Colors.orange.shade700,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            '${habito.sequencia} dias',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Nova visualização semanal.
                      _buildAcompanhamentoSemanal(habito),
                    ],
                  ),
                ),
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (valor) {
                if (valor == 'excluir') {
                  _excluirHabito(habito);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'excluir',
                  child: Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // TELA
  // =========================

  @override
  Widget build(BuildContext context) {
    final concluidosHoje = _habitos
        .where(
          (habito) => habito.foiConcluidoHoje(),
        )
        .length;

    final totalHabitos = _habitos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hábitos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarHabito,
        child: const Icon(Icons.add),
      ),

      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // =========================
                // RESUMO
                // =========================

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6A4BBC),
                        Color(0xFF8E6CD8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.15,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seu dia',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              totalHabitos == 0
                                  ? 'Crie seu primeiro hábito'
                                  : '$concluidosHoje de $totalHabitos hábitos concluídos',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // TÍTULO
                // =========================

                const Text(
                  'Meus hábitos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // LISTA
                // =========================

                if (_habitos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Nenhum hábito cadastrado.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Clique no + para criar seu primeiro hábito.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._habitos.map(
                    (habito) =>
                        _buildHabitoCard(habito),
                  ),
              ],
            ),
    );
  }
}
