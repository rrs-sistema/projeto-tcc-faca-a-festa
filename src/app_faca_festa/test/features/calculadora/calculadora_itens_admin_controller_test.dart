import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_itens_admin_controller.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_item_base.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CalculadoraItensBaseRepositoryFake repository;
  late CalculadoraItensAdminController controller;

  setUp(() {
    Get.testMode = true;
    repository = _CalculadoraItensBaseRepositoryFake();
    controller = CalculadoraItensAdminController(repository: repository);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('loads base and event items through repository', () async {
    repository.itensBase = [
      _itemBase(id: 'bolo', nome: 'Bolo', ordem: 2),
      _itemBase(id: 'agua', nome: 'Água', ordem: 1, ativo: false),
    ];
    repository.itensEvento = [
      _itemEvento(id: 'casamento_bolo', nome: 'Bolo', ordem: 2),
      _itemEvento(id: 'casamento_agua', nome: 'Água', ordem: 1),
    ];

    await controller.carregarTudo();

    expect(repository.listagensBase, 1);
    expect(repository.listagensEvento, 1);
    expect(controller.itensBase.map((item) => item.id), ['agua', 'bolo']);
    expect(controller.itensEvento.map((item) => item.id), [
      'casamento_agua',
      'casamento_bolo',
    ]);
    expect(controller.loading.value, isFalse);
    expect(controller.erro.value, isEmpty);
  });

  test('filters base and event items preserving presentation behavior', () {
    controller.itensBase.assignAll([
      _itemBase(id: 'bolo', nome: 'Bolo', categoria: 'doces'),
      _itemBase(id: 'agua', nome: 'Água', categoria: 'bebidas'),
      _itemBase(id: 'off', nome: 'Inativo', categoria: 'doces', ativo: false),
    ]);
    controller.itensEvento.assignAll([
      _itemEvento(id: 'casamento_bolo', nome: 'Bolo', categoria: 'doces'),
      _itemEvento(
        id: 'formatura_bolo',
        nome: 'Bolo',
        tipoEvento: 'formatura',
        categoria: 'doces',
      ),
      _itemEvento(
        id: 'casamento_inativo',
        nome: 'Inativo',
        categoria: 'doces',
        ativo: false,
      ),
    ]);

    controller.filtroCategoriaBase.value = 'doces';
    controller.filtroStatusBase.value = 'ativos';
    controller.buscaBase.value = 'bolo';
    controller.filtroTipoEvento.value = 'casamento';
    controller.filtroCategoriaEvento.value = 'doces';
    controller.filtroStatusEvento.value = 'ativos';
    controller.buscaEvento.value = 'bolo';

    expect(controller.itensBaseFiltrados.map((item) => item.id), ['bolo']);
    expect(controller.itensEventoFiltrados.map((item) => item.id), [
      'casamento_bolo',
    ]);
  });

  test('toggles base item status through repository and updates local list',
      () async {
    final item = _itemBase(id: 'bolo', nome: 'Bolo', ativo: true);
    controller.itensBase.assign(item);

    await controller.ativarDesativarItemBase(item, false);

    expect(repository.statusBaseAlterados.single, (id: 'bolo', ativo: false));
    expect(controller.itensBase.single.ativo, isFalse);
    expect(controller.saving.value, isFalse);
    expect(controller.erro.value, isEmpty);
  });
}

CalculadoraItemBase _itemBase({
  required String id,
  required String nome,
  String categoria = 'doces',
  int ordem = 1,
  bool ativo = true,
}) {
  final now = DateTime(2026);

  return CalculadoraItemBase(
    id: id,
    nome: nome,
    descricao: 'Descrição $nome',
    categoriaPadrao: categoria,
    tipoItem: categoria,
    unidadePadrao: 'unidade',
    publicoAlvo: 'todos',
    ativo: ativo,
    ordem: ordem,
    icone: 'cake',
    tags: [categoria],
    createdAt: now,
    updatedAt: now,
  );
}

CalculadoraEventoItem _itemEvento({
  required String id,
  required String nome,
  String tipoEvento = 'casamento',
  String categoria = 'doces',
  int ordem = 1,
  bool ativo = true,
}) {
  final now = DateTime(2026);

  return CalculadoraEventoItem(
    id: id,
    idItemBase: nome.toLowerCase(),
    tipoEvento: tipoEvento,
    nome: nome,
    categoria: categoria,
    unidade: 'unidade',
    publicoAlvo: 'todos',
    quantidadePorConvidadoEquivalente: 1,
    valorUnitarioMedio: 10,
    perfisFesta: const ['padrao'],
    selecionadoPadrao: true,
    obrigatorio: false,
    ativo: ativo,
    ordem: ordem,
    observacao: '',
    createdAt: now,
    updatedAt: now,
  );
}

class _CalculadoraItensBaseRepositoryFake
    implements CalculadoraItensBaseRepositoryContract {
  var listagensBase = 0;
  var listagensEvento = 0;
  final statusBaseAlterados = <({String id, bool ativo})>[];
  final statusEventoAlterados = <({String id, bool ativo})>[];
  final itensBaseSalvos = <CalculadoraItemBase>[];
  final itensEventoSalvos = <CalculadoraEventoItem>[];

  List<CalculadoraItemBase> itensBase = const [];
  List<CalculadoraEventoItem> itensEvento = const [];

  @override
  Future<List<CalculadoraItemBase>> listarItensBase() async {
    listagensBase++;
    return itensBase;
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEvento() async {
    listagensEvento++;
    return itensEvento;
  }

  @override
  Future<List<CalculadoraItemBase>> listarItensBaseAtivos() async {
    return itensBase.where((item) => item.ativo).toList();
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEventoAtivos() async {
    return itensEvento.where((item) => item.ativo).toList();
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  }) async {
    return itensEvento.where((item) => item.tipoEvento == tipoEvento).toList();
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  }) {
    return buscarItensPorTipoEvento(
      tipoEvento: tipoEvento,
      perfilFesta: perfilFesta,
    );
  }

  @override
  Future<CalculadoraEventoItem?> buscarItemEventoPorId(String id) async {
    return itensEvento.firstWhereOrNull((item) => item.id == id);
  }

  @override
  Future<void> salvarItemBase(CalculadoraItemBase item) async {
    itensBaseSalvos.add(item);
  }

  @override
  Future<void> salvarItemEvento(CalculadoraEventoItem item) async {
    itensEventoSalvos.add(item);
  }

  @override
  Future<void> ativarDesativarItemBase(String id, bool ativo) async {
    statusBaseAlterados.add((id: id, ativo: ativo));
  }

  @override
  Future<void> ativarDesativarItemEvento(String id, bool ativo) async {
    statusEventoAlterados.add((id: id, ativo: ativo));
  }
}
