class ServicoProdutoModel {
  final String id;
  final String nome;
  final String? tipoMedida; // E.g. 'U' = unidade, 'H' = hora, etc.
  final String? descricao;

  const ServicoProdutoModel({
    required this.id,
    required this.nome,
    this.tipoMedida,
    this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo_medida': tipoMedida,
      'descricao': descricao,
    };
  }

  factory ServicoProdutoModel.fromMap(Map<String, dynamic> map) {
    return ServicoProdutoModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      tipoMedida: map['tipo_medida'],
      descricao: map['descricao'],
    );
  }

  ServicoProdutoModel copyWith({
    String? nome,
    String? tipoMedida,
    String? descricao,
  }) {
    return ServicoProdutoModel(
      id: id,
      nome: nome ?? this.nome,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      descricao: descricao ?? this.descricao,
    );
  }
}
