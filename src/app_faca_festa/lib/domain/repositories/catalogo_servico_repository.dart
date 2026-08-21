import '../../data/models/servico_produto/categoria_servico_model.dart';
import '../../data/models/servico_produto/subcategoria_servico_model.dart';

typedef CatalogoServicoSeedResultado = ({int categorias, int subcategorias});

abstract interface class CatalogoServicoRepository {
  Future<List<CategoriaServicoModel>> listarCategorias();

  Future<Map<String, int>> contarSubcategoriasPorCategoria();

  Future<void> salvarCategoria(CategoriaServicoModel categoria);

  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo);

  Future<void> excluirCategoria(String idCategoria);

  Future<CatalogoServicoSeedResultado> popularCatalogoInicial();

  Future<List<SubcategoriaServicoModel>> listarSubcategorias({
    String? idCategoria,
  });

  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids);

  Future<void> salvarSubcategoria(SubcategoriaServicoModel subcategoria);

  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo);

  Future<void> excluirSubcategoria(String idSubcategoria);
}
