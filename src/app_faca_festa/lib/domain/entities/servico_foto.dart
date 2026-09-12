class ServicoFoto {
  final String id;
  final String idProdutoServico;
  final String idFornecedor;
  final String url;
  final DateTime dataUpload;

  ServicoFoto({
    required this.id,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.url,
    DateTime? dataUpload,
  }) : dataUpload = dataUpload ?? DateTime.now();

  ServicoFoto copyWith({
    String? idProdutoServico,
    String? idFornecedor,
    String? url,
    DateTime? dataUpload,
  }) {
    return ServicoFoto(
      id: id,
      idProdutoServico: idProdutoServico ?? this.idProdutoServico,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      url: url ?? this.url,
      dataUpload: dataUpload ?? this.dataUpload,
    );
  }
}
