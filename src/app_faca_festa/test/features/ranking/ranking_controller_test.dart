import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/ranking/controllers/ranking_controller.dart';
import 'package:app_faca_festa/domain/entities/ranking_servico.dart';
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
    repository.ranking = const [
      RankingServico(
        id: 'fornecedor-servico-1',
        idFornecedor: 'fornecedor-1',
        idProdutoServico: 'servico-1',
        media: 4.8,
        totalAvaliacoes: 10,
      ),
      RankingServico(
        id: 'fornecedor-servico-2',
        idFornecedor: 'fornecedor-2',
        idProdutoServico: 'servico-2',
        media: 4.2,
        totalAvaliacoes: 5,
      ),
    ];

    await controller.carregarRanking('subcategoria-1');

    expect(repository.idSubcategoriasConsultadas, ['subcategoria-1']);
    expect(controller.ranking, hasLength(2));
    expect(controller.ranking.first.media, 4.8);
  });

  test('clears stale ranking before exposing returned list', () async {
    controller.ranking.add(
      const RankingServico(
        id: 'antigo',
        idFornecedor: '',
        idProdutoServico: '',
        media: 0,
        totalAvaliacoes: 0,
      ),
    );
    repository.ranking = [];

    await controller.carregarRanking('subcategoria-1');

    expect(controller.ranking, isEmpty);
  });
}

class _RankingRepositoryFake implements RankingRepository {
  List<RankingServico> ranking = [];
  final idSubcategoriasConsultadas = <String>[];

  @override
  Future<List<RankingServico>> carregarRanking(String idSubcategoria) async {
    idSubcategoriasConsultadas.add(idSubcategoria);
    return ranking;
  }
}
