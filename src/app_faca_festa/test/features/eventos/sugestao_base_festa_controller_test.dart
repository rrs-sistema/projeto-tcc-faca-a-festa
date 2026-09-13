import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/calculadora/controllers/sugestao_base_festa_controller.dart';
import 'package:app_faca_festa/domain/entities/gatilhos_sugestao_base_festa.dart';
import 'package:app_faca_festa/domain/entities/sugestao_base_festa.dart';
import 'package:app_faca_festa/domain/repositories/sugestao_base_festa_repository_contract.dart';

void main() {
  late _SugestaoBaseFestaRepositoryFake repository;
  late SugestaoBaseFestaController controller;

  setUp(() {
    Get.testMode = true;
    repository = _SugestaoBaseFestaRepositoryFake();
    controller = SugestaoBaseFestaController(repository: repository);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('loads suggestions through repository and applies initial ordering',
      () async {
    repository.sugestoes = [
      _sugestao(id: 'b', titulo: 'Bolo', modulo: 'calculadora', ordem: 2),
      _sugestao(id: 'a', titulo: 'Água', modulo: 'orcamento', ordem: 1),
    ];

    await controller.carregarSugestoes();

    expect(repository.listagens, 1);
    expect(controller.listaSugestoes, hasLength(2));
    expect(controller.listaFiltrada.map((item) => item.id), ['a', 'b']);
    expect(controller.loading.value, isFalse);
    expect(controller.error.value, isEmpty);
  });

  test('filters suggestions by module, active flag and text search', () async {
    controller.listaSugestoes.assignAll([
      _sugestao(id: 'calc', titulo: 'Bebidas', modulo: 'calculadora'),
      _sugestao(id: 'orc', titulo: 'Reserva', modulo: 'orcamento'),
      _sugestao(
        id: 'off',
        titulo: 'Antiga',
        modulo: 'calculadora',
        ativo: false,
      ),
    ]);

    controller.filtroModulo.value = 'calculadora';
    controller.filtroAtivo.value = 'ativos';
    controller.buscaTexto.value = 'bebidas';
    controller.aplicarFiltros();

    expect(controller.listaFiltrada.map((item) => item.id), ['calc']);
  });

  test('imports seed suggestions through repository', () async {
    final count = await controller.importarSugestoesTeste(sobrescrever: false);

    expect(count, repository.importados.single.quantidade);
    expect(repository.importados.single.sobrescrever, isFalse);
    expect(repository.importados.single.quantidade, greaterThan(0));
  });
}

SugestaoBaseFesta _sugestao({
  required String id,
  required String titulo,
  required String modulo,
  int ordem = 1,
  bool ativo = true,
}) {
  return SugestaoBaseFesta(
    id: id,
    titulo: titulo,
    descricao: 'Descrição $titulo',
    modulo: modulo,
    tema: 'geral',
    tipoEvento: const ['todos'],
    perfisFesta: const ['todos'],
    categoria: 'geral',
    prioridade: 'media',
    gatilhos: GatilhosSugestaoBaseFesta.empty,
    tags: const ['tag'],
    ativo: ativo,
    ordem: ordem,
  );
}

class _SugestaoBaseFestaRepositoryFake
    implements SugestaoBaseFestaRepositoryContract {
  var listagens = 0;
  final salvas = <SugestaoBaseFesta>[];
  final atualizadas = <SugestaoBaseFesta>[];
  final statusAlterados = <({String id, bool ativo})>[];
  final exclusoes = <String>[];
  final importados = <({int quantidade, bool sobrescrever})>[];

  List<SugestaoBaseFesta> sugestoes = const [];

  @override
  Future<List<SugestaoBaseFesta>> listarSugestoes() async {
    listagens++;
    return sugestoes;
  }

  @override
  Future<void> salvarSugestao(SugestaoBaseFesta sugestao) async {
    salvas.add(sugestao);
  }

  @override
  Future<void> atualizarSugestao(SugestaoBaseFesta sugestao) async {
    atualizadas.add(sugestao);
  }

  @override
  Future<void> ativarDesativarSugestao({
    required String id,
    required bool ativo,
  }) async {
    statusAlterados.add((id: id, ativo: ativo));
  }

  @override
  Future<void> excluirLogicamente(String id) async {
    exclusoes.add(id);
  }

  @override
  Future<int> importarSugestoesTeste({
    bool sobrescrever = true,
  }) async {
    importados.add((
      quantidade: 3,
      sobrescrever: sobrescrever,
    ));
    return 3;
  }
}
