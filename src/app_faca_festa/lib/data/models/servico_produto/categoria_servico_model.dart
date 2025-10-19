class CategoriaServicoModel {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;

  CategoriaServicoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
      };

  factory CategoriaServicoModel.fromMap(Map<String, dynamic> map) {
    return CategoriaServicoModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
    );
  }

  CategoriaServicoModel copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
  }) {
    return CategoriaServicoModel(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }
}
