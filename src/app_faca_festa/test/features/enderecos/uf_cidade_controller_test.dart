import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/uf_cidade_controller.dart';
import 'package:app_faca_festa/domain/repositories/uf_cidade_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';

void main() {
  late _UfCidadeRepositoryFake repository;
  late UFCidadeController controller;

  setUp(() {
    Get.testMode = true;
    repository = _UfCidadeRepositoryFake();
    controller = UFCidadeController(
      ufsCidades: GerenciarUfsCidades(repository),
    );
  });

  tearDown(Get.reset);

  test('loads states through the use case', () async {
    repository.estados = [
      {'id': 'pr', 'nome': 'Parana', 'uf': 'PR'},
      {'id': 'sp', 'nome': 'Sao Paulo', 'uf': 'SP'},
    ];

    await controller.carregarEstados();

    expect(controller.estados, hasLength(2));
    expect(controller.estados.first['uf'], 'PR');
    expect(controller.carregando.value, isFalse);
  });

  test('loads cities through the use case', () async {
    repository.cidadesPorEstado['pr'] = [
      {'id': 'maringa', 'nome': 'Maringa', 'uf': 'PR', 'id_cidade': '4115200'},
    ];

    await controller.carregarCidades('pr');

    expect(repository.estadosConsultados, ['pr']);
    expect(controller.cidades.single['nome'], 'Maringa');
  });

  test('selects state, resets city and loads state cities', () async {
    repository.cidadesPorEstado['pr'] = [
      {'id': 'maringa', 'nome': 'Maringa', 'uf': 'PR', 'id_cidade': 4115200},
    ];
    controller.cidadeSelecionada.value = {'id_cidade': 123};

    await controller.selecionarEstado({'id': 'pr', 'nome': 'Parana'});

    expect(controller.estadoSelecionado.value?['id'], 'pr');
    expect(controller.cidadeSelecionada.value, isNull);
    expect(controller.cidades, hasLength(1));
  });

  test('returns selected city id from number or string', () {
    controller.selecionarCidade({'id_cidade': '4115200'});

    expect(controller.idCidadeSelecionada, 4115200);

    controller.selecionarCidade({'id_cidade': 3550308});

    expect(controller.idCidadeSelecionada, 3550308);
  });

  test('clears cities when city loading fails', () async {
    controller.cidades.add({'id': 'antiga'});
    repository.cidadesError = StateError('failure');

    await controller.carregarCidades('pr');

    expect(controller.cidades, isEmpty);
    expect(controller.carregando.value, isFalse);
  });
}

class _UfCidadeRepositoryFake implements UfCidadeRepository {
  List<Map<String, dynamic>> estados = [];
  final cidadesPorEstado = <String, List<Map<String, dynamic>>>{};
  final estadosConsultados = <String>[];
  Object? estadosError;
  Object? cidadesError;

  @override
  Future<List<Map<String, dynamic>>> carregarEstados() async {
    final currentError = estadosError;
    if (currentError != null) throw currentError;
    return estados;
  }

  @override
  Future<List<Map<String, dynamic>>> carregarCidades(String idEstado) async {
    estadosConsultados.add(idEstado);
    final currentError = cidadesError;
    if (currentError != null) throw currentError;
    return cidadesPorEstado[idEstado] ?? [];
  }
}
