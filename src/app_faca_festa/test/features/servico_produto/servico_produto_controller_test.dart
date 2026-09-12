import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/repositories/servico_produto_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ServicoProdutoRepositoryFake repository;
  late ServicoProdutoController controller;

  setUp(() {
    Get.testMode = true;
    repository = _ServicoProdutoRepositoryFake();
    controller = ServicoProdutoController(
      servicos: GerenciarServicosProduto(repository),
    );
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
    Get.reset();
  });

  test('loads services by subcategory and updates the presentation cache',
      () async {
    repository.servicosPorSubcategoria['doces'] = [
      const ServicoProduto(
        id: 'bolo-chocolate',
        nome: 'Bolo de chocolate',
        idSubcategoria: 'doces',
        ativo: true,
      ),
    ];

    final resultado = await controller.carregarServicosPorSubcategoria('doces');

    expect(resultado.map((s) => s.id), ['bolo-chocolate']);
    expect(controller.servicos.map((s) => s.id), ['bolo-chocolate']);
    expect(controller.servicosPorSubcategoria['doces'], resultado);
  });

  test('loads detailed supplier services through the use case', () async {
    repository.detalhados = [
      const FornecedorServicoDetalhado(
        id: 'bolo-chocolate',
        idFornecedor: 'fornecedor-1',
        idProdutoServico: 'bolo-chocolate',
        nomeServico: 'Bolo de chocolate',
        preco: 150,
        quantidade: 1,
        ativo: true,
      ),
    ];

    await controller.carregarServicosComDetalhesOtimizado(
      idFornecedor: 'fornecedor-1',
    );

    expect(repository.ultimoFornecedorDetalhes, 'fornecedor-1');
    expect(
        controller.servicosFornecedor.single.nomeServico, 'Bolo de chocolate');
  });

  test('saving supplier link validates and creates missing subcategory',
      () async {
    repository.subcategoriaValida = false;

    await controller.vincularServico(
      FornecedorProdutoServico(
        id: 'fornecedor-1_bolo-chocolate',
        idFornecedor: 'fornecedor-1',
        idProdutoServico: 'bolo-chocolate',
        idSubcategoria: 'doces',
        preco: 150,
      ),
    );

    expect(repository.subcategoriaAdicionada, ('fornecedor-1', 'doces'));
    expect(repository.vinculoSalvo?.idProdutoServico, 'bolo-chocolate');
  });
}

class _ServicoProdutoRepositoryFake implements ServicoProdutoRepository {
  final Map<String, List<ServicoProduto>> servicosPorSubcategoria = {};
  final _streamController = StreamController<void>.broadcast();

  List<ServicoProduto> servicos = [];
  List<FornecedorServicoDetalhado> detalhados = [];
  String? ultimoFornecedorDetalhes;
  bool subcategoriaValida = true;
  (String, String)? subcategoriaAdicionada;
  FornecedorProdutoServico? vinculoSalvo;

  Future<void> close() => _streamController.close();

  @override
  Future<List<ServicoProduto>> listarServicos() async => servicos;

  @override
  Future<List<ServicoProduto>> listarServicosAtivos() async => servicos;

  @override
  Future<List<ServicoProduto>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) async {
    return servicosPorSubcategoria[idSubcategoria] ?? [];
  }

  @override
  Future<List<ServicoProduto>> listarServicosAtivosPorCategoriasFornecedor(
      String idFornecedor) async {
    return servicos;
  }

  @override
  Future<List<FornecedorServicoDetalhado>> listarServicosComDetalhes({
    String? idFornecedor,
  }) async {
    ultimoFornecedorDetalhes = idFornecedor;
    return detalhados;
  }

  @override
  Future<void> excluirServico(String id) async {}

  @override
  Future<void> salvarServico(ServicoProduto servico) async {}

  @override
  Future<int> popularCatalogoInicial() async => 0;

  @override
  Stream<void> observarVinculosFornecedor(String idFornecedor) {
    return _streamController.stream;
  }

  @override
  Future<bool> validarSubcategoriaFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) async {
    return subcategoriaValida;
  }

  @override
  Future<void> adicionarSubcategoriaAoFornecedor(
    String idFornecedor,
    String idSubcategoria,
  ) async {
    subcategoriaAdicionada = (idFornecedor, idSubcategoria);
  }

  @override
  Future<void> salvarVinculo(FornecedorProdutoServico vinculo) async {
    vinculoSalvo = vinculo;
  }

  @override
  Future<void> excluirVinculo(String id) async {}
}
