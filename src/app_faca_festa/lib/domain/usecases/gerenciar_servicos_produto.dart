import '../entities/fornecedor_servico_detalhado.dart';
import '../entities/fornecedor_produto_servico.dart';
import '../entities/servico_produto.dart';
import '../repositories/servico_produto_repository.dart';

class GerenciarServicosProduto {
  GerenciarServicosProduto(this.repository);

  final ServicoProdutoRepository repository;

  Future<List<ServicoProduto>> listarServicos() {
    return repository.listarServicos();
  }

  Future<List<ServicoProduto>> listarServicosAtivos() {
    return repository.listarServicosAtivos();
  }

  Future<List<ServicoProduto>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) {
    return repository.listarServicosAtivosPorSubcategoria(idSubcategoria);
  }

  Future<List<ServicoProduto>> listarServicosAtivosPorCategoriasFornecedor(
    String idFornecedor,
  ) {
    return repository.listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
  }

  Future<List<FornecedorServicoDetalhado>> listarServicosComDetalhes({
    String? idFornecedor,
  }) {
    return repository.listarServicosComDetalhes(idFornecedor: idFornecedor);
  }

  Future<void> excluirServico(String id) {
    return repository.excluirServico(id);
  }

  Future<void> salvarServico(ServicoProduto servico) {
    return repository.salvarServico(servico);
  }

  Future<int> popularCatalogoInicial() {
    return repository.popularCatalogoInicial();
  }

  Stream<void> observarVinculosFornecedor(String idFornecedor) {
    return repository.observarVinculosFornecedor(idFornecedor);
  }

  Future<bool> validarSubcategoriaFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) {
    return repository.validarSubcategoriaFornecedor(
      idFornecedor,
      idSubcategoria,
    );
  }

  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) {
    return repository.adicionarSubcategoriaAoFornecedor(
      idFornecedor,
      idSubcategoria,
    );
  }

  Future<void> salvarVinculo(FornecedorProdutoServico vinculo) {
    return repository.salvarVinculo(vinculo);
  }

  Future<void> excluirVinculo(String id) {
    return repository.excluirVinculo(id);
  }
}
