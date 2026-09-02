import '../servico_produto/fornecedor_produto_servico_model.dart';

class FornecedorEstatisticasModel {
  const FornecedorEstatisticasModel({
    required this.solicitacoesPendentes,
    required this.servicosAtivos,
    required this.mensagensNaoLidas,
    required this.avaliacaoMedia,
  });

  final int solicitacoesPendentes;
  final List<FornecedorProdutoServicoModel> servicosAtivos;
  final int mensagensNaoLidas;
  final double avaliacaoMedia;
}
