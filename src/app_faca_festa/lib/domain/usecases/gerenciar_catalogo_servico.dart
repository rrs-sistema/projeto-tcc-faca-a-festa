import '../../data/models/servico_produto/categoria_servico_model.dart';
import '../../data/models/servico_produto/subcategoria_servico_model.dart';
import '../repositories/catalogo_servico_repository.dart';

class GerenciarCatalogoServico {
  GerenciarCatalogoServico(this.repository);

  final CatalogoServicoRepository repository;

  Future<List<CategoriaServicoModel>> listarCategorias() {
    return repository.listarCategorias();
  }

  Future<Map<String, int>> contarSubcategoriasPorCategoria() {
    return repository.contarSubcategoriasPorCategoria();
  }

  Future<void> salvarCategoria(CategoriaServicoModel categoria) {
    return repository.salvarCategoria(categoria);
  }

  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo) {
    return repository.atualizarStatusCategoria(idCategoria, ativo);
  }

  Future<void> excluirCategoria(String idCategoria) {
    return repository.excluirCategoria(idCategoria);
  }

  Future<CatalogoServicoSeedResultado> popularCatalogoInicial() {
    return repository.popularCatalogoInicial();
  }

  Future<List<SubcategoriaServicoModel>> listarSubcategorias({
    String? idCategoria,
  }) {
    return repository.listarSubcategorias(idCategoria: idCategoria);
  }

  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids) {
    return repository.contarServicosPorSubcategoria(ids);
  }

  Future<void> salvarSubcategoria(SubcategoriaServicoModel subcategoria) {
    return repository.salvarSubcategoria(subcategoria);
  }

  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo) {
    return repository.atualizarStatusSubcategoria(idSubcategoria, ativo);
  }

  Future<void> excluirSubcategoria(String idSubcategoria) {
    return repository.excluirSubcategoria(idSubcategoria);
  }
}
