import '../entities/fornecedor_servico_detalhado.dart';
import '../entities/fornecedor_produto_servico.dart';
import '../entities/servico_produto.dart';

abstract interface class ServicoProdutoRepository {
  Future<List<ServicoProduto>> listarServicos();

  Future<List<ServicoProduto>> listarServicosAtivos();

  Future<List<ServicoProduto>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  );

  Future<List<ServicoProduto>> listarServicosAtivosPorCategoriasFornecedor(
      String idFornecedor);

  Future<List<FornecedorServicoDetalhado>> listarServicosComDetalhes({
    String? idFornecedor,
  });

  Future<void> excluirServico(String id);

  Future<void> salvarServico(ServicoProduto servico);

  Future<int> popularCatalogoInicial();

  Stream<void> observarVinculosFornecedor(String idFornecedor);

  Future<bool> validarSubcategoriaFornecedor(
    String idFornecedor,
    String idSubcategoria,
  );

  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  );

  Future<void> salvarVinculo(FornecedorProdutoServico vinculo);

  Future<void> excluirVinculo(String id);
}
