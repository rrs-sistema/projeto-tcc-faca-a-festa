import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/controllers/ranking_controller.dart';
import 'package:app_faca_festa/domain/repositories/ranking_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_ranking_servicos.dart';

void main() {
  late _RankingRepositoryFake repository;
  late RankingController controller;

  setUp(() {
    Get.testMode = true;
    repository = _RankingRepositoryFake();
    controller = RankingController(
      carregarRankingServicos: CarregarRankingServicos(repository),
    );
  });

  tearDown(Get.reset);

  test('loads ranking through the use case', () async {
    repository.ranking = [
      {
        'id': 'fornecedor-servico-1',
        'id_fornecedor': 'fornecedor-1',
        'id_produto_servico': 'servico-1',
        'media': 4.8,
        'total': 10,
      },
      {
        'id': 'fornecedor-servico-2',
        'id_fornecedor': 'fornecedor-2',
        'id_produto_servico': 'servico-2',
        'media': 4.2,
        'total': 5,
      },
    ];

    await controller.carregarRanking('subcategoria-1');

    expect(repository.idSubcategoriasConsultadas, ['subcategoria-1']);
    expect(controller.ranking, hasLength(2));
    expect(controller.ranking.first['media'], 4.8);
  });

  test('clears stale ranking before exposing returned list', () async {
    controller.ranking.add({'id': 'antigo'});
    repository.ranking = [];

    await controller.carregarRanking('subcategoria-1');

    expect(controller.ranking, isEmpty);
  });
}

class _RankingRepositoryFake implements RankingRepository {
  List<Map<String, dynamic>> ranking = [];
  final idSubcategoriasConsultadas = <String>[];

  @override
  Future<List<Map<String, dynamic>>> carregarRanking(
    String idSubcategoria,
  ) async {
    idSubcategoriasConsultadas.add(idSubcategoria);
    return ranking;
  }
}
