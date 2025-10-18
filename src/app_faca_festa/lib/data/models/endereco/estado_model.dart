class EstadoModel {
  final String idUf;
  final String uf;
  final String nome;

  const EstadoModel({
    required this.idUf,
    required this.uf,
    required this.nome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_uf': idUf,
      'uf': uf,
      'nome': nome,
    };
  }

  factory EstadoModel.fromMap(Map<String, dynamic> map) {
    return EstadoModel(
      idUf: map['id_uf'] ?? '',
      uf: map['uf'] ?? '',
      nome: map['nome'] ?? '',
    );
  }

  EstadoModel copyWith({
    String? uf,
    String? nome,
  }) {
    return EstadoModel(
      idUf: idUf,
      uf: uf ?? this.uf,
      nome: nome ?? this.nome,
    );
  }
}
