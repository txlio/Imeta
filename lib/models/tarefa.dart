class Tarefa {
  int id;
  String titulo;
  String descricao;
  bool concluida;
  String prioridade;

  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.concluida = false,
    this.prioridade = 'Média',
  });
}