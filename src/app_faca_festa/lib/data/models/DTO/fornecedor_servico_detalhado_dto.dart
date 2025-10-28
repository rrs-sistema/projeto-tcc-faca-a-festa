// lib/data/models/fornecedor_servico_detalhado_model.dart

class FornecedorServicoDetalhadoDto {
  final String idFornecedorServico;
  final String idFornecedor;
  final String idProdutoServico;
  final String? idSubcategoria;
  final String? nomeServico;
  final String? descricaoServico;
  final double preco;
  final double? precoPromocao;
  final String? nomeSubcategoria;
  final String? nomeCategoria;
  final String? imagemUrl;

  FornecedorServicoDetalhadoDto({
    required this.idFornecedorServico,
    required this.idFornecedor,
    required this.idProdutoServico,
    this.idSubcategoria,
    this.nomeServico,
    this.descricaoServico,
    required this.preco,
    this.precoPromocao,
    this.nomeSubcategoria,
    this.nomeCategoria,
    this.imagemUrl,
  });
}
