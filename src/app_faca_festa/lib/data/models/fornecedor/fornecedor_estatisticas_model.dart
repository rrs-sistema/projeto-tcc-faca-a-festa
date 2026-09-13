import 'package:app_faca_festa/domain/entities/fornecedor_estatisticas.dart';
import '../servico_produto/fornecedor_produto_servico_model.dart';


class FornecedorEstatisticasModel extends FornecedorEstatisticas {
  const FornecedorEstatisticasModel({
    required super.solicitacoesPendentes,
    required List<FornecedorProdutoServicoModel> servicosAtivos,
    required super.mensagensNaoLidas,
    required super.avaliacaoMedia,
  }) : super(servicosAtivos: servicosAtivos);
}
