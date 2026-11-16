
class Meta {
  int id;
  String titulo;
  String descricao;
  DateTime? prazo;
  double valorMeta;
  double valorAtual;

  // Novos atributos
  bool concluida;
  bool xpRecebido;

  Meta({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.prazo,
    this.valorMeta = 0,
    this.valorAtual = 0,
    this.concluida = false,
    this.xpRecebido = false,
  });

  double get progresso {
    if (valorMeta <= 0) {
      return 0;
    }

    return (valorAtual / valorMeta).clamp(0.0, 1.0);
  }

  // Verifica se a meta financeira atingiu o valor desejado
  bool get atingiuValor {
    return valorMeta > 0 && valorAtual >= valorMeta;
  }
}
