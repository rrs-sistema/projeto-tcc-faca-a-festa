import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../controllers/calculadora_festa_controller.dart';
import '../../controllers/evento_controller.dart';
import '../../controllers/gift/gift_controller.dart';
import '../../core/database/app_database.dart';
import '../../data/datasources/local/gift_local_datasource.dart';
import '../../data/datasources/remote/gift_remote_datasource.dart';
import '../../data/repositories_impl/gift_repository_impl.dart';
import '../../domain/repositories/gift_repository.dart';
import '../../domain/usecases/get_gifts/gift_usecases.dart';

class GiftBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Registra os Datasources
    Get.lazyPut<GiftLocalDatasource>(() => GiftLocalDatasource(Get.find<AppDatabase>()));
    Get.lazyPut<GiftRemoteDatasource>(() => GiftRemoteDatasource(FirebaseFirestore.instance));

    // 2. Registra o Repository
    Get.lazyPut<GiftRepository>(() => GiftRepositoryImpl(
          local: Get.find<GiftLocalDatasource>(),
          remote: Get.find<GiftRemoteDatasource>(),
        ));

    // 3. Registra os UseCases
    Get.lazyPut<GiftUseCases>(() => GiftUseCases(Get.find<GiftRepository>()));

    // 4. Registra o Controller
// 4. Registra o Controller
    Get.lazyPut<GiftController>(() {
      final eventoId = Get.arguments?['eventoId'] ??
          Get.find<EventoController>().eventoAtual.value?.idEvento ??
          '';
      return GiftController(
        eventoId: eventoId,
        usecases: Get.find<GiftUseCases>(),
      );
    });

    Get.lazyPut<CalculadoraFestaController>(
      () => CalculadoraFestaController(),
      fenix: true,
    );
  }
}
