import '../entities/categoria_servico.dart';
import '../entities/subcategoria_servico.dart';

typedef CatalogoServicoSeedResultado = ({int categorias, int subcategorias});

abstract interface class CatalogoServicoRepository {
  Future<List<CategoriaServico>> listarCategorias();

  Future<Map<String, int>> contarSubcategoriasPorCategoria();

  Future<void> salvarCategoria(CategoriaServico categoria);

  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo);

  Future<void> excluirCategoria(String idCategoria);

  Future<CatalogoServicoSeedResultado> popularCatalogoInicial();

  Future<List<SubcategoriaServico>> listarSubcategorias({
    String? idCategoria,
  });

  Future<Map<String, int>> contarServicosPorSubcategoria(List<String> ids);

  Future<void> salvarSubcategoria(SubcategoriaServico subcategoria);

  Future<void> atualizarStatusSubcategoria(String idSubcategoria, bool ativo);

  Future<void> excluirSubcategoria(String idSubcategoria);
}
