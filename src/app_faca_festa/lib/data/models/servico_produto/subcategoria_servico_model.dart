class SubcategoriaServicoModel {
  final String id;
  final String idCategoria;
  final String nome;
  final String? descricao;
  final bool ativo;

  SubcategoriaServicoModel({
    required this.id,
    required this.idCategoria,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'id_categoria': idCategoria,
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
      };

  factory SubcategoriaServicoModel.fromMap(Map<String, dynamic> map) {
    return SubcategoriaServicoModel(
      id: map['id'] ?? '',
      idCategoria: map['id_categoria'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
    );
  }

  SubcategoriaServicoModel copyWith({
    String? idCategoria,
    String? nome,
    String? descricao,
    bool? ativo,
  }) {
    return SubcategoriaServicoModel(
      id: id,
      idCategoria: idCategoria ?? this.idCategoria,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }
}
