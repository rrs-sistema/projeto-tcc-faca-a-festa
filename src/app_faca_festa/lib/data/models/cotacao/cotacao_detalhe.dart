class CotacaoDetalheModel {
  final String id;
  final String idCotacao;
  final String idFornecedor;
  final String idProdutoServico;
  final String nomeProdutoServico;
  final double quantidade;
  final double? valorUnitario;
  final double? valorTotal;

  const CotacaoDetalheModel({
    required this.id,
    required this.idCotacao,
    required this.idFornecedor,
    required this.idProdutoServico,
    required this.nomeProdutoServico,
    required this.quantidade,
    this.valorUnitario,
    this.valorTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'id_produto_servico': idProdutoServico,
      'nome_produto_servico': nomeProdutoServico,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
    };
  }

  factory CotacaoDetalheModel.fromMap(Map<String, dynamic> map) {
    return CotacaoDetalheModel(
      id: map['id']?.toString() ?? '',
      idCotacao: map['id_cotacao']?.toString() ?? '',
      idFornecedor: map['id_fornecedor']?.toString() ?? '',
      idProdutoServico: map['id_produto_servico']?.toString() ?? '',
      nomeProdutoServico: map['nome_produto_servico'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0.0,
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble(),
      valorTotal: (map['valor_total'] as num?)?.toDouble(),
    );
  }

  CotacaoDetalheModel copyWith({
    double? quantidade,
    double? valorUnitario,
    double? valorTotal,
  }) {
    return CotacaoDetalheModel(
      id: id,
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      nomeProdutoServico: nomeProdutoServico,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }
}
