import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/uf_cidade.dart';
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
    repository.estados = const [
      Estado(id: 'pr', nome: 'Parana', uf: 'PR'),
      Estado(id: 'sp', nome: 'Sao Paulo', uf: 'SP'),
    ];

    await controller.carregarEstados();

    expect(controller.estados, hasLength(2));
    expect(controller.estados.first.uf, 'PR');
    expect(controller.carregando.value, isFalse);
  });

  test('loads cities through the use case', () async {
    repository.cidadesPorEstado['pr'] = const [
      Cidade(id: 'maringa', nome: 'Maringa', uf: 'PR', idCidade: 4115200),
    ];

    await controller.carregarCidades('pr');

    expect(repository.estadosConsultados, ['pr']);
    expect(controller.cidades.single.nome, 'Maringa');
  });

  test('selects state, resets city and loads state cities', () async {
    repository.cidadesPorEstado['pr'] = const [
      Cidade(id: 'maringa', nome: 'Maringa', uf: 'PR', idCidade: 4115200),
    ];
    controller.cidadeSelecionada.value = const Cidade(
      id: '',
      nome: '',
      uf: '',
      idCidade: 123,
    );

    await controller.selecionarEstado(
      const Estado(id: 'pr', nome: 'Parana', uf: 'PR'),
    );

    expect(controller.estadoSelecionado.value?.id, 'pr');
    expect(controller.cidadeSelecionada.value, isNull);
    expect(controller.cidades, hasLength(1));
  });

  test('returns selected city IBGE id', () {
    controller.selecionarCidade(
      const Cidade(id: '', nome: '', uf: '', idCidade: 4115200),
    );

    expect(controller.idCidadeSelecionada, 4115200);

    controller.selecionarCidade(
      const Cidade(id: '', nome: '', uf: '', idCidade: 3550308),
    );

    expect(controller.idCidadeSelecionada, 3550308);
  });

  test('clears cities when city loading fails', () async {
    controller.cidades.add(
      const Cidade(id: 'antiga', nome: 'Antiga', uf: 'PR'),
    );
    repository.cidadesError = StateError('failure');

    await controller.carregarCidades('pr');

    expect(controller.cidades, isEmpty);
    expect(controller.carregando.value, isFalse);
  });
}

class _UfCidadeRepositoryFake implements UfCidadeRepository {
  List<Estado> estados = [];
  final cidadesPorEstado = <String, List<Cidade>>{};
  final estadosConsultados = <String>[];
  Object? estadosError;
  Object? cidadesError;

  @override
  Future<List<Estado>> carregarEstados() async {
    final currentError = estadosError;
    if (currentError != null) throw currentError;
    return estados;
  }

  @override
  Future<List<Cidade>> carregarCidades(String idEstado) async {
    estadosConsultados.add(idEstado);
    final currentError = cidadesError;
    if (currentError != null) throw currentError;
    return cidadesPorEstado[idEstado] ?? [];
  }
}
