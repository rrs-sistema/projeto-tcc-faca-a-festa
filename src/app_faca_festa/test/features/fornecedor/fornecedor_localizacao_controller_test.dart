import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_localizacao_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedor_localizacao.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';

void main() {
  late _FornecedorLocalizacaoRepositoryFake repository;
  late FornecedorLocalizacaoController controller;

  setUp(() {
    Get.testMode = true;
    Get.put<AutenticacaoRepository>(_AuthFake());
    repository = _FornecedorLocalizacaoRepositoryFake();
    controller = FornecedorLocalizacaoController(
      localizacao: GerenciarFornecedorLocalizacao(repository),
    );
    controller.userLatitude.value = -25.43;
    controller.userLongitude.value = -49.27;
  });

  tearDown(() async {
    await controller.encerrarEscutas();
    await repository.dispose();
    Get.reset();
  });

  test('stops loading and lists suppliers even without territory', () async {
    await controller.inicializar();

    repository.categorias.add([
      const CategoriaServico(id: 'buffet', nome: 'Buffet'),
    ]);
    repository.fornecedores.add([
      Fornecedor(
        idFornecedor: 'fornecedor-1',
        idUsuario: 'usuario-1',
        razaoSocial: 'Ateliê Noivas & Trajes',
        telefone: '41999999999',
        email: 'atelie@email.com',
        dataCadastro: DateTime(2026),
        aptoParaOperar: true,
      ),
    ]);
    repository.territorios.add(const []);
    repository.relacoes.add([
      const FornecedorCategoria(
        idFornecedor: 'fornecedor-1',
        idCategoria: 'buffet',
      ),
    ]);
    repository.avaliacoes.add(const {});

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(controller.carregando.value, isFalse);
    expect(controller.fornecedores, hasLength(1));
    expect(controller.fornecedoresFiltrados, hasLength(1));
    expect(
      controller.fornecedores.single.fornecedor.razaoSocial,
      'Ateliê Noivas & Trajes',
    );
  });
}

class _AuthFake extends Fake implements AutenticacaoRepository {
  @override
  String? get idUsuarioAtual => 'usuario-1';
}

class _FornecedorLocalizacaoRepositoryFake
    implements FornecedorLocalizacaoRepository {
  final categorias = StreamController<List<CategoriaServico>>.broadcast();
  final fornecedores = StreamController<List<Fornecedor>>.broadcast();
  final territorios = StreamController<List<Territorio>>.broadcast();
  final relacoes = StreamController<List<FornecedorCategoria>>.broadcast();
  final avaliacoes = StreamController<Map<String, double>>.broadcast();

  @override
  Stream<List<CategoriaServico>> observarCategoriasAtivas() => categorias.stream;

  @override
  Stream<List<Fornecedor>> observarFornecedoresAtivos() => fornecedores.stream;

  @override
  Stream<List<Territorio>> observarTerritoriosAtivos() => territorios.stream;

  @override
  Stream<List<FornecedorCategoria>> observarCategoriasFornecedor() =>
      relacoes.stream;

  @override
  Stream<Map<String, double>> observarMediasAvaliacoes() => avaliacoes.stream;

  @override
  Stream<List<FornecedorServicoDetalhado>> observarServicosFornecedor(
    String idFornecedor,
  ) =>
      const Stream.empty();

  @override
  Stream<List<FornecedorServicoDetalhado>> observarTodosServicos() =>
      const Stream.empty();

  @override
  Future<List<FornecedorServicoDetalhado>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  ) async =>
      const [];

  @override
  Future<List<FornecedorServicoDetalhado>> listarServicosPorCategoria(
    String idCategoria,
  ) async =>
      const [];

  @override
  Future<List<FornecedorServicoDetalhado>>
      listarFornecedoresSemCategoria() async => const [];

  Future<void> dispose() async {
    await categorias.close();
    await fornecedores.close();
    await territorios.close();
    await relacoes.close();
    await avaliacoes.close();
  }
}
