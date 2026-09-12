class FornecedorServicoDetalhado {
  final String id;
  final String idFornecedor;
  final String idProdutoServico;
  final String? idSubcategoria;
  final String? nomeServico;
  final String? nomeFornecedor;
  final String? descricaoServico;
  final double preco;
  final int quantidade;
  final double? precoPromocao;
  final String? nomeSubcategoria;
  final String? nomeCategoria;
  final String? imagemUrl;
  final String? tipoMedida;
  final bool ativo;

  const FornecedorServicoDetalhado({
    required this.id,
    required this.idFornecedor,
    required this.idProdutoServico,
    this.idSubcategoria,
    this.nomeServico,
    this.nomeFornecedor,
    this.descricaoServico,
    required this.preco,
    required this.quantidade,
    this.precoPromocao,
    this.nomeSubcategoria,
    this.nomeCategoria,
    this.imagemUrl,
    this.tipoMedida,
    required this.ativo,
  });

  double get precoEfetivo {
    if (precoPromocao != null && precoPromocao! > 0) return precoPromocao!;
    return preco;
  }

  FornecedorServicoDetalhado copyWith({
    String? id,
    String? idFornecedor,
    String? idProdutoServico,
    String? idSubcategoria,
    String? nomeServico,
    String? nomeFornecedor,
    String? descricaoServico,
    double? preco,
    int? quantidade,
    double? precoPromocao,
    String? nomeSubcategoria,
    String? nomeCategoria,
    String? imagemUrl,
    String? tipoMedida,
    bool? ativo,
  }) {
    return FornecedorServicoDetalhado(
      id: id ?? this.id,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idProdutoServico: idProdutoServico ?? this.idProdutoServico,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      nomeServico: nomeServico ?? this.nomeServico,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      descricaoServico: descricaoServico ?? this.descricaoServico,
      preco: preco ?? this.preco,
      quantidade: quantidade ?? this.quantidade,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      nomeSubcategoria: nomeSubcategoria ?? this.nomeSubcategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      ativo: ativo ?? this.ativo,
    );
  }
}
