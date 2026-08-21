import 'package:get/get.dart';

import '../../controllers/ranking_controller.dart';
import '../../data/datasources/remote/ranking_remote_datasource.dart';
import '../../data/repositories_impl/ranking_repository_impl.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../../domain/usecases/carregar_ranking_servicos.dart';

class RankingBootstrap {
  RankingBootstrap._();

  static void register() {
    if (!Get.isRegistered<RankingRemoteDatasource>()) {
      Get.lazyPut<RankingRemoteDatasource>(
        () => RankingRemoteDatasource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<RankingRepository>()) {
      Get.lazyPut<RankingRepository>(
        () => RankingRepositoryImpl(Get.find<RankingRemoteDatasource>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CarregarRankingServicos>()) {
      Get.lazyPut<CarregarRankingServicos>(
        () => CarregarRankingServicos(Get.find<RankingRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<RankingController>()) {
      Get.put(
        RankingController(
          carregarRankingServicos: Get.find<CarregarRankingServicos>(),
        ),
        permanent: true,
      );
    }
  }

  static RankingController findController() {
    register();
    return Get.find<RankingController>();
  }
}
