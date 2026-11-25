class MesaEvento {
  final String idMesa;
  final String idEvento;
  final int numeroMesa;
  final String nomeMesa;
  final int capacidadeAssentos;
  final int totalOcupados;
  final String? idGrupo;
  final String? nomeGrupo;
  final String? corHex;
  final bool ativa;

  const MesaEvento({
    required this.idMesa,
    required this.idEvento,
    required this.numeroMesa,
    required this.nomeMesa,
    required this.capacidadeAssentos,
    this.totalOcupados = 0,
    this.idGrupo,
    this.nomeGrupo,
    this.corHex,
    this.ativa = true,
  });

  int get totalLivres {
    final livres = capacidadeAssentos - totalOcupados;
    return livres < 0 ? 0 : livres;
  }

  bool get lotada => totalOcupados >= capacidadeAssentos;

  MesaEvento copyWith({
    String? idMesa,
    String? idEvento,
    int? numeroMesa,
    String? nomeMesa,
    int? capacidadeAssentos,
    int? totalOcupados,
    String? idGrupo,
    String? nomeGrupo,
    bool limparGrupo = false,
    String? corHex,
    bool? ativa,
  }) {
    return MesaEvento(
      idMesa: idMesa ?? this.idMesa,
      idEvento: idEvento ?? this.idEvento,
      numeroMesa: numeroMesa ?? this.numeroMesa,
      nomeMesa: nomeMesa ?? this.nomeMesa,
      capacidadeAssentos: capacidadeAssentos ?? this.capacidadeAssentos,
      totalOcupados: totalOcupados ?? this.totalOcupados,
      idGrupo: limparGrupo ? null : (idGrupo ?? this.idGrupo),
      nomeGrupo: limparGrupo ? null : (nomeGrupo ?? this.nomeGrupo),
      corHex: corHex ?? this.corHex,
      ativa: ativa ?? this.ativa,
    );
  }
}
