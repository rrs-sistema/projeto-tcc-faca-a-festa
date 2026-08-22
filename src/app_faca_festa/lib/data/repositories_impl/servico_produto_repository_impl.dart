import '../../domain/repositories/servico_produto_repository.dart';
import '../datasources/remote/servico_produto_remote_datasource.dart';
import '../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../models/servico_produto/fornecedor_produto_servico_model.dart';
import '../models/servico_produto/servico_produto_model.dart';

class ServicoProdutoRepositoryImpl implements ServicoProdutoRepository {
  ServicoProdutoRepositoryImpl(this.remote);

  final ServicoProdutoRemoteDatasource remote;

  @override
  Future<List<ServicoProdutoModel>> listarServicos() {
    return remote.listarServicos();
  }

  @override
  Future<List<ServicoProdutoModel>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) {
    return remote.listarServicosAtivosPorSubcategoria(idSubcategoria);
  }

  @override
  Future<List<ServicoProdutoModel>> listarServicosAtivosPorCategoriasFornecedor(
      String idFornecedor) {
    return remote.listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  }) {
    return remote.listarServicosComDetalhes(idFornecedor: idFornecedor);
  }

  @override
  Future<void> excluirServico(String id) {
    return remote.excluirServico(id);
  }

  @override
  Future<void> salvarServico(ServicoProdutoModel servico) {
    return remote.salvarServico(servico);
  }

  @override
  Future<int> popularCatalogoInicial() {
    return remote.popularCatalogoInicial();
  }

  @override
  Stream<void> observarVinculosFornecedor(String idFornecedor) {
    return remote.observarVinculosFornecedor(idFornecedor);
  }

  @override
  Future<bool> validarSubcategoriaFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) {
    return remote.validarSubcategoriaFornecedor(idFornecedor, idSubcategoria);
  }

  @override
  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) {
    return remote.adicionarSubcategoriaAoFornecedor(
      idFornecedor,
      idSubcategoria,
    );
  }

  @override
  Future<void> salvarVinculo(FornecedorProdutoServicoModel vinculo) {
    return remote.salvarVinculo(vinculo);
  }

  @override
  Future<void> excluirVinculo(String id) {
    return remote.excluirVinculo(id);
  }
}
