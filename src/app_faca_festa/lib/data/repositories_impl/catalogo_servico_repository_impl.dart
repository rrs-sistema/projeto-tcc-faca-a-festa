import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_servico_repository.dart';
import '../datasources/remote/catalogo_servico_remote_datasource.dart';
import '../models/servico_produto/categoria_servico_model.dart'
    hide CategoriaServico;
import '../models/servico_produto/subcategoria_servico_model.dart'
    hide SubcategoriaServico;

class CatalogoServicoRepositoryImpl implements CatalogoServicoRepository {
  CatalogoServicoRepositoryImpl(this.remote);

  final CatalogoServicoRemoteDatasource remote;

  @override
  Future<List<CategoriaServico>> listarCategorias() {
    return remote.listarCategorias();
  }

  @override
  Future<Map<String, int>> contarSubcategoriasPorCategoria() {
    return remote.contarSubcategoriasPorCategoria();
  }

  @override
  Future<void> salvarCategoria(CategoriaServico categoria) {
    return remote.salvarCategoria(CategoriaServicoModel.fromEntity(categoria));
  }

  @override
  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo) {
    return remote.atualizarStatusCategoria(idCategoria, ativo);
  }

  @override
  Future<void> excluirCategoria(String idCategoria) {
    return remote.excluirCategoria(idCategoria);
  }

  @override
  Future<CatalogoServicoSeedResultado> popularCatalogoInicial() {
    return remote.popularCatalogoInicial();
  }

  @override
  Future<List<SubcategoriaServico>> listarSubcategorias({
    String? idCategoria,
  }) {
    return remote.listarSubcategorias(idCategoria: idCategoria);
  }

  @override
  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids) {
    return remote.contarServicosPorSubcategoria(ids);
  }

  @override
  Future<void> salvarSubcategoria(SubcategoriaServico subcategoria) {
    return remote.salvarSubcategoria(
      SubcategoriaServicoModel.fromEntity(subcategoria),
    );
  }

  @override
  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo) {
    return remote.atualizarStatusSubcategoria(idSubcategoria, ativo);
  }

  @override
  Future<void> excluirSubcategoria(String idSubcategoria) {
    return remote.excluirSubcategoria(idSubcategoria);
  }
}
