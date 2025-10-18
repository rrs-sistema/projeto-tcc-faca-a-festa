class FornecedorCotacaoModel {
  final int idFornecedorCotacao;
  final int idCotacao;
  final String idFornecedor;
  final String? prazoEntrega;
  final String? condicaoPagamento;

  const FornecedorCotacaoModel({
    required this.idFornecedorCotacao,
    required this.idCotacao,
    required this.idFornecedor,
    this.prazoEntrega,
    this.condicaoPagamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_fornecedor_cotacao': idFornecedorCotacao,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'prazo_entrega': prazoEntrega,
      'condicao_pagamento': condicaoPagamento,
    };
  }

  factory FornecedorCotacaoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCotacaoModel(
      idFornecedorCotacao: map['id_fornecedor_cotacao'] is int
          ? map['id_fornecedor_cotacao']
          : int.tryParse(map['id_fornecedor_cotacao'].toString()) ?? 0,
      idCotacao: map['id_cotacao'] is int
          ? map['id_cotacao']
          : int.tryParse(map['id_cotacao'].toString()) ?? 0,
      idFornecedor: map['id_fornecedor'] ?? '',
      prazoEntrega: map['prazo_entrega'],
      condicaoPagamento: map['condicao_pagamento'],
    );
  }

  FornecedorCotacaoModel copyWith({
    String? prazoEntrega,
    String? condicaoPagamento,
  }) {
    return FornecedorCotacaoModel(
      idFornecedorCotacao: idFornecedorCotacao,
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      prazoEntrega: prazoEntrega ?? this.prazoEntrega,
      condicaoPagamento: condicaoPagamento ?? this.condicaoPagamento,
    );
  }
}
