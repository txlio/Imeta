
import 'package:flutter/material.dart';

import '../models/meta.dart';
import '../models/tarefa.dart';
import '../models/habito.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();
  final XpService _xpService = XpService();

  List<Meta> _metas = [];
  List<Tarefa> _tarefas = [];
  List<Habito> _habitos = [];

  int _xp = 0;

  bool _carregando = true;

  // =========================
  // TAREFAS
  // =========================

  int get _tarefasConcluidas {
    return _tarefas.where((tarefa) => tarefa.concluida).length;
  }

  int get _tarefasPendentes {
    return _tarefas.where((tarefa) => !tarefa.concluida).length;
  }

  double get _percentualTarefas {
    if (_tarefas.isEmpty) {
      return 0;
    }

    return _tarefasConcluidas / _tarefas.length;
  }

  // =========================
  // HÁBITOS
  // =========================

  int get _habitosConcluidosHoje {
    return _habitos
        .where((habito) => habito.foiConcluidoHoje())
        .length;
  }

  int get _habitosPendentesHoje {
    return _habitos.length - _habitosConcluidosHoje;
  }

  double get _percentualHabitosHoje {
    if (_habitos.isEmpty) {
      return 0;
    }

    return _habitosConcluidosHoje / _habitos.length;
  }

  // =========================
  // XP E NÍVEL
  // =========================

  int get _nivel {
    return _xpService.calcularNivel(_xp);
  }

  double get _progressoNivel {
    return _xpService.calcularProgresso(_xp);
  }

  int get _xpRestante {
    return _xpService.xpParaProximoNivel(_xp);
  }

  // Maior sequência registrada entre os hábitos cadastrados.
  int get _maiorSequenciaHabitos {
    if (_habitos.isEmpty) return 0;

    return _habitos
        .map((habito) => habito.sequencia)
        .reduce((atual, proxima) => atual > proxima ? atual : proxima);
  }

  // =========================
  // INICIALIZAÇÃO
  // =========================

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // =========================
  // CARREGAR DADOS
  // =========================

  Future<void> _carregarDados() async {
    final metas = await _storage.carregarMetas();
    final tarefas = await _storage.carregarTarefas();
    final habitos = await _storage.carregarHabitos();
    final xp = await _xpService.carregarXp();

    if (!mounted) return;

    setState(() {
      _metas = metas;
      _tarefas = tarefas;
      _habitos = habitos;
      _xp = xp;
      _carregando = false;
    });
  }

  // =========================
  // DATA FORMATADA
  // =========================

  String _dataFormatada(DateTime data) {
    return '${data.year}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  // =========================
  // DESEMPENHO SEMANAL
  // =========================

  Widget _buildDesempenhoSemanal() {
    final hoje = DateTime.now();

    final hojeSemHora = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    final segunda = hojeSemHora.subtract(
      Duration(days: hoje.weekday - 1),
    );

    const diasSemana = [
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SÁB',
      'DOM',
    ];

    final totalHabitos = _habitos.length;

    final dadosSemana = List.generate(7, (index) {
      final data = segunda.add(Duration(days: index));
      final dataFormatada = _dataFormatada(data);

      final concluidos = _habitos.where((habito) {
        return habito.diasConcluidos.contains(dataFormatada);
      }).length;

      final percentual = totalHabitos == 0
          ? 0.0
          : concluidos / totalHabitos;

      return {
        'dia': diasSemana[index],
        'data': data.day,
        'concluidos': concluidos,
        'percentual': percentual,
        'ehHoje': data.year == hoje.year &&
            data.month == hoje.month &&
            data.day == hoje.day,
        'ehFuturo': data.isAfter(hojeSemHora),
      };
    });

    final totalConcluidosNaSemana = dadosSemana.fold<int>(
      0,
      (total, dia) => total + (dia['concluidos'] as int),
    );

    final diasComConclusao = dadosSemana.where((dia) {
      return (dia['concluidos'] as int) > 0;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart,
                color: Colors.deepPurple,
                size: 25,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Desempenho semanal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Hábitos concluídos por dia',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          if (_habitos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 35,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre hábitos para acompanhar sua semana.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final dia = dadosSemana[index];

                  final percentual =
                      dia['percentual'] as double;

                  final concluidos =
                      dia['concluidos'] as int;

                  final ehHoje = dia['ehHoje'] as bool;
                  final ehFuturo = dia['ehFuturo'] as bool;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$concluidos',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ehFuturo
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Expanded(
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: percentual == 0
                                    ? 0.04
                                    : percentual,
                                widthFactor: 0.65,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ehFuturo
                                        ? Colors.grey.shade200
                                        : Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            dia['dia'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: ehHoje
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: ehHoje
                                  ? Colors.deepPurple
                                  : Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: ehHoje
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalConcluidosNaSemana',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Conclusões na semana',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$diasComConclusao de 7',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dias com atividade',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // RESUMO DOS HÁBITOS DE HOJE
  // =========================

  Widget _buildResumoHabitosHoje() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
                size: 25,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hábitos de hoje',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$_habitosConcluidosHoje/${_habitos.length}',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _percentualHabitosHoje,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurple,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _habitos.isEmpty
                ? 'Cadastre seus hábitos para acompanhar seu progresso.'
                : _habitosPendentesHoje == 0
                    ? 'Todos os hábitos concluídos! Parabéns! 🎉'
                    : '$_habitosPendentesHoje hábito(s) ainda pendente(s) hoje.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IMeta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),

      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // =========================
            // SAUDAÇÃO
            // =========================

            const Text(
              'Olá! 👋',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Vamos organizar seu dia?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // AVISOS DO DIA
            // =========================

            _buildAvisosDoDia(),

            const SizedBox(height: 24),

            // =========================
            // CARD DO DIA
            // =========================

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6A4BBC),
                    Color(0xFF8E6CD8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seu dia',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _tarefas.isEmpty
                        ? 'Nenhuma tarefa cadastrada'
                        : '$_tarefasConcluidas de ${_tarefas.length} tarefas concluídas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _percentualTarefas,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _tarefasPendentes == 0
                        ? 'Tudo concluído! 🎉'
                        : '$_tarefasPendentes tarefas pendentes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // CARD DE XP E NÍVEL
            // =========================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nível $_nivel',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '$_xp XP • faltam $_xpRestante XP',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressoNivel,
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${(_progressoNivel * 100).toStringAsFixed(0)}% para o próximo nível',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // HÁBITOS DE HOJE
            // =========================

            _buildResumoHabitosHoje(),

            const SizedBox(height: 20),

            // =========================
            // DESEMPENHO SEMANAL
            // =========================

            _buildDesempenhoSemanal(),

            const SizedBox(height: 24),

            // =========================
            // RESUMO
            // =========================

            const Text(
              'Resumo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildResumoCard(
                    icon: Icons.flag,
                    titulo: 'Metas',
                    valor: '${_metas.length}',
                    subtitulo: 'cadastradas',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildResumoCard(
                    icon: Icons.check_circle,
                    titulo: 'Tarefas',
                    valor: '${_tarefas.length}',
                    subtitulo: 'no total',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildResumoCard(
                    icon: Icons.local_fire_department,
                    titulo: 'Sequência',
                    valor: '$_maiorSequenciaHabitos',
                    subtitulo: 'dias',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildResumoCard(
                    icon: Icons.star,
                    titulo: 'XP',
                    valor: '$_xp',
                    subtitulo: 'pontos',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =========================
            // TAREFAS PENDENTES
            // =========================

            if (_tarefasPendentes > 0) ...[
              const Text(
                'Tarefas pendentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ..._tarefas
                  .where((tarefa) => !tarefa.concluida)
                  .take(5)
                  .map(
                    (tarefa) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.radio_button_unchecked,
                        ),
                        title: Text(
                          tarefa.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Prioridade: ${tarefa.prioridade}',
                        ),
                      ),
                    ),
                  ),
            ],

            // =========================
            // METAS
            // =========================

            if (_metas.isNotEmpty) ...[
              const SizedBox(height: 16),

              const Text(
                'Suas metas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ..._metas
                  .take(5)
                  .map(
                    (meta) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(
                          meta.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          meta.valorMeta > 0
                              ? '${(meta.progresso * 100).toStringAsFixed(0)}% concluída'
                              : 'Meta cadastrada',
                        ),
                        trailing: SizedBox(
                          width: 55,
                          child: LinearProgressIndicator(
                            value: meta.progresso,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================
  // AVISOS DO DIA
  // =========================

  Widget _buildAvisosDoDia() {
    final metasEmAndamento =
        _metas.where((meta) => meta.progresso < 1).length;

    final avisos = <Widget>[];

    if (_tarefasPendentes > 0) {
      avisos.add(
        _buildAviso(
          icone: Icons.notifications_active_outlined,
          titulo: 'Você tem $_tarefasPendentes tarefa(s) pendente(s)',
          descricao: 'Reserve um momento para concluir suas atividades.',
          cor: Colors.deepOrange,
        ),
      );
    }

    if (metasEmAndamento > 0) {
      avisos.add(
        _buildAviso(
          icone: Icons.flag_outlined,
          titulo: '$metasEmAndamento meta(s) em andamento',
          descricao: 'Dê um pequeno passo hoje para avançar nas suas metas.',
          cor: Colors.deepPurple,
        ),
      );
    }

    avisos.add(
      _buildAviso(
        icone: Icons.local_fire_department_outlined,
        titulo: 'Hora de cuidar dos seus hábitos',
        descricao: 'Abra a aba Hábitos e registre o que você já realizou hoje.',
        cor: Colors.teal,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avisos do dia',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...avisos,
      ],
    );
  }

  // =========================
  // CARD DE AVISO
  // =========================

  Widget _buildAviso({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 26),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descricao,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // CARD DE RESUMO
  // =========================

  Widget _buildResumoCard({
    required IconData icon,
    required String titulo,
    required String valor,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: Colors.deepPurple,
          ),

          const SizedBox(height: 12),

          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            subtitulo,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
