class FornecedorCategoriaModel {
  final String idFornecedor;
  final String idCategoria;

  FornecedorCategoriaModel({
    required this.idFornecedor,
    required this.idCategoria,
  });

  Map<String, dynamic> toMap() => {
        'id_fornecedor': idFornecedor,
        'id_categoria': idCategoria,
      };

  factory FornecedorCategoriaModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCategoriaModel(
      idFornecedor: map['id_fornecedor'] ?? '',
      idCategoria: map['id_categoria'] ?? '',
    );
  }

  FornecedorCategoriaModel copyWith({
    String? idFornecedor,
    String? idCategoria,
  }) {
    return FornecedorCategoriaModel(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idCategoria: idCategoria ?? this.idCategoria,
    );
  }
}
