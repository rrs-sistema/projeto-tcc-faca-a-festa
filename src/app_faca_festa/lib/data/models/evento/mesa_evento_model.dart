class MesaEventoModel {
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

  const MesaEventoModel({
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

  Map<String, dynamic> toMap() {
    return {
      'id_mesa': idMesa,
      'id_evento': idEvento,
      'numero_mesa': numeroMesa,
      'nome_mesa': nomeMesa,
      'capacidade_assentos': capacidadeAssentos,
      'total_ocupados': totalOcupados,
      'total_livres': totalLivres,
      'id_grupo': idGrupo,
      'nome_grupo': nomeGrupo,
      'cor_hex': corHex,
      'ativa': ativa,
    };
  }

  factory MesaEventoModel.fromMap(Map<String, dynamic> map) {
    return MesaEventoModel(
      idMesa: map['id_mesa']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      numeroMesa:
          map['numero_mesa'] is num ? (map['numero_mesa'] as num).toInt() : 0,
      nomeMesa: map['nome_mesa']?.toString() ?? '',
      capacidadeAssentos: map['capacidade_assentos'] is num
          ? (map['capacidade_assentos'] as num).toInt()
          : 0,
      totalOcupados: map['total_ocupados'] is num
          ? (map['total_ocupados'] as num).toInt()
          : 0,
      idGrupo: map['id_grupo']?.toString(),
      nomeGrupo: map['nome_grupo']?.toString(),
      corHex: map['cor_hex']?.toString(),
      ativa: map['ativa'] ?? true,
    );
  }

  MesaEventoModel copyWith({
    int? numeroMesa,
    String? nomeMesa,
    int? capacidadeAssentos,
    int? totalOcupados,
    String? idGrupo,
    String? nomeGrupo,
    String? corHex,
    bool? ativa,
  }) {
    return MesaEventoModel(
      idMesa: idMesa,
      idEvento: idEvento,
      numeroMesa: numeroMesa ?? this.numeroMesa,
      nomeMesa: nomeMesa ?? this.nomeMesa,
      capacidadeAssentos: capacidadeAssentos ?? this.capacidadeAssentos,
      totalOcupados: totalOcupados ?? this.totalOcupados,
      idGrupo: idGrupo ?? this.idGrupo,
      nomeGrupo: nomeGrupo ?? this.nomeGrupo,
      corHex: corHex ?? this.corHex,
      ativa: ativa ?? this.ativa,
    );
  }
}
