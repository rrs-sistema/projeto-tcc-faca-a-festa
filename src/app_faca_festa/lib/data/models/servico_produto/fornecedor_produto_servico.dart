class FornecedorProdutoServicoModel {
  final String idServico;
  final String idProdutoServico;
  final String idFornecedor;
  final double preco;
  final double? precoPromocao;
  final bool ativo;

  const FornecedorProdutoServicoModel({
    required this.idServico,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.preco,
    this.precoPromocao,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_servico': idServico,
      'id_produto_servico': idProdutoServico,
      'id_fornecedor': idFornecedor,
      'preco': preco,
      'preco_promocao': precoPromocao,
      'ativo': ativo,
    };
  }

  factory FornecedorProdutoServicoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorProdutoServicoModel(
      idServico: map['id_servico'] ?? '',
      idProdutoServico: map['id_produto_servico'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      preco: (map['preco'] as num?)?.toDouble() ?? 0.0,
      precoPromocao: (map['preco_promocao'] as num?)?.toDouble(),
      ativo: map['ativo'] ?? true,
    );
  }

  FornecedorProdutoServicoModel copyWith({
    double? preco,
    double? precoPromocao,
    bool? ativo,
  }) {
    return FornecedorProdutoServicoModel(
      idServico: idServico,
      idProdutoServico: idProdutoServico,
      idFornecedor: idFornecedor,
      preco: preco ?? this.preco,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      ativo: ativo ?? this.ativo,
    );
  }
}
