class Habito {
  int id;
  String titulo;
  List<String> diasConcluidos;

  Habito({
    required this.id,
    required this.titulo,
    this.diasConcluidos = const [],
  });

  bool foiConcluidoHoje() {
    final hoje = DateTime.now();

    final dataHoje =
        '${hoje.year}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';

    return diasConcluidos.contains(dataHoje);
  }

  int get sequencia {
    if (diasConcluidos.isEmpty) {
      return 0;
    }

    final datas = diasConcluidos
        .map((data) => DateTime.parse(data))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final hoje = DateTime.now();

    final hojeSemHora = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    final ultimaData = DateTime(
      datas.first.year,
      datas.first.month,
      datas.first.day,
    );

    final diferenca =
        hojeSemHora.difference(ultimaData).inDays;

    if (diferenca > 1) {
      return 0;
    }

    int contador = 0;

    DateTime dataEsperada = ultimaData;

    for (final data in datas) {
      final dataSemHora = DateTime(
        data.year,
        data.month,
        data.day,
      );

      if (dataSemHora == dataEsperada) {
        contador++;

        dataEsperada = dataEsperada.subtract(
          const Duration(days: 1),
        );
      }
    }

    return contador;
  }
}