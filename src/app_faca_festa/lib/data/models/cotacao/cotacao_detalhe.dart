class CotacaoDetalheModel {
  final int idCotacaoDetalhe;
  final int idCotacao;
  final int idFornecedorCotacao;
  final double? quantidade;
  final double? valorUnitario;
  final double? valorSubtotal;
  final double? taxaDesconto;
  final double? valorDesconto;
  final double? valorTotal;

  const CotacaoDetalheModel({
    required this.idCotacaoDetalhe,
    required this.idCotacao,
    required this.idFornecedorCotacao,
    this.quantidade,
    this.valorUnitario,
    this.valorSubtotal,
    this.taxaDesconto,
    this.valorDesconto,
    this.valorTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_cotacao_detalhe': idCotacaoDetalhe,
      'id_cotacao': idCotacao,
      'id_fornecedor_cotacao': idFornecedorCotacao,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
      'valor_subtotal': valorSubtotal,
      'taxa_desconto': taxaDesconto,
      'valor_desconto': valorDesconto,
      'valor_total': valorTotal,
    };
  }

  factory CotacaoDetalheModel.fromMap(Map<String, dynamic> map) {
    return CotacaoDetalheModel(
      idCotacaoDetalhe: map['id_cotacao_detalhe'] is int
          ? map['id_cotacao_detalhe']
          : int.tryParse(map['id_cotacao_detalhe'].toString()) ?? 0,
      idCotacao: map['id_cotacao'] is int
          ? map['id_cotacao']
          : int.tryParse(map['id_cotacao'].toString()) ?? 0,
      idFornecedorCotacao: map['id_fornecedor_cotacao'] is int
          ? map['id_fornecedor_cotacao']
          : int.tryParse(map['id_fornecedor_cotacao'].toString()) ?? 0,
      quantidade: (map['quantidade'] as num?)?.toDouble(),
      valorUnitario: (map['valor_unitario'] as num?)?.toDouble(),
      valorSubtotal: (map['valor_subtotal'] as num?)?.toDouble(),
      taxaDesconto: (map['taxa_desconto'] as num?)?.toDouble(),
      valorDesconto: (map['valor_desconto'] as num?)?.toDouble(),
      valorTotal: (map['valor_total'] as num?)?.toDouble(),
    );
  }

  CotacaoDetalheModel copyWith({
    double? quantidade,
    double? valorUnitario,
    double? valorSubtotal,
    double? taxaDesconto,
    double? valorDesconto,
    double? valorTotal,
  }) {
    return CotacaoDetalheModel(
      idCotacaoDetalhe: idCotacaoDetalhe,
      idCotacao: idCotacao,
      idFornecedorCotacao: idFornecedorCotacao,
      quantidade: quantidade ?? this.quantidade,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      valorSubtotal: valorSubtotal ?? this.valorSubtotal,
      taxaDesconto: taxaDesconto ?? this.taxaDesconto,
      valorDesconto: valorDesconto ?? this.valorDesconto,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }
}
