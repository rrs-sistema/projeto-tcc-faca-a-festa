import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

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
    // A infraestrutura offline-first normalmente é registrada no bootstrap.
    // Os fallbacks mantêm o binding utilizável em rotas e testes isolados.
    if (!Get.isRegistered<GiftLocalDatasource>()) {
      Get.lazyPut<GiftLocalDatasource>(
        () => GiftLocalDatasource(Get.find<AppDatabase>()),
      );
    }
    if (!Get.isRegistered<GiftRemoteDatasource>()) {
      Get.lazyPut<GiftRemoteDatasource>(
        () => GiftRemoteDatasource(FirebaseFirestore.instance),
      );
    }

    Get.lazyPut<GiftRepository>(
      () => GiftRepositoryImpl(
        local: Get.find<GiftLocalDatasource>(),
        remote: Get.find<GiftRemoteDatasource>(),
      ),
    );

    Get.lazyPut<GiftUseCases>(() => GiftUseCases(Get.find<GiftRepository>()));

    Get.lazyPut<GiftController>(() {
      final arguments = Get.arguments;
      final routeEventoId =
          arguments is Map ? arguments['eventoId'] as String? : null;
      final eventoId = routeEventoId ??
          Get.find<EventoController>().eventoAtualEntidade?.idEvento ??
          '';
      return GiftController(
        eventoId: eventoId,
        usecases: Get.find<GiftUseCases>(),
      );
    });
  }
}
