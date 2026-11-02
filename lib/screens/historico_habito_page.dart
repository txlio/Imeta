import 'package:flutter/material.dart';

import '../models/habito.dart';

class HistoricoHabitoPage extends StatefulWidget {
  final Habito habito;

  const HistoricoHabitoPage({
    super.key,
    required this.habito,
  });

  @override
  State<HistoricoHabitoPage> createState() => _HistoricoHabitoPageState();
}

class _HistoricoHabitoPageState extends State<HistoricoHabitoPage> {
  late DateTime _mesAtual;

  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();

    _mesAtual = DateTime(
      hoje.year,
      hoje.month,
    );
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return meses[mes - 1];
  }

  String _dataFormatada(DateTime data) {
    return '${data.year}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  bool _foiConcluido(DateTime data) {
    return widget.habito.diasConcluidos.contains(
      _dataFormatada(data),
    );
  }

  bool _ehHoje(DateTime data) {
    final hoje = DateTime.now();

    return data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
  }

  int _quantidadeDiasNoMes() {
    return DateTime(
      _mesAtual.year,
      _mesAtual.month + 1,
      0,
    ).day;
  }

  int _primeiroDiaDaSemana() {
    final primeiroDia = DateTime(
      _mesAtual.year,
      _mesAtual.month,
      1,
    );

    return primeiroDia.weekday;
  }

  void _mesAnterior() {
    setState(() {
      _mesAtual = DateTime(
        _mesAtual.year,
        _mesAtual.month - 1,
      );
    });
  }

  void _proximoMes() {
    setState(() {
      _mesAtual = DateTime(
        _mesAtual.year,
        _mesAtual.month + 1,
      );
    });
  }

  int _diasConcluidosNoMes() {
    int total = 0;

    for (final data in widget.habito.diasConcluidos) {
      final dataConvertida = DateTime.parse(data);

      if (dataConvertida.year == _mesAtual.year &&
          dataConvertida.month == _mesAtual.month) {
        total++;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final diasNoMes = _quantidadeDiasNoMes();
    final primeiroDia = _primeiroDiaDaSemana();
    final diasConcluidos = _diasConcluidosNoMes();

    final totalCelulas = ((primeiroDia - 1) + diasNoMes);
    final quantidadeLinhas = (totalCelulas / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // =========================
          // CABEÇALHO DO HÁBITO
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
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habito.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '🔥 ${widget.habito.sequencia} dias de sequência',
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
          // NAVEGAÇÃO DO MÊS
          // =========================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _mesAnterior,
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                '${_nomeMes(_mesAtual.month)} ${_mesAtual.year}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: _proximoMes,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =========================
          // RESUMO DO MÊS
          // =========================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple,
                ),

                const SizedBox(width: 10),

                Text(
                  '$diasConcluidos dias concluídos neste mês',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =========================
          // DIAS DA SEMANA
          // =========================

          Row(
            children: [
              _buildDiaSemana('Seg'),
              _buildDiaSemana('Ter'),
              _buildDiaSemana('Qua'),
              _buildDiaSemana('Qui'),
              _buildDiaSemana('Sex'),
              _buildDiaSemana('Sáb'),
              _buildDiaSemana('Dom'),
            ],
          ),

          const SizedBox(height: 8),

          // =========================
          // CALENDÁRIO
          // =========================

          Column(
            children: List.generate(
              quantidadeLinhas,
              (linha) {
                return Row(
                  children: List.generate(
                    7,
                    (coluna) {
                      final numeroDia =
                          (linha * 7) + coluna - (primeiroDia - 2);

                      if (numeroDia < 1 ||
                          numeroDia > diasNoMes) {
                        return _buildCelulaVazia();
                      }

                      final data = DateTime(
                        _mesAtual.year,
                        _mesAtual.month,
                        numeroDia,
                      );

                      return _buildDia(data);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // =========================
          // LEGENDA
          // =========================

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegenda(
                cor: Colors.deepPurple,
                texto: 'Concluído',
              ),

              const SizedBox(width: 20),

              _buildLegenda(
                cor: Colors.grey.shade200,
                texto: 'Não concluído',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiaSemana(String texto) {
    return Expanded(
      child: Center(
        child: Text(
          texto,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCelulaVazia() {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: Container(),
      ),
    );
  }

  Widget _buildDia(DateTime data) {
    final concluido = _foiConcluido(data);
    final hoje = _ehHoje(data);

    return Expanded(
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: concluido
              ? Colors.deepPurple
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: hoje
              ? Border.all(
                  color: Colors.deepPurple,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${data.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: concluido
                      ? Colors.white
                      : Colors.black87,
                ),
              ),

              if (concluido)
                const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegenda({
    required Color cor,
    required String texto,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(width: 6),

        Text(
          texto,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}