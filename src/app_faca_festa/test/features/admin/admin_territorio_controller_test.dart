import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/data/models/fornecedor/territorio_model.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';

void main() {
  late _AdminTerritorioRepositoryFake repository;
  late AdminTerritorioController controller;

  setUp(() {
    Get.testMode = true;
    repository = _AdminTerritorioRepositoryFake();
    controller = AdminTerritorioController(
      territoriosAdmin: GerenciarAdminTerritorios(repository),
    );
  });

  tearDown(Get.reset);

  test('loads territories through the use case', () async {
    repository.territorios = [
      _territorio(id: 'territorio-1', descricao: 'Zona Sul'),
      _territorio(id: 'territorio-2', descricao: 'Centro'),
    ];

    await controller.carregarTerritorios();

    expect(controller.territorios, hasLength(2));
    expect(controller.territorios.first.descricao, 'Zona Sul');
  });

  test('saves territory and reloads the list', () async {
    final territorio = _territorio(id: 'territorio-1', descricao: 'Zona Sul');
    repository.territorios = [territorio];

    await controller.salvarTerritorio(territorio);

    expect(repository.territoriosSalvos, [territorio]);
    expect(controller.territorios.map((t) => t.idTerritorio), ['territorio-1']);
  });

  test('toggles active state and reloads territories', () async {
    final territorio = _territorio(id: 'territorio-1', descricao: 'Zona Sul');

    await controller.toggleAtivo(territorio, false);

    expect(repository.alteracoesAtivo, {'territorio-1': false});
    expect(repository.listarChamadas, 1);
  });

  test('keeps current empty behavior when loading fails', () async {
    repository.error = StateError('failure');

    await controller.carregarTerritorios();

    expect(controller.territorios, isEmpty);
  });
}

TerritorioModel _territorio({
  required String id,
  required String descricao,
  bool ativo = true,
}) {
  return TerritorioModel(
    idTerritorio: id,
    idFornecedor: 'fornecedor-1',
    descricao: descricao,
    ativo: ativo,
    tipoCobertura: 'raio',
    latitude: -23.5,
    longitude: -46.6,
    raioKm: 10,
  );
}

class _AdminTerritorioRepositoryFake implements AdminTerritorioRepository {
  List<TerritorioModel> territorios = [];
  final territoriosSalvos = <TerritorioModel>[];
  final alteracoesAtivo = <String, bool>{};
  Object? error;
  int listarChamadas = 0;

  @override
  Future<List<TerritorioModel>> listarTerritorios() async {
    listarChamadas++;
    final currentError = error;
    if (currentError != null) throw currentError;
    return territorios;
  }

  @override
  Future<void> salvarTerritorio(TerritorioModel territorio) async {
    territoriosSalvos.add(territorio);
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) async {
    alteracoesAtivo[idTerritorio] = ativo;
  }
}
