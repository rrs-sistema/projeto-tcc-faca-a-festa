import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/servico_produto/fornecedor_produto_servico_model.dart';
import '../../data/models/servico_produto/servico_produto_model.dart';

abstract interface class ServicoProdutoRepository {
  Future<List<ServicoProdutoModel>> listarServicos();

  Future<List<ServicoProdutoModel>> listarServicosAtivos();

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  );

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorCategoriasFornecedor(
      String idFornecedor);

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  });

  Future<void> excluirServico(String id);

  Future<void> salvarServico(ServicoProdutoModel servico);

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

  Future<void> salvarVinculo(FornecedorProdutoServicoModel vinculo);

  Future<void> excluirVinculo(String id);
}
