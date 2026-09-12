class FornecedorProdutoServico {
  final String id;
  final String idProdutoServico;
  final String idFornecedor;
  final String? idSubcategoria;
  final double preco;
  final double? precoPromocao;
  final bool ativo;
  final DateTime dataCadastro;
  final double? mediaServico;
  final int? totalAvaliacoesServico;

  FornecedorProdutoServico({
    required this.id,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.preco,
    this.idSubcategoria,
    this.mediaServico,
    this.totalAvaliacoesServico,
    this.precoPromocao,
    this.ativo = true,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  FornecedorProdutoServico copyWith({
    double? preco,
    double? precoPromocao,
    bool? ativo,
    String? idSubcategoria,
  }) {
    return FornecedorProdutoServico(
      id: id,
      idProdutoServico: idProdutoServico,
      idFornecedor: idFornecedor,
      preco: preco ?? this.preco,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      ativo: ativo ?? this.ativo,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      dataCadastro: dataCadastro,
      mediaServico: mediaServico,
      totalAvaliacoesServico: totalAvaliacoesServico,
    );
  }
}
