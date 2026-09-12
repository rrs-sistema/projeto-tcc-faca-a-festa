import 'fornecedor_produto_servico.dart';

class FornecedorEstatisticas {
  const FornecedorEstatisticas({
    required this.solicitacoesPendentes,
    required this.servicosAtivos,
    required this.mensagensNaoLidas,
    required this.avaliacaoMedia,
  });

  final int solicitacoesPendentes;
  final List<FornecedorProdutoServico> servicosAtivos;
  final int mensagensNaoLidas;
  final double avaliacaoMedia;
}
