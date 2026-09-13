class Estado {
  const Estado({
    required this.id,
    required this.nome,
    required this.uf,
  });

  final String id;
  final String nome;
  final String uf;
}

class Cidade {
  const Cidade({
    required this.id,
    required this.nome,
    required this.uf,
    this.idCidade,
  });

  final String id;
  final String nome;
  final String uf;
  final int? idCidade;
}
