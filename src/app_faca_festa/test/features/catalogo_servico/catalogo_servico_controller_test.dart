import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/categoria/categoria_servico_controller.dart';
import 'package:app_faca_festa/controllers/categoria/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/data/models/servico_produto/categoria_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/subcategoria_servico_model.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_servico_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_catalogo_servico.dart';

void main() {
  late _CatalogoServicoRepositoryFake repository;
  late GerenciarCatalogoServico catalogo;

  setUp(() {
    Get.testMode = true;
    repository = _CatalogoServicoRepositoryFake();
    catalogo = GerenciarCatalogoServico(repository);
  });

  tearDown(Get.reset);

  test('categoria controller delegates loading and keeps presentation filters',
      () async {
    final controller = CategoriaServicoController(catalogo: catalogo);
    repository.categorias = [
      CategoriaServicoModel(
        id: 'buffet',
        nome: 'Buffet',
        descricao: 'Comidas e bebidas',
        ordem: 2,
      ),
      CategoriaServicoModel(
        id: 'decoracao',
        nome: 'Decoração',
        ativo: false,
        ordem: 1,
      ),
    ];
    repository.contagemSubcategorias = {'buffet': 3};

    await controller.carregarCategorias();
    controller.filtroAtivo.value = true;
    controller.busca.value = 'comidas';

    expect(controller.categorias, hasLength(2));
    expect(controller.subcategoriasDe('buffet'), 3);
    expect(controller.categoriasFiltradas.map((c) => c.id), ['buffet']);
  });

  test('subcategoria controller delegates loading and service counting',
      () async {
    final controller = SubcategoriaServicoController(catalogo: catalogo);
    repository.subcategorias = [
      SubcategoriaServicoModel(
        id: 'bolos',
        idCategoria: 'buffet',
        nome: 'Bolos',
        ordem: 2,
      ),
      SubcategoriaServicoModel(
        id: 'doces',
        idCategoria: 'buffet',
        nome: 'Doces',
        ordem: 1,
      ),
      SubcategoriaServicoModel(
        id: 'flores',
        idCategoria: 'decoracao',
        nome: 'Flores',
      ),
    ];
    repository.contagemServicos = {'bolos': 4, 'doces': 7};

    await controller.carregarSubcategorias('buffet');

    expect(controller.subcategoriasFiltradas.map((s) => s.id), [
      'bolos',
      'doces',
    ]);
    expect(controller.visiveis.map((s) => s.id), ['doces', 'bolos']);
    expect(controller.servicosDe('doces'), 7);
  });
}

class _CatalogoServicoRepositoryFake implements CatalogoServicoRepository {
  List<CategoriaServicoModel> categorias = [];
  List<SubcategoriaServicoModel> subcategorias = [];
  Map<String, int> contagemSubcategorias = {};
  Map<String, int> contagemServicos = {};

  @override
  Future<List<CategoriaServicoModel>> listarCategorias() async => categorias;

  @override
  Future<Map<String, int>> contarSubcategoriasPorCategoria() async {
    return contagemSubcategorias;
  }

  @override
  Future<void> salvarCategoria(CategoriaServicoModel categoria) async {}

  @override
  Future<void> atualizarStatusCategoria(String idCategoria, bool ativo) async {}

  @override
  Future<void> excluirCategoria(String idCategoria) async {}

  @override
  Future<CatalogoServicoSeedResultado> popularCatalogoInicial() async {
    return (categorias: 0, subcategorias: 0);
  }

  @override
  Future<List<SubcategoriaServicoModel>> listarSubcategorias({
    String? idCategoria,
  }) async {
    if (idCategoria == null || idCategoria.isEmpty) return subcategorias;
    return subcategorias.where((s) => s.idCategoria == idCategoria).toList();
  }

  @override
  Future<Map<String, int>> contarServicosPorSubcategoria(
      List<String> ids) async {
    return {for (final id in ids) id: contagemServicos[id] ?? 0};
  }

  @override
  Future<void> salvarSubcategoria(
      SubcategoriaServicoModel subcategoria) async {}

  @override
  Future<void> atualizarStatusSubcategoria(
    String idSubcategoria,
    bool ativo,
  ) async {}

  @override
  Future<void> excluirSubcategoria(String idSubcategoria) async {}
}
