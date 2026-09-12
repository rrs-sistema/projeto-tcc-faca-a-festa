import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/ranking_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/ranking_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/ranking_repository.dart';
import 'package:app_faca_festa/domain/usecases/carregar_ranking_servicos.dart';
import 'package:app_faca_festa/presentation/modules/ranking/controllers/ranking_controller.dart';

class RankingBootstrap {
  RankingBootstrap._();

  static void register() {
    if (!Get.isRegistered<RankingRemoteDatasource>()) {
      Get.lazyPut<RankingRemoteDatasource>(
        () => RankingRemoteDatasource(
          firestore: Get.find<FirebaseFirestore>(),
        ),
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
