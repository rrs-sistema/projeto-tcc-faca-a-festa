class ServicoFotoModel {
  final String id;
  final String idProdutoServico;
  final String idFornecedor;
  final String url;

  const ServicoFotoModel({
    required this.id,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_produto_servico': idProdutoServico,
      'id_fornecedor': idFornecedor,
      'url': url,
    };
  }

  factory ServicoFotoModel.fromMap(Map<String, dynamic> map) {
    return ServicoFotoModel(
      id: map['id'] ?? '',
      idProdutoServico: map['id_produto_servico'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      url: map['url'] ?? '',
    );
  }
}
