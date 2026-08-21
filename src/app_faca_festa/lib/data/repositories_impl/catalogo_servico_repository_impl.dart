import '../../domain/repositories/catalogo_servico_repository.dart';
import '../datasources/remote/catalogo_servico_remote_datasource.dart';
import '../models/servico_produto/categoria_servico_model.dart';
import '../models/servico_produto/subcategoria_servico_model.dart';

class CatalogoServicoRepositoryImpl implements CatalogoServicoRepository {
  CatalogoServicoRepositoryImpl(this.remote);

  final CatalogoServicoRemoteDatasource remote;

  @override
  Future<List<CategoriaServicoModel>> listarCategorias() {
    return remote.listarCategorias();
  }

  @override
  Future<Map<String, int>> contarSubcategoriasPorCategoria() {
    return remote.contarSubcategoriasPorCategoria();
  }

  @override
  Future<void> salvarCategoria(CategoriaServicoModel categoria) {
    return remote.salvarCategoria(categoria);
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
  Future<List<SubcategoriaServicoModel>> listarSubcategorias({
    String? idCategoria,
  }) {
    return remote.listarSubcategorias(idCategoria: idCategoria);
  }

  @override
  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids) {
    return remote.contarServicosPorSubcategoria(ids);
  }

  @override
  Future<void> salvarSubcategoria(SubcategoriaServicoModel subcategoria) {
    return remote.salvarSubcategoria(subcategoria);
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
