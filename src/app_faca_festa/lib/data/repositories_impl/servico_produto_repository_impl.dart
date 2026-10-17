import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/repositories/servico_produto_repository.dart';
import '../datasources/remote/servico_produto_remote_datasource.dart';
import '../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../models/servico_produto/fornecedor_produto_servico_model.dart';
import '../models/servico_produto/servico_produto_model.dart';

class ServicoProdutoRepositoryImpl implements ServicoProdutoRepository {
  ServicoProdutoRepositoryImpl(this.remote);

  final ServicoProdutoRemoteDatasource remote;

  @override
  Future<List<ServicoProduto>> listarServicos() {
    return UpdateOperations.run(() async {
      return remote.listarServicos();
    });
  }

  @override
  Future<List<ServicoProduto>> listarServicosAtivos() {
    return UpdateOperations.run(() async {
      return remote.listarServicosAtivos();
    });
  }

  @override
  Future<List<ServicoProduto>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) {
    return UpdateOperations.run(() async {
      return remote.listarServicosAtivosPorSubcategoria(idSubcategoria);
    });
  }

  @override
  Future<List<ServicoProduto>> listarServicosAtivosPorCategoriasFornecedor(
      String idFornecedor) {
    return UpdateOperations.run(() async {
      return remote.listarServicosAtivosPorCategoriasFornecedor(idFornecedor);
    });
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  }) {
    return UpdateOperations.run(() async {
      return remote.listarServicosComDetalhes(idFornecedor: idFornecedor);
    });
  }

  @override
  Future<void> excluirServico(String id) {
    return UpdateOperations.run(() async {
      return remote.excluirServico(id);
    });
  }

  @override
  Future<void> salvarServico(ServicoProduto servico) {
    return UpdateOperations.run(() async {
      return remote.salvarServico(ServicoProdutoModel.fromEntity(servico));
    });
  }

  @override
  Future<int> popularCatalogoInicial() {
    return UpdateOperations.run(() async {
      return remote.popularCatalogoInicial();
    });
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
    return UpdateOperations.run(() async {
      return remote.validarSubcategoriaFornecedor(idFornecedor, idSubcategoria);
    });
  }

  @override
  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) {
    return UpdateOperations.run(() async {
      return remote.adicionarSubcategoriaAoFornecedor(
        idFornecedor,
        idSubcategoria,
      );
    });
  }

  @override
  Future<void> salvarVinculo(FornecedorProdutoServico vinculo) {
    return UpdateOperations.run(() async {
      return remote.salvarVinculo(
        FornecedorProdutoServicoModel.fromEntity(vinculo),
      );
    });
  }

  @override
  Future<void> excluirVinculo(String id) {
    return UpdateOperations.run(() async {
      return remote.excluirVinculo(id);
    });
  }
}
