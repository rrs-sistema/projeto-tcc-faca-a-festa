import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/servico_produto/fornecedor_produto_servico_model.dart';
import '../../data/models/servico_produto/servico_produto_model.dart';
import '../repositories/servico_produto_repository.dart';

class GerenciarServicosProduto {
  GerenciarServicosProduto(this.repository);

  final ServicoProdutoRepository repository;

  Future<List<ServicoProdutoModel>> listarServicos() {
    return repository.listarServicos();
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivos() {
    return repository.listarServicosAtivos();
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) {
    return repository.listarServicosAtivosPorSubcategoria(idSubcategoria);
  }

  Future<List<ServicoProdutoModel>> listarServicosAtivosPorCategoriasFornecedor(
    String idFornecedor,
  ) {
    return repository.listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  }) {
    return repository.listarServicosComDetalhes(idFornecedor: idFornecedor);
  }

  Future<void> excluirServico(String id) {
    return repository.excluirServico(id);
  }

  Future<void> salvarServico(ServicoProdutoModel servico) {
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

  Future<void> salvarVinculo(FornecedorProdutoServicoModel vinculo) {
    return repository.salvarVinculo(vinculo);
  }

  Future<void> excluirVinculo(String id) {
    return repository.excluirVinculo(id);
  }
}
