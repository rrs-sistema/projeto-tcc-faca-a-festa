import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/core/database/app_database.dart';
import 'package:app_faca_festa/data/datasources/local/gift_local_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/gift_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/gift_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/gift_repository.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/gifts/controllers/gift_controller.dart';

/// Route-scoped composition for Gifts.
///
/// Offline-first infrastructure is registered by [GiftOfflineBootstrap].
/// This bootstrap only fills gaps (web / tests) and creates [GiftController]
/// with the `eventoId` of the current route.
abstract final class GiftBootstrap {
  static void registerRoute() {
    if (!Get.isRegistered<GiftLocalDatasource>()) {
      Get.lazyPut<GiftLocalDatasource>(
        () => GiftLocalDatasource(Get.find<AppDatabase>()),
      );
    }
    if (!Get.isRegistered<GiftRemoteDatasource>()) {
      Get.lazyPut<GiftRemoteDatasource>(
        () => GiftRemoteDatasource(Get.find<FirebaseFirestore>()),
      );
    }
    if (!Get.isRegistered<GiftRepository>()) {
      Get.lazyPut<GiftRepository>(
        () => GiftRepositoryImpl(
          local: Get.find<GiftLocalDatasource>(),
          remote: Get.find<GiftRemoteDatasource>(),
        ),
      );
    }
    if (!Get.isRegistered<GiftUseCases>()) {
      Get.lazyPut<GiftUseCases>(
        () => GiftUseCases(Get.find<GiftRepository>()),
      );
    }

    Get.lazyPut<GiftController>(() {
      final arguments = Get.arguments;
      final routeEventoId =
          arguments is GerenciarPresentesArgs ? arguments.eventoId : null;
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
