class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final String emoji;
  final int objetivo;
  final int progresso;
  final bool desbloqueada;

  const Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.emoji,
    required this.objetivo,
    required this.progresso,
    required this.desbloqueada,
  });

  double get percentual {
    if (objetivo <= 0) return 0;

    return (progresso / objetivo).clamp(0.0, 1.0);
  }
}
