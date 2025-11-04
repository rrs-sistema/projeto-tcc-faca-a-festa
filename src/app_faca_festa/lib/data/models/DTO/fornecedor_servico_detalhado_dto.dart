// lib/data/models/fornecedor_servico_detalhado_model.dart

class FornecedorServicoDetalhadoDto {
  final String id;
  final String idFornecedor;
  final String idProdutoServico;
  final String? idSubcategoria;
  final String? nomeServico;
  final String? nomeFornecedor;
  final String? descricaoServico;
  final double preco;
  final double? precoPromocao;
  final String? nomeSubcategoria;
  final String? nomeCategoria;
  final String? imagemUrl;
  final String? tipoMedida;
  final bool ativo;

  FornecedorServicoDetalhadoDto({
    required this.id,
    required this.idFornecedor,
    required this.idProdutoServico,
    this.idSubcategoria,
    this.nomeServico,
    this.nomeFornecedor,
    this.descricaoServico,
    required this.preco,
    this.precoPromocao,
    this.nomeSubcategoria,
    this.nomeCategoria,
    this.imagemUrl,
    this.tipoMedida,
    required this.ativo,
  });
}
