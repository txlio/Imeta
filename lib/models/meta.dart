class Meta {
  int id;
  String titulo;
  String descricao;
  DateTime? prazo;
  double valorMeta;
  double valorAtual;

  Meta({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.prazo,
    this.valorMeta = 0,
    this.valorAtual = 0,
  });

  double get progresso {
    if (valorMeta <= 0) {
      return 0;
    }

    return (valorAtual / valorMeta).clamp(0.0, 1.0);
  }

  bool get concluida {
    return valorMeta > 0 && valorAtual >= valorMeta;
  }
}