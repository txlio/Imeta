
class Tarefa {
  int id;
  String titulo;
  String descricao;
  bool concluida;
  String prioridade;
  String categoria;

  // Dados dos lembretes
  DateTime? dataLembrete;
  int? notificacaoId;

  Tarefa({
    required this.id,
    required this.titulo,
    this.descricao = '',
    this.concluida = false,
    this.prioridade = 'Média',
    this.categoria = 'Pessoal',
    this.dataLembrete,
    this.notificacaoId,
  });
}
