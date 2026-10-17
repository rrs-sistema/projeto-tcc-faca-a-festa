import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_servico_repository.dart';
import '../datasources/remote/catalogo_servico_remote_datasource.dart';
import '../models/servico_produto/categoria_servico_model.dart';
import '../models/servico_produto/subcategoria_servico_model.dart';

class CatalogoServicoRepositoryImpl implements CatalogoServicoRepository {
  CatalogoServicoRepositoryImpl(this.remote);

  final CatalogoServicoRemoteDatasource remote;

  @override
  Future<List<CategoriaServico>> listarCategorias() {
    return UpdateOperations.run(() async {
      return remote.listarCategorias();
    });
  }

  @override
  Future<Map<String, int>> contarSubcategoriasPorCategoria() {
    return UpdateOperations.run(() async {
      return remote.contarSubcategoriasPorCategoria();
    });
  }

  @override
  Future<void> salvarCategoria(CategoriaServico categoria) {
    return UpdateOperations.run(() async {
      return remote
          .salvarCategoria(CategoriaServicoModel.fromEntity(categoria));
    });
  }

  @override
  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatusCategoria(idCategoria, ativo);
    });
  }

  @override
  Future<void> excluirCategoria(String idCategoria) {
    return UpdateOperations.run(() async {
      return remote.excluirCategoria(idCategoria);
    });
  }

  @override
  Future<CatalogoServicoSeedResultado> popularCatalogoInicial() {
    return UpdateOperations.run(() async {
      return remote.popularCatalogoInicial();
    });
  }

  @override
  Future<List<SubcategoriaServico>> listarSubcategorias({
    String? idCategoria,
  }) {
    return UpdateOperations.run(() async {
      return remote.listarSubcategorias(idCategoria: idCategoria);
    });
  }

  @override
  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids) {
    return UpdateOperations.run(() async {
      return remote.contarServicosPorSubcategoria(ids);
    });
  }

  @override
  Future<void> salvarSubcategoria(SubcategoriaServico subcategoria) {
    return UpdateOperations.run(() async {
      return remote.salvarSubcategoria(
        SubcategoriaServicoModel.fromEntity(subcategoria),
      );
    });
  }

  @override
  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatusSubcategoria(idSubcategoria, ativo);
    });
  }

  @override
  Future<void> excluirSubcategoria(String idSubcategoria) {
    return UpdateOperations.run(() async {
      return remote.excluirSubcategoria(idSubcategoria);
    });
  }
}
