import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../models/habito.dart';
import '../models/meta.dart';
import '../models/tarefa.dart';
import '../services/conquista_service.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class ProgressoPage extends StatefulWidget {
  const ProgressoPage({super.key});

  @override
  State<ProgressoPage> createState() => _ProgressoPageState();
}

class _ProgressoPageState extends State<ProgressoPage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();
  final ConquistaService _conquistaService = ConquistaService();

  List<Tarefa> _tarefas = [];
  List<Meta> _metas = [];
  List<Habito> _habitos = [];
  List<Conquista> _conquistas = [];

  int _xp = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
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

      final conquistas = await _conquistaService.carregarConquistas(
        tarefasConcluidas: tarefasConcluidas,
        diasSequencia: maiorSequencia,
        metasConcluidas: metasConcluidas,
        xp: xp,
        nivel: nivel,
      );

      if (!mounted) return;

      setState(() {
        _tarefas = tarefas;
        _metas = metas;
        _habitos = habitos;
        _xp = xp;
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
          content: Text('Não foi possível carregar o progresso: $e'),
        ),
      );
    }
  }

  int get _nivel => _xpService.calcularNivel(_xp);
  double get _progressoNivel => _xpService.calcularProgresso(_xp);
  int get _xpRestante => _xpService.xpParaProximoNivel(_xp);

  int get _tarefasConcluidas =>
      _tarefas.where((tarefa) => tarefa.concluida).length;

  int get _metasConcluidas =>
      _metas.where((meta) => meta.concluida).length;

  int get _habitosConcluidosHoje =>
      _habitos.where((habito) => habito.foiConcluidoHoje()).length;

  double get _progressoTarefas {
    if (_tarefas.isEmpty) return 0;
    return _tarefasConcluidas / _tarefas.length;
  }

  double get _progressoMetas {
    if (_metas.isEmpty) return 0;
    return _metasConcluidas / _metas.length;
  }

  double get _progressoHabitos {
    if (_habitos.isEmpty) return 0;
    return _habitosConcluidosHoje / _habitos.length;
  }

  String _porcentagem(double valor) =>
      '${(valor * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Meu Progresso',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Progresso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // CARD DE NÍVEL
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A4BBC), Color(0xFF8E6CD8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nível',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$_nivel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'XP total',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_xp XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso do nível',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_progressoNivel * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressoNivel,
                      minHeight: 10,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.20),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_xpRestante XP para o próximo nível',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // CONQUISTAS
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Minhas conquistas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_conquistas.where((c) => c.desbloqueada).length}'
                  '/${_conquistas.length}',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete atividades para desbloquear novas medalhas.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            if (_conquistas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma conquista disponível no momento.'),
                ),
              )
            else
              ..._conquistas.map(
                (conquista) => _ConquistaCard(conquista: conquista),
              ),

            const SizedBox(height: 28),

            // ESTATÍSTICAS
            const Text(
              'Meu desempenho',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ProgressoCard(
              titulo: 'Tarefas concluídas',
              valor: _porcentagem(_progressoTarefas),
              progresso: _progressoTarefas,
              icon: Icons.check_circle,
              detalhe: '$_tarefasConcluidas de ${_tarefas.length} tarefas',
            ),
            _ProgressoCard(
              titulo: 'Metas concluídas',
              valor: _porcentagem(_progressoMetas),
              progresso: _progressoMetas,
              icon: Icons.flag,
              detalhe: '$_metasConcluidas de ${_metas.length} metas',
            ),
            _ProgressoCard(
              titulo: 'Hábitos realizados hoje',
              valor: _porcentagem(_progressoHabitos),
              progresso: _progressoHabitos,
              icon: Icons.local_fire_department,
              detalhe:
                  '$_habitosConcluidosHoje de ${_habitos.length} hábitos',
            ),

            const SizedBox(height: 12),

            // COMO GANHAR XP
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como ganhar XP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const _XpItem(
                    icon: Icons.check_circle,
                    texto: 'Concluir uma tarefa',
                    xp: '+10 XP',
                  ),
                  const SizedBox(height: 12),
                  const _XpItem(
                    icon: Icons.local_fire_department,
                    texto: 'Concluir um hábito',
                    xp: '+20 XP',
                  ),
                  const SizedBox(height: 12),
                  const _XpItem(
                    icon: Icons.flag,
                    texto: 'Concluir uma meta',
                    xp: '+50 XP',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // MOTIVAÇÃO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.deepPurple,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _xp == 0
                          ? 'Comece hoje! Complete tarefas, hábitos e metas para ganhar XP.'
                          : 'Continue assim! Cada pequena ação ajuda você a evoluir.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConquistaCard extends StatelessWidget {
  final Conquista conquista;

  const _ConquistaCard({required this.conquista});

  @override
  Widget build(BuildContext context) {
    final desbloqueada = conquista.desbloqueada;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: desbloqueada ? Colors.white : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: desbloqueada
              ? Colors.deepPurple.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: desbloqueada
                    ? Colors.deepPurple.withValues(alpha: 0.10)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                desbloqueada ? conquista.emoji : '🔒',
                style: const TextStyle(fontSize: 27),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conquista.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: desbloqueada
                          ? Colors.black87
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conquista.descricao,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: conquista.percentual,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      color: desbloqueada
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    desbloqueada
                        ? 'Conquista desbloqueada!'
                        : '${conquista.progresso.clamp(0, conquista.objetivo)}'
                            ' de ${conquista.objetivo}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: desbloqueada
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: desbloqueada
                          ? Colors.deepPurple
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (desbloqueada)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final double progresso;
  final IconData icon;
  final String detalhe;

  const _ProgressoCard({
    required this.titulo,
    required this.valor,
    required this.progresso,
    required this.icon,
    required this.detalhe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detalhe,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progresso),
          ],
        ),
      ),
    );
  }
}

class _XpItem extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String xp;

  const _XpItem({
    required this.icon,
    required this.texto,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          xp,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}
