import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/servico/servico_produto_controller.dart';
import 'package:app_faca_festa/data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_produto_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/servico_produto_model.dart';
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
      const ServicoProdutoModel(
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
      FornecedorServicoDetalhadoDto(
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
      FornecedorProdutoServicoModel(
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
  final Map<String, List<ServicoProdutoModel>> servicosPorSubcategoria = {};
  final _streamController = StreamController<void>.broadcast();

  List<ServicoProdutoModel> servicos = [];
  List<FornecedorServicoDetalhadoDto> detalhados = [];
  String? ultimoFornecedorDetalhes;
  bool subcategoriaValida = true;
  (String, String)? subcategoriaAdicionada;
  FornecedorProdutoServicoModel? vinculoSalvo;

  Future<void> close() => _streamController.close();

  @override
  Future<List<ServicoProdutoModel>> listarServicos() async => servicos;

  @override
  Future<List<ServicoProdutoModel>> listarServicosAtivosPorSubcategoria(
    String idSubcategoria,
  ) async {
    return servicosPorSubcategoria[idSubcategoria] ?? [];
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarServicosComDetalhes({
    String? idFornecedor,
  }) async {
    ultimoFornecedorDetalhes = idFornecedor;
    return detalhados;
  }

  @override
  Future<void> excluirServico(String id) async {}

  @override
  Future<void> salvarServico(ServicoProdutoModel servico) async {}

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
  Future<void> salvarVinculo(FornecedorProdutoServicoModel vinculo) async {
    vinculoSalvo = vinculo;
  }

  @override
  Future<void> excluirVinculo(String id) async {}
}
