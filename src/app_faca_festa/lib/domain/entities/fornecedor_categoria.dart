class FornecedorCategoria {
  final String idFornecedor;
  final String idCategoria;
  final String? nomeCategoria;
  final List<Map<String, dynamic>> subcategorias;
  final DateTime? dataCadastro;

  const FornecedorCategoria({
    required this.idFornecedor,
    required this.idCategoria,
    this.nomeCategoria,
    this.subcategorias = const [],
    this.dataCadastro,
  });

  FornecedorCategoria copyWith({
    String? idFornecedor,
    String? idCategoria,
    String? nomeCategoria,
    List<Map<String, dynamic>>? subcategorias,
    DateTime? dataCadastro,
  }) {
    return FornecedorCategoria(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idCategoria: idCategoria ?? this.idCategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      subcategorias: subcategorias ?? this.subcategorias,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }
}
